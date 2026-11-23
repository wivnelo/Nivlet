# Nivlet 2.1.3 · Build 70

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

本版改进截图窗口的退出和二维码结果的操作，不新增功能。

- 二维码识别结果新增“复制并关闭”，和文字识别面板一致；按回车也会复制第一条结果并关闭截图。网址的“打开链接”移到左侧。
- 单击选框外部即可退出截图，和 Esc、右键一样；识别面板打开时也可以。按住拖动仍是重新框选；正在输入标注文字时，单击外部只结束输入，不会退出。
- 点到工具栏、属性栏或识别面板按钮之间的空白处，不再误关面板或退出截图。

设置项、配置格式和权限不变。

## English

This release improves leaving a capture and working with QR results. It adds no features.

- QR code results now have Copy and Close, matching the text recognition panel; Return also copies the first result and closes the capture. Open Link for web addresses moves to the left.
- A single click outside the selection leaves the capture, like Esc or a right-click, including while a result panel is open. Dragging outside still starts a new selection; while you are typing an annotation, a click outside only finishes the text.
- Clicking empty space between buttons in the toolbars or the result panel no longer closes the panel or leaves the capture.

Settings, configuration format and permissions are unchanged.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 70 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证

All command-line regression files, the privacy scan and the runtime patch check passed locally and in CI. The settings UI suites passed in Simplified Chinese, Traditional Chinese, English and Japanese, light and dark, at 980 and 620 points wide. A self-test of the capture overlay confirmed that a click outside the selection leaves the capture, a drag outside starts a new selection and a click on empty toolbar space keeps the selection. The QR result panel was rendered and reviewed in light and dark mode in all four languages. The final app and DMG passed notarization, stapling and Gatekeeper checks; all embedded Mach-O files are arm64.

Other Mac/macOS combinations, multi-display capture and a live Sparkle installation of Build 70 have not been claimed as tested.

## Source and artifacts / 源码与产物

Product source: `7c226c9e8bfb2f2359db129c0cb02d3040b11975`. The release tag adds public documentation; it does not change product files. The notarized package was built from this commit in a neutral temporary directory, with the Hammerspoon runtime rebuilt from the pinned upstream commit and `patches/series`, then trimmed by `scripts/trim-runtime.py`. It includes the 2.1.2 text recognition retry.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.1.3-build70-arm64.zip` | `182f4f01d108821d39ab0edc698122358ba5263f357ee654d3c73400859c97f8` |
| `Nivlet-2.1.3-build70-arm64.dmg` | `670b030dbc1b0c5d373b21b79100e442c0ed9b85b3c6fa5ecd56080102b1116c` |

ZIP: 8,195,393 bytes (2.1.2: 8,195,266); DMG: 9,371,355 bytes (2.1.2: 9,369,963). App notarization `c55fa062-6952-4248-9513-82906548d5ec` and DMG notarization `d5aaee19-f78e-44b0-84b5-f5a78d840b39` were Accepted.

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.1.3) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)

Public verification: `v2.1.3` resolves to `245db2d05dcd3e7becfe99c31d1eee713f64de87`. All three public attachments were downloaded anonymously and match the accepted artifacts byte for byte; the downloaded app passes strict signing, stapling and Gatekeeper checks. `releases/latest` points to `v2.1.3`; 19 earlier releases remain listed.

公开回核：三份附件匿名下载与已验收产物逐字节一致，下载 App 的严格签名、票据与 Gatekeeper 通过。正式 tag 对应上述提交，`releases/latest` 指向 `v2.1.3`，此前 19 个版本仍在列表中。
