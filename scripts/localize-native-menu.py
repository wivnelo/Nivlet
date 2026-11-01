#!/usr/bin/env python3
"""Compile title-only native menu resources before signing, without launching the app.

Native menus use macOS bundle-language selection at launch. Toolkit's in-app
language preference does not override AppleLanguages or AppKit-owned controls.
"""
from pathlib import Path
import argparse
import copy
import json
import plistlib
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES = ('en', 'zh-Hans', 'zh-Hant', 'ja')


def structure_without_titles(element):
    return (element.tag, tuple(sorted((k, v) for k, v in element.attrib.items() if k != 'title')),
            (element.text or '').strip(), tuple(structure_without_titles(child) for child in element))


def localized_documents(source, catalog):
    """Fail closed if upstream IDs/titles change; preserve every non-title field."""
    document = ET.parse(source)
    base = document.getroot()
    actual = {element.get('id'): element.get('title') for element in base.iter() if 'title' in element.attrib}
    if catalog.get('schema') != 1 or actual != catalog.get('source_titles'):
        raise ValueError('Native menu source titles/IDs changed; review localization mappings first')
    translations = catalog.get('translations', {})
    if set(translations) != set(LANGUAGES[1:]):
        raise ValueError('Native menu catalog must contain exactly zh-Hans, zh-Hant and ja')
    original_structure = structure_without_titles(base)
    localized = {}
    for language in LANGUAGES[1:]:
        titles = translations[language]
        if set(titles) != set(actual):
            raise ValueError('Missing or extra native menu title: ' + language)
        result = copy.deepcopy(document)
        for element in result.getroot().iter():
            if 'title' not in element.attrib:
                continue
            title = titles[element.get('id')]
            if not isinstance(title, str) or not title.strip() or len(title) > 256 or any(ord(c) < 32 for c in title):
                raise ValueError('Invalid native menu title: ' + language)
            element.set('title', title)
        if structure_without_titles(result.getroot()) != original_structure:
            raise ValueError('Localization must not change native menu behavior')
        localized[language] = result
    return localized


def compile_nib(source, destination):
    subprocess.run(['xcrun', 'ibtool', '--errors', '--warnings', '--notices',
                    '--minimum-deployment-target', '13.0', '--compile', str(destination), str(source)], check=True)
    if not destination.is_file() or destination.is_symlink() or not destination.stat().st_size:
        raise ValueError('ibtool did not produce a native menu archive')


def install_localizations(app, source, catalog, compiler=compile_nib):
    app = Path(app).absolute()
    resources = app / 'Contents/Resources'
    info_path = app / 'Contents/Info.plist'
    if app.name != 'Nivlet.app' or app.is_symlink() or not app.is_dir():
        raise ValueError('Expected a real Nivlet.app build directory')
    if (app / 'Contents').is_symlink() or resources.is_symlink() or not resources.is_dir() or info_path.is_symlink():
        raise ValueError('Unexpected native menu resource path')
    info = plistlib.loads(info_path.read_bytes())
    if info.get('CFBundleIdentifier') != 'dev.local.DesktopToolkit' or info.get('NSMainNibFile') != 'MainMenu':
        raise ValueError('Wrong native menu application bundle')
    documents = localized_documents(source, catalog)
    root_nib = resources / 'MainMenu.nib'
    if root_nib.is_symlink():
        raise ValueError('Unexpected original native menu symlink')
    original = root_nib if root_nib.exists() else resources / 'en.lproj/MainMenu.nib'
    if original.is_symlink() or not original.is_file():
        raise ValueError('Missing original compiled MainMenu.nib')
    for language in LANGUAGES:
        folder = resources / (language + '.lproj')
        target = folder / 'MainMenu.nib'
        if folder.is_symlink() or (folder.exists() and not folder.is_dir()) or target.is_symlink() or (target.exists() and not target.is_file()):
            raise ValueError('Unexpected localized native menu output: ' + language)
    # Compile everything before changing the built bundle. A failing compiler
    # leaves the original native interface and existing resources untouched.
    with tempfile.TemporaryDirectory(prefix='nivlet-menu-', dir='/private/tmp') as temporary:
        prepared = Path(temporary)
        shutil.copyfile(original, prepared / 'en.nib')
        for language, document in documents.items():
            input_path = prepared / (language + '.xib')
            document.write(input_path, encoding='utf-8', xml_declaration=True)
            compiler(input_path, prepared / (language + '.nib'))
        for language in LANGUAGES:
            folder = resources / (language + '.lproj')
            folder.mkdir(exist_ok=True)
            shutil.copyfile(prepared / (language + '.nib'), folder / 'MainMenu.nib')
    # A nonlocalized resource can take precedence over localized resources.
    # Its exact bytes are retained in en.lproj; only that redundant root copy
    # is removed, before any signing step.
    if root_nib.exists():
        root_nib.unlink()
    return {'languages': list(LANGUAGES), 'titles_per_language': len(catalog['source_titles']),
            'native_language': 'macOS bundle language at launch', 'actions_changed': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app')
    args = parser.parse_args()
    catalog = json.loads((ROOT / 'Native/localizations/MainMenu.json').read_text())
    print(json.dumps(install_localizations(args.app, ROOT / 'vendor/hammerspoon/Hammerspoon/MainMenu.xib', catalog)))


if __name__ == '__main__':
    main()
