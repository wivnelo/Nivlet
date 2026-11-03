# Nivlet 2.0.3 · Build 63

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

- 安装包更小：移除 Nivlet 不会用到的 Hammerspoon 组件（相机、定位、语音与麦克风、蓝牙/USB/HID/MIDI、外部命令行与 IPC、HTTP 服务器、文档浏览器等）及内置 API 文档。安装后约 25 MB（此前约 40 MB），下载包也相应缩小。
- 功能、设置项、界面、配置格式与权限均不变；已有配置和剪贴板历史在升级后保留。
- 内部维护：统一快捷键校验逻辑，合并运行时补丁，并新增自动化测试与持续集成。

## English

- Smaller download and install: removes Hammerspoon components Nivlet never uses (camera, location, speech and microphone, Bluetooth/USB/HID/MIDI, the external command-line tool and IPC, the HTTP server, the documentation browser and others) and the bundled API docs. The installed app is about 25 MB, down from about 40 MB, and the downloads shrink accordingly.
- Features, settings, interface, configuration format and permissions are unchanged; existing settings and clipboard history are kept after updating.
- Maintenance: shared shortcut validation, consolidated runtime patches, and new automated tests with continuous integration.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 63 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证

All command-line regression files, the privacy scan and the runtime patch check passed locally and in CI. The settings UI suites passed in an isolated WKWebView in Simplified Chinese, Traditional Chinese, English and Japanese, light and dark, and in a 620-point compact window. A locally signed copy of the trimmed build launched without errors and loaded every module Nivlet uses. The final app and DMG passed notarization, stapling and Gatekeeper checks; all embedded Mach-O files are arm64.

Other Mac/macOS combinations and a live Sparkle installation of Build 63 have not been claimed as tested.

## Source and artifacts / 源码与产物

Product source: `bc139047501518faea736f53825295759cf36beb`. The release tag adds public documentation; it does not change product files. The notarized package was built from this commit in a neutral temporary directory, with the Hammerspoon runtime rebuilt from the pinned upstream commit and `patches/series`, then trimmed by `scripts/trim-runtime.py`.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.0.3-build63-arm64.zip` | `ef86cf6a9eec0b0b4fbb27d4be20d67fc8c4f66f9e225da8df614b39ea53ce6c` |
| `Nivlet-2.0.3-build63-arm64.dmg` | `0df9e38bb75e59e3023577889cc965894f54d76a47cc904d930d70ce56e75f85` |

ZIP: 8,651,839 bytes (2.0.2: 11,399,096); DMG: 9,209,202 bytes (2.0.2: 13,316,784); installed app about 24.8 MB (2.0.2: 40.5 MB). App notarization `63aba2a3-0303-4eb8-b9a9-68b908fa7448` and DMG notarization `4c483234-20e7-4721-b7b5-8048aedebb3f` were Accepted.

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.3) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)

Public verification: `v2.0.3` resolves to `29d63129d9cfe7856f5fff3a6f1c71c15e1b8923`. All three public attachments were downloaded anonymously and match the accepted artifacts byte for byte; the downloaded app passes strict signing, stapling and Gatekeeper checks. The 12 earlier releases and their assets remain unchanged.

公开回核：三份附件匿名下载与已验收产物逐字节一致，下载 App 的严格签名、票据与 Gatekeeper 通过。正式 tag 对应上述提交，12 个历史版本及其附件保持不变。
