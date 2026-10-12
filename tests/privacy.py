"""Regression checks for binary paths, token false positives and package gates."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("privacy", root / "scripts/check-privacy.py")
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)


class PrivacyTests(unittest.TestCase):
    def test_binary_home_path_and_redacted_output(self):
        value = b"/" + b"Users/private-audit-user/source/file.m"
        self.assertIn("personal-home-path", privacy.inspect(b"\0" + value + b"\0", "libsample.dylib"))
        with tempfile.TemporaryDirectory() as temp:
            package = Path(temp) / "bad.zip"
            with zipfile.ZipFile(package, "w") as output:
                output.writestr("Nivlet.app/Contents/MacOS/Nivlet", value)
            result = subprocess.run(["python3", str(root / "scripts/check-privacy.py"), "--zip", str(package)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn(value, result.stdout + result.stderr)
            self.assertNotIn(b"private-audit-user", result.stdout + result.stderr)

    def test_runtime_examples_only_in_known_resources(self):
        value = b"/" + b"Users/username/Documents"
        self.assertEqual(privacy.inspect(value, "Contents/Resources/docs.json", bundle=True), [])
        self.assertIn("personal-home-path", privacy.inspect(value, "Contents/MacOS/Nivlet", bundle=True))
        self.assertIn("personal-home-path", privacy.inspect(b"/" + b"Users/real-person/a", "Contents/Resources/docs.json", bundle=True))

    def test_credentials_and_symbol_false_positive(self):
        self.assertIn("credential", privacy.inspect(b"token=" + b"ghp_" + b"x" * 36, "settings.json"))
        self.assertIn("private-key", privacy.inspect(b"-----BEGIN " + b"PRIVATE KEY-----", "bundle.dat"))
        self.assertEqual(privacy.inspect(b"libtask-5555494462dbd466cb52347b9a0e013ad5f76494\0", "libtask.dylib"), [])

    def test_sensitive_artifact_names(self):
        self.assertIn("sensitive-file", privacy.inspect(b"test", "Nivlet.app/.env"))
        self.assertIn("sensitive-file", privacy.inspect(b"test", "Nivlet.app/clipboard-history/item.png"))
        self.assertEqual(privacy.inspect(b"public update key", "Info.plist"), [])

    def test_commit_identity_gate(self):
        with tempfile.TemporaryDirectory() as temp:
            subprocess.run(["git", "init", "-q", temp], check=True)
            for key, value in [("user.name", "Example"), ("user.email", "user@example.com")]:
                subprocess.run(["git", "-C", temp, "config", key, value], check=True)
            self.assertEqual(len(list(privacy.check_repo(Path(temp)))), 2)
            subprocess.run(["git", "-C", temp, "config", "user.email", "123+example@users.noreply.github.com"], check=True)
            self.assertEqual(list(privacy.check_repo(Path(temp))), [])


if __name__ == "__main__":
    unittest.main()
