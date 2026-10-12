"""Validate the actual signed release archive and reject a corrupted copy."""
from pathlib import Path
import hashlib
import plistlib
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile
root = Path(__file__).resolve().parent.parent
ns = {'s': 'http://www.andymatuschak.org/xml-namespaces/sparkle'}
item = ET.parse(root / 'docs/appcast.xml').find('./channel/item')
entry = item.find('enclosure')
version = item.find('s:shortVersionString', ns).text
assert entry.attrib['url'].startswith(f'https://github.com/wivnelo/Nivlet/releases/download/v{version}/')
assert item.find('s:hardwareRequirements', ns).text == 'arm64'
previous = ET.parse(root / 'docs/appcast.xml').findall('./channel/item')[1:]
assert not previous, 'Retired installation packages must not remain in the feed'
archive = root / 'build/packages' / entry.attrib['url'].rsplit('/', 1)[1]
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
