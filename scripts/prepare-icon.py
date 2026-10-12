#!/usr/bin/env python3
"""Resize the approved Nivlet artwork into the runtime macOS icon catalog."""
import json
from pathlib import Path
import subprocess

project = Path(__file__).resolve().parent.parent
catalog = project / "vendor/hammerspoon/Hammerspoon/Images.xcassets/AppIcon.appiconset"
source = project / "assets/nivlet-icon.png"
for image in json.loads((catalog / "Contents.json").read_text())["images"]:
    pixels = int(image["size"].split("x")[0]) * int(image["scale"].removesuffix("x"))
    subprocess.run(["/usr/bin/sips", "-z", str(pixels), str(pixels), str(source),
                    "--out", str(catalog / image["filename"])], check=True,
                   stdout=subprocess.DEVNULL)
