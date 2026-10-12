#!/usr/bin/env python3
"""Keep every bundled Mach-O arm64-only; strip only the Release executable.

Run before signing. Framework symlinks are preserved. Xcode keeps the main
executable's matching dSYM alongside the app, outside distribution archives.
"""
from pathlib import Path
import subprocess
import sys

app = Path(sys.argv[1]).resolve()
configuration = sys.argv[2]
if configuration not in {"Debug", "Release"}:
    raise ValueError("Unsupported build configuration")
magic = {bytes.fromhex(value) for value in
         ("cafebabe", "bebafeca", "cafebabf", "bfbafeca", "cffaedfe", "feedfacf",
          "cefaedfe", "feedface")}
count = 0
for path in app.rglob("*"):
    if path.is_symlink() or not path.is_file():
        continue
    with path.open("rb") as stream:
        if stream.read(4) not in magic:
            continue
    arches = subprocess.check_output(["lipo", "-archs", str(path)], text=True).split()
    if "arm64" not in arches:
        raise RuntimeError(f"Bundled binary has no arm64 slice: {path}")
    if arches != ["arm64"]:
        temporary = path.with_name(path.name + ".arm64-temp")
        try:
            subprocess.run(["lipo", str(path), "-thin", "arm64", "-output", str(temporary)], check=True)
            temporary.chmod(path.stat().st_mode)
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)
    count += 1

if configuration == "Release":
    executable = app / "Contents/MacOS/Nivlet"
    dsym = app.with_suffix(".app.dSYM")
    def uuids(path):
        output = subprocess.check_output(["xcrun", "dwarfdump", "--uuid", str(path)], text=True)
        return {line.split()[1] for line in output.splitlines() if "(arm64)" in line}
    binary_uuids = uuids(executable)
    if not dsym.is_dir() or not binary_uuids or uuids(dsym) != binary_uuids:
        raise RuntimeError("Matching arm64 dSYM required before stripping Release executable")
    def exports():
        output = subprocess.check_output(["nm", "-gU", str(executable)], text=True)
        return sorted(line.split()[-1] for line in output.splitlines() if line.split())
    before = exports()
    subprocess.run(["xcrun", "strip", "-S", "-x", str(executable)], check=True)
    if not before or exports() != before or uuids(executable) != binary_uuids:
        raise RuntimeError("Release stripping changed exported symbols or UUID")
print(f"Verified {count} bundled Mach-O files as arm64; configuration: {configuration}")
