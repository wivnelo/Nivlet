#!/usr/bin/env python3
"""Build Release in a fresh neutral path, then copy only app and matching dSYM."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
destination = Path(os.environ.get("NIVLET_DERIVED_DATA_PATH", root / "build/PrivateRelease")).resolve()
products = destination / "Build/Products/Release"
if destination.exists():
    raise SystemExit("Privacy Release destination already exists; choose a fresh NIVLET_DERIVED_DATA_PATH")
subprocess.run(["python3", str(root / "scripts/check-privacy.py"), "--repo", str(root)], check=True)
for name in ["vendor/hammerspoon", "vendor/sparkle-2.10.0"]:
    if not (root / name).is_dir():
        raise SystemExit("Prepare pinned Runtime and Sparkle before the isolated build")
with tempfile.TemporaryDirectory(prefix="nivlet-release-", dir="/private/tmp") as temporary:
    workspace = Path(temporary) / "source"
    workspace.mkdir()
    for name in ["Toolkit", "Native", "patches", "scripts", "vendor", "assets"]:
        shutil.copytree(root / name, workspace / name, symlinks=True,
                        ignore=shutil.ignore_patterns(".git", ".DS_Store", "xcuserdata", "*.xcuserstate"))
    for name in ["VERSION", "LICENSE", "THIRD-PARTY-NOTICES.md", "Hammerspoon-Downstream.xcconfig"]:
        shutil.copy2(root / name, workspace / name)
    # Upstream's version phase reads its pinned Git tag and commit count.
    shutil.copytree(root / "vendor/hammerspoon/.git", workspace / "vendor/hammerspoon/.git", symlinks=True)
    derived = Path(temporary) / "DerivedData"
    env = dict(os.environ, NIVLET_BUILD_CONFIGURATION="Release", NIVLET_DERIVED_DATA_PATH=str(derived))
    env["HAMMERSPOON_TOKEN_PATH"] = str(workspace / "disabled-tokens")
    subprocess.run(["sh", str(workspace / "scripts/build-dev.sh")], env=env, check=True)
    built = derived / "Build/Products/Release"
    subprocess.run(["python3", str(root / "scripts/check-privacy.py"), "--app", str(built / "Nivlet.app")], check=True)
    products.mkdir(parents=True)
    for name in ["Nivlet.app", "Nivlet.app.dSYM"]:
        shutil.copytree(built / name, products / name, symlinks=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(products / "Nivlet.app")], check=True)
print("Private Release ready; not installed or published: " + str(products / "Nivlet.app"))
