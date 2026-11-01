# Japanese localization

The Japanese dictionary is `Toolkit/modules/translations_ja.lua`. It maps the existing Simplified Chinese source keys to Japanese; it does not translate user clipboard content, application names, identifiers, URLs, or input-source names supplied by macOS.

## Copy conventions

The copy is written for a small Mac utility: short action labels, clear results, and a concrete next step when something fails. It uses Japanese punctuation and readable word order rather than mirroring the Chinese sentence structure. The initial set contains all 490 unique keys in the existing English dictionary, the missing import explanation, and the two new language self-names. Integration adds `核心` → `コア` for the CPU core-count display, bringing the expected set to 494 entries.

| Concept | Japanese | Context |
| --- | --- | --- |
| General | 一般 | Sidebar and general preferences |
| Window | ウインドウ | Mac window actions and layouts |
| Input source | 入力ソース | The selected keyboard/input method, not a translation of application content |
| Source app | リンク元アプリ | The app from which a web link was opened |
| Browser routing | ブラウザの振り分け | Selects which installed browser opens a link |
| Save all settings | すべての設定を保存 | Saves changed pages together |
| Discard page changes | このページの変更を破棄 | Restores the saved settings for the current page |
| Cancel | キャンセル | Cancels a dialog/action; distinct from discarding a draft |
| Accessibility access | アクセシビリティへのアクセス | The macOS permission required by window actions and direct paste |
| Clipboard history | クリップボードの履歴 | Previously recorded items, distinct from the current system clipboard |
| Retention | 保持期間 / 履歴の保持 | Time limit / group heading |
| Export / import settings | 設定を書き出す / 設定を読み込む | Configuration files |

Brand names (`Nivlet`, `Safari`, `GitHub`), `Bundle ID`, `HTTP / HTTPS`, `file`, `.html / .htm`, `punycode`, and shortcut tokens such as `⌘ + L`, `Command + L`, `Return`, `Control`, and `Option` are retained. Language choices use their self-names: `简体中文`, `繁體中文`, `English`, `日本語`.

Numeric limits and the meaning of destructive actions remain unchanged. For example, clearing history explicitly describes both Nivlet history/cache deletion and emptying the system clipboard, and says the action cannot be undone. Partial-save and recovery messages do not promise a transaction or successful restoration.

## Verification and limits

- Lua loading, coverage of all 490 original keys, and printf-format-token parity passed.
- Static HTML scanning found one existing missing English key: `导入会替换文件中包含的模块及其未保存输入，其他模块保持不变。`; the Japanese dictionary includes it and it has been reported for shared integration.
- Explicit Lua translation calls and standalone Chinese JavaScript literals had no other missing dictionary key in the inspected source.
- The dictionary was AI-authored and self-reviewed against feature code. Independent AI review and rendered-page verification are part of the parent integration task. No human native-speaker review is claimed.
- External application names and input-source names retain their system-provided language. Japanese UI selection does not change macOS or browser language.
- Safari's native menu language is separate from the Nivlet UI language. The translation audit found only Simplified Chinese and English paths in the original helper and reported the need for integration; no browser UI or clearing action was invoked. Apple's current help confirms Japanese `履歴 > 履歴を消去` and Taiwanese Traditional Chinese `瀏覽記錄 > 清除瀏覽記錄`. The help text omits trailing ellipses, so it alone does not establish the exact accessibility label suffix. See [Japanese Safari help](https://support.apple.com/ja-jp/guide/safari/sfri47acf5d6/mac) and [Taiwan Safari help](https://support.apple.com/zh-tw/guide/safari/sfri47acf5d6/mac).
