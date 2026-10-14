#!/usr/bin/env python3
"""Offline integration checks using temporary homes and installed Homebrew tools."""
import os
from pathlib import Path
import pty
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
REAL_HOME = Path.home()
BREW = Path("/opt/homebrew" if Path("/opt/homebrew/bin/brew").exists() else "/usr/local")


class ShellTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.repo = self.home / ".dotfiles"
        self.repo.mkdir()
        for name in (".zshrc", ".zsh_plugins.txt", "starship.toml"):
            shutil.copy2(ROOT / name, self.repo / name)
        shutil.copytree(ROOT / "scripts", self.repo / "scripts")
        # Reuse installed plugin clones read-only; never read the user's secrets/history.
        self.plugins = self.home / "Library/Caches/antidote"
        self.plugins.mkdir(parents=True)
        (self.plugins / "github.com").symlink_to(REAL_HOME / "Library/Caches/antidote/github.com")
        (self.plugins / ".antidote.load").touch()
        self.cache = self.home / "cache"
        self.cache.mkdir()
        self.env = dict(HOME=str(self.home), XDG_CACHE_HOME=str(self.cache),
                        PATH=f"{BREW}/bin:/usr/bin:/bin:/usr/sbin:/sbin",
                        TERM="xterm-256color", HOMEBREW_PREFIX=str(BREW),
                        ANTIDOTE_HOME=str(self.plugins), LC_ALL="en_US.UTF-8")
        # Generate from the real manifest, without loading any user configuration.
        source = BREW / "opt/antidote/share/antidote/antidote.zsh"
        bundle = subprocess.run(["/bin/zsh", "-fc",
            'source "$1"; antidote bundle < "$2"', "test", str(source),
            str(self.repo / ".zsh_plugins.txt")], env=self.env, capture_output=True)
        self.assertEqual(bundle.returncode, 0, bundle.stderr.decode())
        (self.cache / ".zsh_plugins.zsh").write_bytes(bundle.stdout)

    def shell(self, code):
        master, slave = pty.openpty()
        try:
            return subprocess.run(["/bin/zsh", "-fic",
                'source "$HOME/.dotfiles/.zshrc"; ' + code], env=self.env,
                cwd=ROOT, stdin=slave, capture_output=True, text=True, timeout=20)
        finally:
            os.close(slave)
            os.close(master)

    def check(self, code):
        result = self.shell(code)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_git_alias_resolves_current_branch(self):
        # Intercept Git's network operation; branch detection still uses real Git.
        self.check('''expected=$(command git symbolic-ref --short HEAD)
            git() { [[ "$*" == "pull origin $expected" ]]; }
            eval ggpull''')

    def test_path_and_fpath_have_no_duplicates(self):
        self.check('''typeset -a unique_path unique_fpath
            unique_path=("${(@u)path}")
            unique_fpath=("${(@u)fpath}")
            [[ ${#path} == ${#unique_path} && ${#fpath} == ${#unique_fpath} ]]''')

    def test_cold_completion_cache(self):
        self.check('[[ -s "$ZSH_COMPDUMP" ]] && (( $+functions[compdef] ))')

    def test_stale_completion_dump_is_refreshed(self):
        self.check('true')
        dump = next(self.cache.glob(".zcompdump-*"))
        os.utime(dump, (1, 1))
        self.check('true')
        self.assertGreater(dump.stat().st_mtime, 1)

    def test_missing_plugin_marker_forces_rebuild(self):
        cache = self.cache / ".zsh_plugins.zsh"
        cache.write_text("# stale bundle without plugins\n")
        (self.plugins / ".antidote.load").unlink()
        self.check('[[ $(git_current_branch) == $(command git symbolic-ref --short HEAD) ]]')
        self.assertTrue((self.plugins / ".antidote.load").exists())
        self.assertIn("ohmyzsh", cache.read_text())

    def test_esp_export_requires_toolchain(self):
        (self.home / "export-esp.sh").write_text("export ESP_TEST=1\n")
        self.check('[[ -z $ESP_TEST ]]')
        (self.home / ".rustup/toolchains/esp").mkdir(parents=True)
        self.check('[[ $ESP_TEST == 1 ]]')

    def test_fnm_searches_parent_directories(self):
        self.check('[[ $FNM_VERSION_FILE_STRATEGY == recursive ]]')

    def test_startup_is_quiet(self):
        result = self.shell('true')
        self.assertEqual((result.returncode, result.stdout, result.stderr), (0, "", ""))

    def test_default_cache_without_xdg(self):
        self.env.pop("XDG_CACHE_HOME")
        self.check('''[[ -s "$ZSH_COMPDUMP" && -s "$HOME/.cache/.zsh_plugins.zsh" ]] &&
            [[ $(git_current_branch) == $(command git symbolic-ref --short HEAD) ]]''')

    def test_fzf_respects_gitignore_and_handles_spaces(self):
        fixture = self.home / "project with spaces"
        fixture.mkdir()
        subprocess.run(["/usr/bin/git", "init", "-q", str(fixture)], check=True)
        (fixture / ".gitignore").write_text("ignored.txt\n")
        for name in ("keep file.txt", "ignored.txt", ".hidden"):
            (fixture / name).touch()
        (fixture / "directory with spaces").mkdir()
        self.check('''cd "$HOME/project with spaces"
            [[ -n $FZF_CTRL_T_COMMAND && -n $FZF_ALT_C_COMMAND ]] || exit 1
            files=$(eval "$FZF_CTRL_T_COMMAND")
            [[ $files == *"keep file.txt"* && $files == *".hidden"* &&
               $files != *"ignored.txt"* && $files != *".git/"* ]] || exit 1
            [[ $(print -r -- "$files" | fzf --filter='keep file') == 'keep file.txt' ]] || exit 1
            [[ $(eval "$FZF_ALT_C_COMMAND") == 'directory with spaces/' ]] || exit 1
            paths=$(_fzf_compgen_path .)
            [[ $paths == *"keep file.txt"* && $paths == *".hidden"* &&
               $paths != *"ignored.txt"* && $paths != *".git/"* ]] || exit 1
            [[ $(_fzf_compgen_dir .) == './directory with spaces/' ]] || exit 1
            bat --color=always --style=numbers --line-range=:300 -- 'keep file.txt' >/dev/null''')

    def test_fzf_widgets_and_preview(self):
        self.check('''[[ $(bindkey '^R') == *fzf-history-widget* &&
                            $(bindkey '^T') == *fzf-file-widget* &&
                            $(bindkey '^[c') == *fzf-cd-widget* &&
                            $FZF_CTRL_T_OPTS == *bat* ]]''')

    def test_modern_aliases_skip_claude_code_shell(self):
        self.check('[[ $aliases[ls] == eza* && $aliases[cat] == bat* && $aliases[tree] == eza* ]]')
        self.env["CLAUDECODE"] = "1"
        self.check('(( ! $+aliases[ls] && ! $+aliases[cat] )) && [[ $aliases[tree] == eza* ]]')

    def test_prompt_shows_conda_env_including_base(self):
        self.check('[[ $(starship prompt) != *conda:* ]]')
        self.check('[[ $(CONDA_DEFAULT_ENV=base starship prompt) == *conda:base* ]]')
        self.check('[[ $(CONDA_DEFAULT_ENV=geo starship prompt) == *conda:geo* ]]')

    @unittest.skipUnless((BREW / "bin/conda").exists(), "miniconda not installed")
    def test_conda_loads_on_first_use_without_base(self):
        self.check('''(( ! $+functions[__conda_activate] )) && [[ -z $CONDA_DEFAULT_ENV ]] || exit 1
            conda activate base && [[ $CONDA_DEFAULT_ENV == base ]] || exit 1
            [[ $(whence -p python) == */miniconda/base/bin/python ]] || exit 1
            conda deactivate && [[ -z $CONDA_DEFAULT_ENV ]]''')

    def test_git_ignore_matches_only_macos_icon_file(self):
        repo = self.home / "icons"
        subprocess.run(["/usr/bin/git", "init", "-q", str(repo)], check=True)
        def ignored(name):
            return subprocess.run(["/usr/bin/git", "-C", str(repo), "-c",
                f"core.excludesFile={ROOT / 'git/ignore'}", "check-ignore", "-q", name]).returncode == 0
        self.assertTrue(ignored("Icon\r"))
        self.assertFalse(ignored("Icons/a.svg"))

    def stubs(self, **scripts):
        bin_dir = self.home / "stub-bin"
        bin_dir.mkdir(exist_ok=True)
        log = self.home / "stub.log"
        for name, body in scripts.items():
            stub = bin_dir / name
            stub.write_text(f'#!/bin/bash\necho "{name} $*" >> "{log}"\n{body}\n')
            stub.chmod(0o755)
        return bin_dir, log

    def test_update_keeps_going_after_failures(self):
        env = self.fake_antidote("return 1")
        (self.home / ".rustup/toolchains/esp").mkdir(parents=True)
        bin_dir, log = self.stubs(
            brew=f'[[ $1 == --prefix ]] && echo "{env["HOMEBREW_PREFIX"]}" && exit 0; exit 1',
            uv="exit 1", rustup="exit 1", espup="exit 1", cargo="exit 1", gcloud="exit 1")
        env["PATH"] = f"{bin_dir}:/usr/bin:/bin"
        result = subprocess.run(["/bin/bash", str(ROOT / "update.sh")], env=env,
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        calls = log.read_text()
        for call in ("brew update", "brew bundle cleanup --force", "brew vulns --brewfile=",
                     "uv tool upgrade --all", "uv python upgrade", "uv cache prune", "rustup update",
                     "cargo install espup --locked", "espup update", "gcloud components update --quiet"):
            self.assertIn(call, calls)
        self.assertIn("Update finished with errors", result.stderr)

    def test_identity_setup_adds_scopes_protocol_and_keys(self):
        gh = """case "$1 $2" in
  "auth status") echo "  - Token scopes: 'admin:public_key', 'repo'" ;;
  "api user") printf 'octocat\\n42\\nThe Octocat\\n' ;;
esac"""
        bin_dir, log = self.stubs(gh=gh)
        env = dict(self.env, PATH=f"{bin_dir}:/usr/bin:/bin")
        result = subprocess.run(["/bin/bash", str(ROOT / "scripts/setup-git-identity.sh")],
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = log.read_text()
        for call in ("gh auth refresh --hostname github.com",
                     "gh config set --host github.com git_protocol ssh",
                     "--type authentication", "--type signing",
                     "gh api --paginate users/octocat/ssh_signing_keys"):
            self.assertIn(call, calls)
        personal = (self.home / ".gitconfig").read_text()
        self.assertIn("42+octocat@users.noreply.github.com", personal)
        self.assertIn("gpgSign = true", personal)
        pub = (self.home / ".ssh/id_ed25519.pub").read_text().split()[1]
        self.assertIn(pub, (self.home / ".config/git/allowed_signers").read_text())

    def test_audit_reports_old_layout_without_changing_anything(self):
        home = self.home / "old-mac"
        repo = home / ".dotfiles"
        for path in ("nvm/versions/node/v18.20.0/lib/node_modules/pnpm", "pyenv/versions/3.11.9"):
            (repo / path).mkdir(parents=True)
        for path in ("Library/Caches", ".cache", ".local"):
            (home / path).mkdir(parents=True)
        (repo / ".gitmodules").write_text('[submodule "nvm"]\n')
        (repo / ".zshrc").write_text('export PATH="/Users/someone-else/.local/bin:$PATH"\n')
        (repo / ".gitconfig").write_text("[user]\n\tname = Someone Else\n\temail = else@example.com\n")
        (home / ".zshrc").symlink_to(repo / ".zshrc")
        (home / ".gitconfig").symlink_to(repo / ".gitconfig")
        (home / ".zprofile").write_text('eval "$(/usr/local/bin/brew shellenv)"\n')
        def snapshot():
            # Tools may create their own caches; settings, dotfiles and installs must stay untouched.
            caches = (home / "Library/Caches", home / ".cache", home / ".local")
            return sorted((p, p.lstat().st_mtime) for p in home.rglob("*")
                          if not any(p == c or c in p.parents for c in caches))
        before = snapshot()
        env = dict(HOME=str(home), USER="tester", LOGNAME="tester", PATH="/usr/bin:/bin:/usr/sbin:/sbin",
                   GIT_CONFIG_NOSYSTEM="1")
        result = subprocess.run(["/bin/bash", str(ROOT / "scripts/audit.sh")], env=env,
                                capture_output=True, text=True, timeout=120)
        self.assertEqual(result.returncode, 0, result.stderr)
        for expected in ("old submodule layout", "nvm in", "v18.20.0 global npm packages: pnpm",
                         "pyenv in", "3.11.9", "~/.gitconfig links to", "Someone Else <else@example.com>",
                         "~/.zprofile sets up tools", "another user's folders: /Users/someone-else/.local/bin"):
            self.assertIn(expected, result.stdout)
        self.assertEqual(before, snapshot())

    def fake_antidote(self, body):
        prefix = self.home / "fake-brew"
        source = prefix / "opt/antidote/share/antidote/antidote.zsh"
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_text("antidote() { " + body + "; }\n")
        return dict(self.env, HOMEBREW_PREFIX=str(prefix))

    def test_failed_bundle_preserves_working_cache(self):
        env = self.fake_antidote("print 'partial output'; return 1")
        cache = self.cache / "working.zsh"
        cache.write_text("# working cache\n")
        result = subprocess.run(["/bin/zsh", str(ROOT / "scripts/bundle-plugins.zsh"),
            str(self.repo / ".zsh_plugins.txt"), str(cache)], env=env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(cache.read_text(), "# working cache\n")
        self.assertTrue((ROOT / "scripts/bundle-plugins.zsh").exists())
        self.assertEqual(list(self.cache.glob("working.zsh.*")), [])

    def test_invalid_or_empty_bundle_preserves_working_cache(self):
        for body in ("print 'if broken'", "return 0"):
            with self.subTest(body=body):
                env = self.fake_antidote(body)
                cache = self.cache / "working.zsh"
                cache.write_text("# working cache\n")
                result = subprocess.run(["/bin/zsh", str(ROOT / "scripts/bundle-plugins.zsh"),
                    str(self.repo / ".zsh_plugins.txt"), str(cache)], env=env, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(cache.read_text(), "# working cache\n")
                self.assertEqual(list(self.cache.glob("working.zsh.*")), [])

    def test_startup_survives_failed_rebuild(self):
        self.env = self.fake_antidote("print 'partial output'; return 1")
        cache = self.cache / ".zsh_plugins.zsh"
        previous = cache.read_bytes()
        os.utime(cache, (1, 1))  # Force the real .zshrc rebuild path.
        result = self.shell('[[ $(git_current_branch) == $(command git symbolic-ref --short HEAD) ]]')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Plugin rebuild failed", result.stderr)
        self.assertEqual(cache.read_bytes(), previous)

    def test_successful_bundle_replaces_cache(self):
        env = self.fake_antidote("print '# valid replacement'")
        cache = self.cache / "working.zsh"
        cache.write_text("# previous cache\n")
        result = subprocess.run(["/bin/zsh", str(ROOT / "scripts/bundle-plugins.zsh"),
            str(self.repo / ".zsh_plugins.txt"), str(cache)], env=env, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(cache.read_text(), "# valid replacement\n")
        self.assertEqual(list(self.cache.glob("working.zsh.*")), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
