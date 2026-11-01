# Native menus

`MainMenu.json` translates the titles of all 78 named objects in the pinned,
patched `MainMenu.xib`. Object IDs and original titles are verified before a
build. Changes to selectors, shortcuts, outlets, visibility or any other
interface attributes are forbidden by the generator and regression test.

`scripts/localize-native-menu.py` compiles Simplified Chinese, Taiwan Traditional
Chinese and Japanese menus before signing. It moves the original English nib
unchanged into `en.lproj`; all four native menu resources are selected by macOS
bundle language at launch. Taiwan terminology is also the Traditional Chinese
fallback for Hong Kong. The native menu is not switched by Toolkit's in-app
language preference. AppKit-generated items and framework dialogs retain their
system/framework localization behavior; no `AppleLanguages` setting is written.

Translations received independent AI language review, not human native-speaker
proofreading. The Taiwan Edit > Substitutions terminology was checked against
[Apple's text replacement guide](https://support.apple.com/zh-tw/guide/mac-help/mh35735/mac).

Validation:

- `python3 tests/native_menu_localizations.py` checks title-only changes,
  complete mappings, unchanged English/runtime resources, idempotency,
  compiler failure and unsafe output paths.
- `NIVLET_TEST_NATIVE_COMPILE=1 python3 tests/native_menu_localizations.py` also
  compiles the three real nib archives with `ibtool` and runs a Foundation-only
  bundle lookup probe. It checks en-US, zh-CN, zh-TW, zh-HK and ja-JP selection,
  without loading a nib, launching Nivlet or modifying user preferences.
