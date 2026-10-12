"""Declare HTTP(S) handling without selecting any system default handler."""
import os
from pathlib import Path
import re
import plistlib
import sys
path = sys.argv[1]
with open(path, 'rb') as source:
    info = plistlib.load(source)
version = (Path(__file__).resolve().parent.parent / 'VERSION').read_text().strip()
build = os.environ.get('NIVLET_BUILD_NUMBER', '1')
if not re.fullmatch(r'\d+\.\d+\.\d+', version) or not re.fullmatch(r'[1-9]\d*', build):
    raise SystemExit('Invalid Nivlet version or NIVLET_BUILD_NUMBER')
info['CFBundleShortVersionString'] = version
info['CFBundleVersion'] = build
# Frameworks such as Sparkle choose their localization from the host's
# supported languages, even though our settings UI is localized in Lua/HTML.
info['CFBundleLocalizations'] = ['en', 'zh-Hans']
info['SUFeedURL'] = 'https://wivnelo.github.io/Nivlet/appcast.xml'
info['SUPublicEDKey'] = 'BZOLe5gdPobi3DhB5l13XFopkGgkPP/V6I/kzY3YXKg='
info['SUEnableAutomaticChecks'] = False
info['SUAutomaticallyUpdate'] = False
info['SUEnableSystemProfiling'] = False
info['SUVerifyUpdateBeforeExtraction'] = True
info['CFBundleURLTypes'] = [{
    'CFBundleURLName': 'dev.local.DesktopToolkit.web',
    'CFBundleTypeRole': 'Viewer',
    'CFBundleURLSchemes': ['http', 'https'],
}]
with open(path, 'wb') as target:
    plistlib.dump(info, target)
