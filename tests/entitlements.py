"""Audited Release entitlements stay equal to the signed 1.0.8 plist."""
import plistlib
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
path = root / "Native" / "Nivlet.entitlements"
official = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    '<plist version="1.0"><dict>'
    '<key>com.apple.security.automation.apple-events</key><true/>'
    "</dict></plist>"
)
apple_events = "com.apple.security.automation.apple-events"
text = path.read_text(encoding="utf-8")
if text.strip() != official:
    sys.exit("Native/Nivlet.entitlements diverges from the signed 1.0.8 plist")
parsed = plistlib.loads(text.encode("utf-8"))
if set(parsed) != {apple_events} or parsed[apple_events] is not True:
    sys.exit("Unexpected entitlements: " + repr(parsed))

runtime = "Hammerspoon/Hammerspoon.entitlements"
for name in ["scripts/fetch-runtime.sh", "scripts/build-dev.sh"]:
    installed = False
    for line in (root / name).read_text(encoding="utf-8").splitlines():
        if (
            line.startswith("cp ")
            and "Native/Nivlet.entitlements" in line
            and line.rstrip().endswith(runtime + '"')
        ):
            installed = True
    if not installed:
        sys.exit(name + " does not install Native/Nivlet.entitlements onto " + runtime)

build = (root / "scripts/build-dev.sh").read_text(encoding="utf-8")
needle = 'codesign --force --sign - --entitlements "$project_dir/Native/Nivlet.entitlements"'
if needle not in build:
    sys.exit("Release signing does not pass Native/Nivlet.entitlements")
release = (root / "scripts/build-private-release.py").read_text(encoding="utf-8")
if '"Native"' not in release:
    sys.exit("Isolated release build does not include Native/")
patch = (root / "patches/runtime-isolation.patch").read_text(encoding="utf-8")
if "CODE_SIGN_ENTITLEMENTS = " + runtime not in patch:
    sys.exit("Release xcconfig no longer signs " + runtime)
print("Audited entitlements: " + apple_events + " only")
