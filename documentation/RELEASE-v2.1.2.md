# Nivlet 2.1.2 · Build 69

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

本版修复截图文字识别，不新增功能。

- 修复：Nivlet 连续运行较长时间（实测约 9 小时）后，截图的“识别文字”、截图翻译和双击 Ctrl 的识别可能每次都提示“识别失败，请重试”，只有重启 Nivlet 才恢复。现在识别一旦失败，会自动在一个全新的进程里再识别一次，通常只多等不到半秒。
- 识别失败时，系统给出的具体错误会写入 Nivlet 日志，便于排查；不会额外弹出提示。
- 失效的确切原因尚未查明，本版通过自动重试绕开它。

设置项、配置格式和权限不变。

## English

This release fixes screen text recognition. It adds no features.

- Fixed: after Nivlet had been running for a long time (about nine hours in the reported case), Recognize Text in screenshots, screenshot translation and double-Ctrl recognition could fail every time with “Recognition failed. Try again.” until Nivlet was restarted. When recognition fails, it is now retried once in a fresh process, which usually adds less than half a second.
- The underlying Vision error is written to Nivlet's log for diagnosis; no extra alert is shown.
- The exact cause of the failure is not yet known; this release works around it with the automatic retry.

Settings, configuration format and permissions are unchanged.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 69 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证

All command-line regression files, including a new test that builds the capture helper and checks fresh-process recognition of Chinese and English text and the rejection of non-image input, the privacy scan and the runtime patch check passed locally and in CI. The user confirmed screenshot and double-Ctrl recognition on a signed test build. The final app and DMG passed notarization, stapling and Gatekeeper checks; all embedded Mach-O files are arm64.

The failing state of a long-running helper could not be reproduced on demand, so the retry was exercised directly rather than after a real failure. Other Mac/macOS combinations and a live Sparkle installation of Build 69 have not been claimed as tested.

## Source and artifacts / 源码与产物

Product source: `4adffefc5618848a1730c28960066765e53bd663`. The release tag adds public documentation; it does not change product files. The notarized package was built from this commit in a neutral temporary directory, with the Hammerspoon runtime rebuilt from the pinned upstream commit and `patches/series`, then trimmed by `scripts/trim-runtime.py`. The product change is limited to `Native/capture/Recognition.swift`, `Native/capture/main.swift` and `Toolkit/modules/capture.lua`.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.1.2-build69-arm64.zip` | `acc421a637192d2293b146587d7d94ee678352d145f0e720288de662571e7de4` |
| `Nivlet-2.1.2-build69-arm64.dmg` | `ad5968f3422811a2095457024dcd87765efe5bb38d74e569c808e48b7c9994fd` |

ZIP: 8,195,266 bytes (2.1.1: 8,192,092); DMG: 9,369,963 bytes (2.1.1: 9,365,881). App notarization `5aad4c47-cdef-4ddc-9444-ba93ccbf0f61` and DMG notarization `46bfe562-6fe3-4825-9427-d84bf1e8f9b1` were Accepted. A first signing run stopped when the DMG timestamp request failed; its partial outputs were set aside and the whole signing and notarization was run again.

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.1.2) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)
