"""Ensure release trimming preserves runtime bytes and rejects scope expansion."""
from pathlib import Path
import importlib.util
import os
import plistlib
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('distribution_trim', ROOT / 'scripts/trim-distribution.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class TrimTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nivlet-trim-test-')
        self.addCleanup(self.temp.cleanup)
        self.app = Path(self.temp.name) / 'Nivlet.app'
        (self.app / 'Contents').mkdir(parents=True)
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'dev.local.DesktopToolkit'}))
        self.kept = []
        for framework, (version, names) in module.FRAMEWORKS.items():
            base = self.app / 'Contents/Frameworks' / framework
            target = base / 'Versions' / version
            target.mkdir(parents=True)
            (base / 'Versions/Current').symlink_to(version)
            for name in names:
                (target / name).mkdir()
                filename = 'public.h' if name.endswith('Headers') else 'module.modulemap'
                (target / name / filename).write_text('compile interface')
                (base / name).symlink_to('Versions/Current/' + name)
            for relative in ['library.dylib', 'Resources/LICENSE', '_CodeSignature/CodeResources']:
                file = target / relative
                file.parent.mkdir(exist_ok=True)
                file.write_bytes(b'runtime-license-or-signature')
                self.kept.append((file, file.read_bytes()))

    def test_only_interfaces_removed_and_repeat_safe(self):
        result = module.trim(self.app)
        self.assertEqual(len(result['removedPaths']), 10)
        self.assertGreater(result['removedRegularFileBytes'], 0)
        for path, content in self.kept:
            self.assertEqual(path.read_bytes(), content)
        self.assertEqual(module.trim(self.app)['removedRegularFileBytes'], 0)

    def test_foreign_content_fails_before_any_removal(self):
        foreign = self.app / 'Contents/Frameworks/Sparkle.framework/Versions/B/Headers/LICENSE'
        foreign.write_text('must preserve')
        with self.assertRaises(ValueError):
            module.trim(self.app)
        self.assertTrue((self.app / 'Contents/Frameworks/LuaSkin.framework/Versions/A/Headers/public.h').exists())
        self.assertTrue(foreign.exists())

    def test_link_escape_fails_before_any_removal(self):
        link = self.app / 'Contents/Frameworks/Sparkle.framework/Headers'
        link.unlink()
        link.symlink_to(self.temp.name)
        with self.assertRaises(ValueError):
            module.trim(self.app)
        self.assertTrue((self.app / 'Contents/Frameworks/LuaSkin.framework/Versions/A/Headers/public.h').exists())

    def test_other_app_rejected(self):
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'other.app'}))
        with self.assertRaises(ValueError):
            module.trim(self.app)


if __name__ == '__main__':
    unittest.main()
