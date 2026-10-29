"""Validate the actual signed release archive and reject a corrupted copy."""
from pathlib import Path
import argparse
import hashlib
import os
import plistlib
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile
root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--build', default=os.environ.get('NIVLET_BUILD_NUMBER'))
parser.add_argument('--dist', type=Path, default=os.environ.get('NIVLET_RELEASE_DIST'))
parser.add_argument('--appcast', type=Path, default=os.environ.get('NIVLET_APPCAST', 'docs/appcast.xml'))
args = parser.parse_args()
if not args.build:
    parser.error('Provide --build N or set NIVLET_BUILD_NUMBER')
if not args.build.isdecimal() or int(args.build) < 1:
    parser.error('Build number must be a positive integer')
version = (root / 'VERSION').read_text().strip()
dist = root / (args.dist or Path(f'build/release-{version}-build{args.build}/dist'))
ns = {'s': 'http://www.andymatuschak.org/xml-namespaces/sparkle'}
items = ET.parse(root / args.appcast).findall('./channel/item')
assert len(items) == 2, 'Both architecture updates are required'
assert items[0].find('s:hardwareRequirements', ns).text == 'arm64'
assert items[1].find('s:hardwareRequirements', ns) is None, 'Intel is the fallback, not an unsupported hardware token'
versions = [(item.find('s:version', ns).text, item.find('s:shortVersionString', ns).text) for item in items]
assert versions[0] == versions[1], 'Architecture versions must match'
for build, short_version in versions:
    assert short_version == version, 'Feed shortVersionString must match VERSION'
    assert build == args.build, 'Feed sparkle:version must match the requested build'
# Sparkle 2.10 filters ARM requirements, then keeps the first equal-version item.
for arm in (True, False):
    eligible = [item for item in items if arm or item.find('s:hardwareRequirements', ns) is None]
    selected = eligible[0].find('enclosure').attrib['url']
    assert ('-arm64.zip' if arm else '-x86_64.zip') in selected
for item, architecture in zip(items, ('arm64', 'x86_64')):
    entry = item.find('enclosure')
    version = item.find('s:shortVersionString', ns).text
    assert entry.attrib['url'].startswith(f'https://github.com/wivnelo/Nivlet/releases/download/v{version}/')
    assert entry.attrib['url'].endswith(f'-{architecture}.zip')
    archive = dist / entry.attrib['url'].rsplit('/', 1)[1]
    assert archive.stat().st_size == int(entry.attrib['length'])
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
        info = plistlib.loads(package.read('Nivlet.app/Contents/Info.plist'))
        assert info['CFBundleVersion'] == item.find('s:version', ns).text
        assert info['CFBundleShortVersionString'] == item.find('s:shortVersionString', ns).text
        assert info['SUFeedURL'] == 'https://wivnelo.github.io/Nivlet/appcast.xml'
        assert len(info['SUPublicEDKey']) == 44
        assert info['SUVerifyUpdateBeforeExtraction']
        assert not info['SUEnableAutomaticChecks'] and not info['SUAutomaticallyUpdate'] and not info['SUEnableSystemProfiling']
        for name in ['init.lua', 'settings.html']:
            text = package.read('Nivlet.app/Contents/Resources/Toolkit/' + name).decode()
            assert 'github.com/jrchhoo' not in text
            assert 'https://wivnelo.github.io/Nivlet/' in text
        html = package.read('Nivlet.app/Contents/Resources/Toolkit/settings.html').decode()
        assert '<span>筹备中</span>' not in html and '更新通道尚未建立' not in html
        assert "#draftHint').dataset.dirty==='true'" in html
    command = [str(root / 'vendor/sparkle-2.10.0/bin/sign_update'), '--account', 'dev.local.DesktopToolkit.updates', '--verify']
    sig = entry.attrib['{' + ns['s'] + '}edSignature']
    subprocess.run(command + [str(archive), sig], check=True)
    with tempfile.TemporaryDirectory(prefix='nivlet-update-tamper-') as temp:
        altered = Path(temp) / archive.name
        altered.write_bytes(archive.read_bytes() + b'tampered')
        result = subprocess.run(command + [str(altered), sig], capture_output=True)
        assert result.returncode != 0, 'Tampered archive accepted'
    for line in archive.with_suffix('.sha256').read_text().splitlines():
        digest, name = line.split()
        assert hashlib.sha256((archive.parent / name).read_bytes()).hexdigest() == digest
    print('Feed/build match, private feed isolation, ZIP CRC, SHA-256, signature verification and tamper rejection passed')
