"""Reject stale or foreign release inputs before copying, signing or notarizing."""
from contextlib import redirect_stdout
import importlib.util
import io
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('sign_notarize', ROOT / 'scripts/sign-notarize.py')
signer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signer)


class SigningPreflightTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='nivlet-sign-preflight-')
        self.addCleanup(self.temporary.cleanup)
        self.release = Path(self.temporary.name).resolve() / 'release'
        self.source = self.release / 'arm64/DerivedData/Build/Products/Release/Nivlet.app'
        self.version = (ROOT / 'VERSION').read_text().strip()
        self.metadata = {'CFBundleIdentifier': 'dev.local.DesktopToolkit',
                         'CFBundleShortVersionString': self.version, 'CFBundleVersion': '56'}
        self.argv = ['sign-notarize.py', '--identity', 'unused test identity',
                     '--team-id', 'TEST', '--notary-profile', 'unused test profile',
                     '--build-dir', str(self.release), '--build', '56']

    def write_source(self, changes=None):
        contents = self.source / 'Contents'
        contents.mkdir(parents=True, exist_ok=True)
        (contents / 'Info.plist').write_bytes(plistlib.dumps(dict(self.metadata, **(changes or {}))))

    def test_stale_or_foreign_inputs_fail_before_any_tool_or_output(self):
        for key, value in [('CFBundleShortVersionString', '0.0.1'),
                           ('CFBundleVersion', '55'),
                           ('CFBundleIdentifier', 'other.application')]:
            with self.subTest(key=key):
                self.write_source({key: value})
                with patch.object(signer.sys, 'argv', self.argv), \
                        patch.object(signer.subprocess, 'run') as external:
                    with self.assertRaisesRegex(ValueError, key + ' mismatch'):
                        signer.main()
                    external.assert_not_called()
                self.assertFalse((self.release / 'dist').exists())
                self.assertFalse((self.release / 'arm64/Nivlet.app').exists())

    def test_correct_metadata_reaches_copy_only_after_preflight(self):
        self.write_source()

        class StopBeforeCopy(Exception):
            pass

        with patch.object(signer.sys, 'argv', self.argv), \
                patch.object(signer.subprocess, 'run', side_effect=StopBeforeCopy) as external, \
                redirect_stdout(io.StringIO()) as output:
            with self.assertRaises(StopBeforeCopy):
                signer.main()
            self.assertEqual(external.call_count, 1)
            command = external.call_args.args[0]
            self.assertEqual(command, ['ditto', str(self.source), str(self.release / 'arm64/Nivlet.app')])
            self.assertIn('verified source metadata', output.getvalue())

    def test_dry_run_missing_source_is_explicitly_unverified(self):
        with patch.object(signer.sys, 'argv', self.argv + ['--dry-run']), \
                patch.object(signer.subprocess, 'run') as external, \
                redirect_stdout(io.StringIO()) as output:
            signer.main()
            external.assert_not_called()
            text = output.getvalue()
            self.assertIn('plan only', text)
            self.assertIn('metadata has NOT been verified', text)
            self.assertNotIn('verified source metadata:', text)
        self.assertFalse(self.release.exists())

    def test_dry_run_existing_stale_source_is_rejected(self):
        self.write_source({'CFBundleVersion': '55'})
        with patch.object(signer.sys, 'argv', self.argv + ['--dry-run']), \
                patch.object(signer.subprocess, 'run') as external:
            with self.assertRaisesRegex(ValueError, 'CFBundleVersion mismatch'):
                signer.main()
            external.assert_not_called()
        self.assertFalse((self.release / 'dist').exists())


if __name__ == '__main__':
    unittest.main()
