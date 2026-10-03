#!/usr/bin/env python3
"""Measure login/interactive initialization, excluding prompt rendering and typing latency."""
import os
import pty
import statistics
import subprocess
import time

samples = []
for run in range(12):
    master, slave = pty.openpty()
    try:
        start = time.perf_counter()
        result = subprocess.run(
            ["/bin/zsh", "-lic", "exit"],
            env=dict(os.environ, TERM="xterm-256color"),
            stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20,
        )
        elapsed = (time.perf_counter() - start) * 1000
    finally:
        os.close(slave)
        os.close(master)
    if result.returncode or result.stderr:
        raise SystemExit("Shell exited unsuccessfully or emitted diagnostics; investigate before benchmarking.")
    samples.append(elapsed)

print("Startup (ms): " + ", ".join(f"{value:.1f}" for value in samples))
print(f"Warm median, excluding first two runs: {statistics.median(samples[2:]):.1f} ms")
