"""Check host languages required for native framework localization."""
from pathlib import Path
import os
import plistlib
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='nivlet-localizations-') as directory:
    path = Path(directory) / 'Info.plist'
    path.write_bytes(plistlib.dumps({'CFBundleDevelopmentRegion': 'en', 'PreserveMe': True}))
    subprocess.run(['python3', str(root / 'scripts/configure-url-types.py'), str(path)],
                   env=dict(os.environ, NIVLET_BUILD_NUMBER='25'), check=True)
    info = plistlib.loads(path.read_bytes())
    assert info['CFBundleLocalizations'] == ['en', 'zh-Hans']
    assert info['CFBundleDevelopmentRegion'] == 'en'
    assert info['PreserveMe'] is True
    assert info['SUEnableAutomaticChecks'] is False
print('bundle localizations: PASS')
