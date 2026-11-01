"""Native menu localization changes labels only, and never executes the app."""
from pathlib import Path
import copy
import importlib.util
import json
import os
import plistlib
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location('native_menu_localizer', ROOT / 'scripts/localize-native-menu.py')
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)
SOURCE = ROOT / 'vendor/hammerspoon/Hammerspoon/MainMenu.xib'
CATALOG = json.loads((ROOT / 'Native/localizations/MainMenu.json').read_text())


class NativeMenuTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='nivlet-menu-test-')
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.app = self.directory / 'Nivlet.app'
        self.resources = self.app / 'Contents/Resources'
        self.resources.mkdir(parents=True)
        (self.app / 'Contents/Info.plist').write_bytes(plistlib.dumps({
            'CFBundleIdentifier': 'dev.local.DesktopToolkit', 'NSMainNibFile': 'MainMenu',
            'CFBundleDevelopmentRegion': 'en', 'CFBundleLocalizations': list(module.LANGUAGES)}))
        (self.resources / 'MainMenu.nib').write_bytes(b'original compiled menu')
        (self.resources / 'LICENSE').write_bytes(b'preserved license')

    @staticmethod
    def fake_compile(source, destination):
        destination.write_bytes(b'nib:' + source.read_bytes())

    def test_title_only_complete_mapping(self):
        import xml.etree.ElementTree as ET
        original = ET.parse(SOURCE).getroot()
        result = module.localized_documents(SOURCE, CATALOG)
        self.assertEqual(set(result), {'zh-Hans', 'zh-Hant', 'ja'})
        for language, document in result.items():
            self.assertEqual(module.structure_without_titles(original),
                             module.structure_without_titles(document.getroot()))
            actual = {e.get('id'): e.get('title') for e in document.getroot().iter() if 'title' in e.attrib}
            self.assertEqual(actual, CATALOG['translations'][language])

    def test_source_or_catalog_changes_are_rejected(self):
        for change in ('source', 'missing', 'extra', 'empty'):
            catalog = copy.deepcopy(CATALOG)
            key = next(iter(catalog['source_titles']))
            if change == 'source': catalog['source_titles'][key] = 'Unexpected source'
            elif change == 'missing': del catalog['translations']['ja'][key]
            elif change == 'extra': catalog['translations']['ja']['unknown'] = 'Unknown'
            else: catalog['translations']['ja'][key] = ''
            with self.assertRaises(ValueError): module.localized_documents(SOURCE, catalog)

    def test_preserves_actions_original_and_unrelated_resources(self):
        result = module.install_localizations(self.app, SOURCE, CATALOG, self.fake_compile)
        self.assertFalse(result['actions_changed'])
        self.assertFalse((self.resources / 'MainMenu.nib').exists())
        self.assertEqual((self.resources / 'en.lproj/MainMenu.nib').read_bytes(), b'original compiled menu')
        self.assertEqual((self.resources / 'LICENSE').read_bytes(), b'preserved license')
        for language in module.LANGUAGES:
            self.assertTrue((self.resources / (language + '.lproj/MainMenu.nib')).is_file())
        module.install_localizations(self.app, SOURCE, CATALOG, self.fake_compile)
        self.assertEqual((self.resources / 'en.lproj/MainMenu.nib').read_bytes(), b'original compiled menu')

    def test_compiler_failure_does_not_change_resources(self):
        def fail(source, destination):
            if source.stem == 'ja': raise RuntimeError('synthetic compiler failure')
            self.fake_compile(source, destination)
        before = {str(p.relative_to(self.resources)): p.read_bytes() for p in self.resources.rglob('*') if p.is_file()}
        with self.assertRaises(RuntimeError): module.install_localizations(self.app, SOURCE, CATALOG, fail)
        after = {str(p.relative_to(self.resources)): p.read_bytes() for p in self.resources.rglob('*') if p.is_file()}
        self.assertEqual(before, after)

    def test_wrong_bundle_and_symlink_output_are_rejected(self):
        info = self.app / 'Contents/Info.plist'
        info.write_bytes(plistlib.dumps({'CFBundleIdentifier': 'wrong', 'NSMainNibFile': 'MainMenu'}))
        with self.assertRaises(ValueError): module.install_localizations(self.app, SOURCE, CATALOG, self.fake_compile)
        info.write_bytes(plistlib.dumps({'CFBundleIdentifier': 'dev.local.DesktopToolkit', 'NSMainNibFile': 'MainMenu'}))
        outside = self.directory / 'outside'
        outside.mkdir()
        (self.resources / 'ja.lproj').symlink_to(outside, target_is_directory=True)
        with self.assertRaises(ValueError): module.install_localizations(self.app, SOURCE, CATALOG, self.fake_compile)
        self.assertEqual(list(outside.iterdir()), [])
        (self.resources / 'ja.lproj').unlink()
        (self.resources / 'MainMenu.nib').unlink()
        (self.resources / 'MainMenu.nib').symlink_to(outside / 'missing.nib')
        with self.assertRaises(ValueError): module.install_localizations(self.app, SOURCE, CATALOG, self.fake_compile)

    @unittest.skipUnless(os.environ.get('NIVLET_TEST_NATIVE_COMPILE') == '1', 'Set NIVLET_TEST_NATIVE_COMPILE=1 for actual ibtool resource compilation')
    def test_ibtool_compiles_native_menu_archives(self):
        module.install_localizations(self.app, SOURCE, CATALOG)
        for language in module.LANGUAGES[1:]:
            content = (self.resources / (language + '.lproj/MainMenu.nib')).read_bytes()
            self.assertGreater(len(content), 1000)
            self.assertNotEqual(content, (self.resources / 'en.lproj/MainMenu.nib').read_bytes())
        # Foundation resource lookup is read-only: no NSApplication, Nivlet
        # executable, nib instantiation, preferences write or UI is involved.
        probe_source = self.directory / 'bundle-language-probe.m'
        probe_source.write_text(r'''
#import <Foundation/Foundation.h>
int main(int argc, const char *argv[]) { @autoreleasepool {
    if (argc != 2) return 1;
    NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithUTF8String:argv[1]]];
    NSArray *languages = @[@"en", @"zh-Hans", @"zh-Hant", @"ja"];
    for (NSString *language in languages) {
        NSString *path = [bundle pathForResource:@"MainMenu" ofType:@"nib" inDirectory:nil forLocalization:language];
        NSString *suffix = [NSString stringWithFormat:@"/%@.lproj/MainMenu.nib", language];
        if (!path || ![path hasSuffix:suffix]) return 2;
    }
    NSDictionary *expected = @{@"en-US":@"en", @"zh-CN":@"zh-Hans", @"zh-TW":@"zh-Hant", @"zh-HK":@"zh-Hant", @"ja-JP":@"ja"};
    for (NSString *preference in expected) {
        NSArray *chosen = [NSBundle preferredLocalizationsFromArray:languages forPreferences:@[preference]];
        if (![chosen.firstObject isEqualToString:expected[preference]]) return 3;
    }
    return 0;
} }
''')
        probe = self.directory / 'bundle-language-probe'
        subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-Wall', '-Wextra', '-Werror',
                        '-framework', 'Foundation', str(probe_source), '-o', str(probe)], check=True)
        subprocess.run([str(probe), str(self.app)], check=True)


if __name__ == '__main__':
    unittest.main()
