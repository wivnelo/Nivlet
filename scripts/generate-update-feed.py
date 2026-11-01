"""Sign the Apple Silicon release ZIP and write its architecture-restricted feed."""
import argparse
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

root = Path(__file__).resolve().parent.parent
MAGIC = {bytes.fromhex(value) for value in (
    'cafebabe', 'bebafeca', 'cafebabf', 'bfbafeca',
    'cffaedfe', 'feedfacf', 'cefaedfe', 'feedface',
)}


def read_description(version, build):
    path = root / 'release-notes' / f'{version}-build{build}.md'
    if not path.is_file():
        raise SystemExit(f'Missing release notes: {path}')
    notes = path.read_text(encoding='utf-8')
    if 'DRAFT PLACEHOLDER' in notes:
        raise SystemExit(f'Draft release notes must be replaced before release: {path}')
    description = ' '.join(re.sub(r'<!--.*?-->', '', notes, flags=re.DOTALL).split())
    if not description:
        raise SystemExit(f'Empty release notes: {path}')
    return description


def inspect_archive(archive):
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None:
            raise SystemExit('Invalid ZIP')
        names = package.namelist()
        if len(names) != len(set(names)):
            raise SystemExit('Duplicate ZIP entries')
        info = plistlib.loads(package.read('Nivlet.app/Contents/Info.plist'))
        version = info['CFBundleShortVersionString']
        build = info['CFBundleVersion']
        if version != (root / 'VERSION').read_text().strip():
            raise SystemExit('Archive version does not match VERSION')
        if not re.fullmatch(r'[1-9]\d*', build):
            raise SystemExit('Invalid archive build')
        if archive.name != f'Nivlet-{version}-build{build}-arm64.zip':
            raise SystemExit('Expected the canonical arm64 release ZIP filename')
        if info['CFBundleIdentifier'] != 'dev.local.DesktopToolkit':
            raise SystemExit('Unexpected bundle identifier')
        if info['SUFeedURL'] != 'https://wivnelo.github.io/Nivlet/appcast.xml':
            raise SystemExit('Unexpected update feed')
        if info['SUPublicEDKey'] != 'BZOLe5gdPobi3DhB5l13XFopkGgkPP/V6I/kzY3YXKg=':
            raise SystemExit('Unexpected update public key')
        count = 0
        found_main = False
        with tempfile.TemporaryDirectory(prefix='nivlet-feed-arch-') as temporary:
            binary = Path(temporary) / 'binary'
            for entry in package.infolist():
                if entry.is_dir():
                    continue
                with package.open(entry) as stream:
                    header = stream.read(4)
                    if header not in MAGIC:
                        continue
                    binary.write_bytes(header + stream.read())
                actual = subprocess.check_output(['lipo', '-archs', str(binary)], text=True).strip()
                if actual != 'arm64':
                    raise SystemExit(f'Expected arm64 only, got {actual}: {entry.filename}')
                count += 1
                found_main |= entry.filename == 'Nivlet.app/Contents/MacOS/Nivlet'
        if not found_main:
            raise SystemExit('Missing main Mach-O executable')
    return info, count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path, help='Final notarized arm64 ZIP; Intel releases remain archived at v1.0.8')
    parser.add_argument('--output', type=Path, default=root / 'docs/appcast.xml')
    parser.add_argument('--validate-only', action='store_true', help='Check the archive without signing or writing a feed')
    args = parser.parse_args()
    archive = args.archive.resolve()
    info, count = inspect_archive(archive)
    subprocess.run([sys.executable, str(root / 'scripts/check-privacy.py'), '--repo', str(root)], check=True)
    subprocess.run([sys.executable, str(root / 'scripts/check-privacy.py'), '--zip', str(archive)], check=True)
    if args.validate_only:
        print(f'Validated {count} arm64 Mach-O files; no feed written')
        return
    version, build = info['CFBundleShortVersionString'], info['CFBundleVersion']
    description = read_description(version, build)
    tool = root / 'vendor/sparkle-2.10.0/bin/sign_update'
    command = [str(tool), '--account', 'dev.local.DesktopToolkit.updates']
    signature = subprocess.check_output(command + ['-p', str(archive)], text=True).strip()
    subprocess.run(command + ['--verify', str(archive), signature], check=True)
    ns = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
    ET.register_namespace('sparkle', ns)
    rss = ET.Element('rss', version='2.0')
    channel = ET.SubElement(rss, 'channel')
    ET.SubElement(channel, 'title').text = 'Nivlet for Mac Updates'
    ET.SubElement(channel, 'link').text = 'https://wivnelo.github.io/Nivlet/'
    item = ET.SubElement(channel, 'item')
    ET.SubElement(item, 'title').text = f'Nivlet {version} · Build {build}'
    ET.SubElement(item, f'{{{ns}}}version').text = build
    ET.SubElement(item, f'{{{ns}}}shortVersionString').text = version
    ET.SubElement(item, f'{{{ns}}}minimumSystemVersion').text = '13.0'
    # Without this restriction Intel clients could be offered an unusable update.
    ET.SubElement(item, f'{{{ns}}}hardwareRequirements').text = 'arm64'
    ET.SubElement(item, 'link').text = f'https://github.com/wivnelo/Nivlet/releases/tag/v{version}'
    ET.SubElement(item, 'description').text = description
    ET.SubElement(item, 'enclosure', {
        'url': f'https://github.com/wivnelo/Nivlet/releases/download/v{version}/{archive.name}',
        'length': str(archive.stat().st_size),
        'type': 'application/octet-stream',
        f'{{{ns}}}edSignature': signature,
    })
    ET.indent(rss)
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=output.parent, prefix='.appcast-', suffix='.xml', delete=False) as stream:
            temporary = Path(stream.name)
            ET.ElementTree(rss).write(stream, encoding='utf-8', xml_declaration=True)
        temporary.replace(output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print(f'Signed Apple Silicon update feed generated: {version} Build {build}: {output}')


if __name__ == '__main__':
    main()
