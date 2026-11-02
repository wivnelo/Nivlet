"""Encode isolated UI captures with macOS ImageIO; no pip packages required.

The renderer writes build/readme-demo/manifest.json and numbered PNG frames.
GIFs and decoded-frame contact sheets go to build/media-final for visual review.
"""
from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parent.parent
cache = root / 'build/media-final/swift-module-cache'
cache.mkdir(parents=True, exist_ok=True)
environment = dict(os.environ, CLANG_MODULE_CACHE_PATH=str(cache),
                   SWIFT_MODULECACHE_PATH=str(cache))
subprocess.run([
    '/usr/bin/swift', '-module-cache-path', str(cache),
    str(root / 'scripts/encode-readme-demo.swift'), str(root),
], check=True, env=environment)
