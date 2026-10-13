"""Sign a release ZIP using the Nivlet Keychain key and write its Sparkle feed."""
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
root = Path(__file__).resolve().parent.parent
if len(sys.argv) != 3:
    raise SystemExit('Usage: generate-update-feed.py ARM64.zip X86_64.zip (both required)')
archives = [Path(value).resolve() for value in sys.argv[1:]]
releases = []
for archive, architecture in zip(archives, ('arm64', 'x86_64')):
    with zipfile.ZipFile(archive) as package:
        info = plistlib.loads(package.read('Nivlet.app/Contents/Info.plist'))
        with tempfile.TemporaryDirectory(prefix='nivlet-feed-arch-') as temporary:
            binary = Path(temporary) / 'Nivlet'
            binary.write_bytes(package.read('Nivlet.app/Contents/MacOS/Nivlet'))
            actual = subprocess.check_output(['lipo', '-archs', str(binary)], text=True).strip()
            if actual != architecture:
                raise SystemExit(f'Expected {architecture}, got {actual}: {archive.name}')
    releases.append((info['CFBundleShortVersionString'], info['CFBundleVersion'], info['SUPublicEDKey']))
if releases[0] != releases[1]:
    raise SystemExit('Both architectures must have the same version, build and update public key')
ns = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ET.register_namespace('sparkle', ns)
rss = ET.Element('rss', version='2.0')
channel = ET.SubElement(rss, 'channel')
ET.SubElement(channel, 'title').text = 'Nivlet for Mac Updates'
ET.SubElement(channel, 'link').text = 'https://wivnelo.github.io/Nivlet/'
# Equal-version preference is first-match in Sparkle 2.10: ARM first, Intel fallback.
for archive, architecture in zip(archives, ('arm64', 'x86_64')):
    subprocess.run([sys.executable, str(root / 'scripts/check-privacy.py'), '--repo', str(root)], check=True)
    subprocess.run([sys.executable, str(root / 'scripts/check-privacy.py'), '--zip', str(archive)], check=True)
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None:
            raise SystemExit('Invalid ZIP')
        info = plistlib.loads(package.read('Nivlet.app/Contents/Info.plist'))
    assert info['CFBundleIdentifier'] == 'dev.local.DesktopToolkit'
    assert info['SUFeedURL'] == 'https://wivnelo.github.io/Nivlet/appcast.xml'
    tool = root / 'vendor/sparkle-2.10.0/bin/sign_update'
    command = [str(tool), '--account', 'dev.local.DesktopToolkit.updates']
    signature = subprocess.check_output(command + ['-p', str(archive)], text=True).strip()
    subprocess.run(command + ['--verify', str(archive), signature], check=True)
    item = ET.SubElement(channel, 'item')
    version, build = info['CFBundleShortVersionString'], info['CFBundleVersion']
    ET.SubElement(item, 'title').text = f'Nivlet {version} · Build {build}'
    ET.SubElement(item, f'{{{ns}}}version').text = build
    ET.SubElement(item, f'{{{ns}}}shortVersionString').text = version
    ET.SubElement(item, f'{{{ns}}}minimumSystemVersion').text = '13.0'
    if architecture == 'arm64':
        ET.SubElement(item, f'{{{ns}}}hardwareRequirements').text = 'arm64'
    ET.SubElement(item, 'link').text = f'https://github.com/wivnelo/Nivlet/releases/tag/v{version}'
    ET.SubElement(item, 'description').text = f'Nivlet {version}: refresh installed apps and browsers without restarting; update icons and select an available browser when needed. 无需重启刷新应用和浏览器，更新图标与卸载后的浏览器选择。'
    ET.SubElement(item, 'enclosure', {
        'url': f'https://github.com/wivnelo/Nivlet/releases/download/v{version}/{archive.name}',
        'length': str(archive.stat().st_size),
        'type': 'application/octet-stream',
        f'{{{ns}}}edSignature': signature,
    })
# Old artifacts were explicitly retired during privacy remediation.
ET.indent(rss)
ET.ElementTree(rss).write(root / 'docs/appcast.xml', encoding='utf-8', xml_declaration=True)
print(f'Signed dual-architecture update feed generated: {version} Build {build}')
