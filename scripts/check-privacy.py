#!/usr/bin/env python3
"""Fail closed on personal build paths and common credentials; never print values."""
import argparse
from pathlib import Path
import re
import subprocess
import sys
import zipfile

HOME_PATH = re.compile(rb"(?:/" + rb"Users/|/" + rb"home/|[A-Z]:\\Users\\)([^/\\\s\x00\"'<>]+)")
EXAMPLE_FILES = {"Contents/Resources/docs.json", "Contents/Resources/extensions/hs/spotlight.lua"}
PATTERNS = {
    "private-key": re.compile(rb"-----BEGIN (?:[A-Z ]*PRIVATE KEY|OPENSSH PRIVATE KEY)-----"),
    "credential": re.compile(rb"(?<![A-Za-z0-9_])(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[A-Z0-9]{16}|sk-(?:proj-)?[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{15,}|[0-9]{8,12}:[A-Za-z0-9_-]{35})(?![A-Za-z0-9_])"),
}
SENSITIVE_FILE = re.compile(r"(?:^|/)(?:\.env(?:\.[^/]*)?|id_rsa|id_ed25519|[^/]+\.(?:p12|pfx|key|sqlite|log)|clipboard-history|xcuserdata|\.git)(?:/|$)", re.I)


def inspect(data, name, bundle=False):
    problems = []
    for match in HOME_PATH.finditer(data):
        if bundle and any(name.endswith(p) for p in EXAMPLE_FILES) and match[1] in {b"username", b"Guest", b"ConsoleUser"}:
            continue
        problems.append("personal-home-path")
        break
    problems.extend(label for label, pattern in PATTERNS.items() if pattern.search(data))
    if SENSITIVE_FILE.search(name):
        problems.append("sensitive-file")
    return problems


def check_repo(root):
    root = root.resolve()
    paths = subprocess.check_output(["git", "-C", str(root), "ls-files", "-z", "--cached", "--others", "--exclude-standard"]).decode().split("\0")
    for name in sorted(set(filter(None, paths))):
        path = root / name
        # Existing nested workspaces have their own audit and publication boundary.
        if name == "website/" and (path / ".git").exists():
            continue
        if path.is_file():
            for problem in inspect(path.read_bytes(), name):
                yield name, problem
    for role in ["AUTHOR", "COMMITTER"]:
        identity = subprocess.check_output(["git", "-C", str(root), "var", "GIT_" + role + "_IDENT"])
        if not re.search(rb"<[0-9]+\+[A-Za-z0-9-]+@users\.noreply\.github\.com>", identity):
            yield "Git " + role.lower(), "non-noreply-email"


def check_app(app):
    if not (app / "Contents/Info.plist").is_file():
        raise ValueError("Expected an app bundle")
    for path in sorted(app.rglob("*")):
        if path.is_file() and not path.is_symlink():
            name = path.relative_to(app).as_posix()
            for problem in inspect(path.read_bytes(), name, bundle=True):
                yield name, problem


def check_zip(archive):
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None:
            raise ValueError("ZIP integrity check failed")
        for entry in package.infolist():
            if not entry.is_dir():
                for problem in inspect(package.read(entry), entry.filename, bundle=True):
                    yield entry.filename, problem


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--repo", type=Path)
    group.add_argument("--app", type=Path)
    group.add_argument("--zip", type=Path)
    args = parser.parse_args()
    try:
        problems = list(check_repo(args.repo) if args.repo else check_app(args.app) if args.app else check_zip(args.zip))
    except (OSError, ValueError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        print("Privacy scan could not complete: " + type(error).__name__, file=sys.stderr)
        return 1
    for name, problem in problems:
        print(problem + ": " + name, file=sys.stderr)
    print("Privacy scan: " + ("FAILED" if problems else "PASS"))
    return bool(problems)


if __name__ == "__main__":
    sys.exit(main())
