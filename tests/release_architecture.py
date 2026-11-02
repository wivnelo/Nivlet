"""Exercise arm64 release gates without signing, opening apps or changing a feed."""
from pathlib import Path
import importlib.util
import os
import plistlib
import struct
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('feed_generator', ROOT / 'scripts/generate-update-feed.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def macho(arm=True):

    return struct.pack('<8I', 0xfeedfacf, 0x0100000c if arm else 0x01000007, 0 if arm else 3, 2, 0, 0, 0, 0)


class ArchitectureTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='nivlet-architecture-test-')
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.version = (ROOT / 'VERSION').read_text().strip()
        self.archive = self.directory / f'Nivlet-{self.version}-build56-arm64.zip'

    def archive_with(self, main_arm=True, nested_arm=True):
        info = {'CFBundleIdentifier': 'dev.local.DesktopToolkit', 'CFBundleShortVersionString': self.version,
                'CFBundleVersion': '56', 'SUFeedURL': 'https://wivnelo.github.io/Nivlet/appcast.xml',
                'SUPublicEDKey': 'BZOLe5gdPobi3DhB5l13XFopkGgkPP/V6I/kzY3YXKg='}
        with zipfile.ZipFile(self.archive, 'w') as output:
            output.writestr('Nivlet.app/Contents/Info.plist', plistlib.dumps(info))
            output.writestr('Nivlet.app/Contents/MacOS/Nivlet', macho(main_arm))
            output.writestr('Nivlet.app/Contents/Frameworks/nested.dylib', macho(nested_arm))
        return self.archive

    def test_all_embedded_binaries_checked(self):
        _, count = generator.inspect_archive(self.archive_with())
        self.assertEqual(count, 2)
        with self.assertRaisesRegex(SystemExit, 'Expected arm64 only'):
            generator.inspect_archive(self.archive_with(nested_arm=False))

    def test_renamed_intel_main_rejected(self):
        with self.assertRaisesRegex(SystemExit, 'Expected arm64 only'):
            generator.inspect_archive(self.archive_with(main_arm=False))

    def test_no_intel_signing_or_build_entry(self):
        sign = subprocess.run([sys.executable, str(ROOT / 'scripts/sign-notarize.py'), 'x86_64'], capture_output=True, text=True)
        self.assertNotEqual(sign.returncode, 0)
        self.assertIn('invalid choice', sign.stderr)
        build = subprocess.run(['sh', str(ROOT / 'scripts/build-dev.sh')],
                               env=dict(os.environ, NIVLET_ARCH='x86_64'), capture_output=True, text=True)
        self.assertNotEqual(build.returncode, 0)
        self.assertIn('final Intel release', build.stderr)

    def test_signing_defaults_to_only_arm64(self):
        command = [sys.executable, str(ROOT / 'scripts/sign-notarize.py'), '--dry-run',
                   '--identity', 'test identity', '--team-id', 'TEST', '--notary-profile', 'test profile',
                   '--build-dir', str(self.directory / 'release'), '--build', '56']
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('arm64', result.stdout)
        self.assertNotIn('x86_64', result.stdout)


if __name__ == '__main__':
    unittest.main()
