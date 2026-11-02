"""Compile the power-state machine with fault-injected callbacks; no IOKit calls."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='nivlet-keep-awake-test-') as directory:
    binary = Path(directory) / 'keep-awake-test'
    subprocess.run([
        'clang', '-std=c11', '-Wall', '-Wextra', '-Werror',
        '-fsanitize=address,undefined', str(root / 'tests/keep_awake_native.c'),
        '-o', str(binary),
    ], check=True)
    subprocess.run([str(binary)], check=True)
