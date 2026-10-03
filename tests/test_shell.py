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
        # Reuse installed plugins read-only; never read the user's secrets/history.
        self.plugins = REAL_HOME / "Library/Caches/antidote"
        target = self.home / "Library/Caches/antidote"
        target.parent.mkdir(parents=True)
        target.symlink_to(self.plugins)
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
            bat --color=always --style=numbers --line-range=:300 -- 'keep file.txt' >/dev/null''')

    def test_fzf_widgets_and_preview(self):
        self.check('''[[ $(bindkey '^R') == *fzf-history-widget* &&
                            $(bindkey '^T') == *fzf-file-widget* &&
                            $(bindkey '^[c') == *fzf-cd-widget* &&
                            $FZF_CTRL_T_OPTS == *bat* ]]''')

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
