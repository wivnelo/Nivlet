# Nivlet 2.0.2 · Build 62

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

- 菜单栏网速图标只在显示的文字变化时才重新绘制，网络空闲时不再每 2 秒重复生成图标。
- 关闭“网速”显示后，后台系统信息采集由每 2 秒改为每 60 秒；打开设置中的系统信息页时仍实时刷新。此时菜单中的农历日期最多延迟一分钟更新。
- 剪贴板历史在后台检查时减少重复工作：未超出条数上限时不再重建列表；图片大小沿用复制时已得到的结果，设置页缩略图只编码一次。
- 设置页每次回传数据时，已配置应用的图标只查找一次。

本版本不新增功能，不改变设置项、界面、配置格式或权限。

## English

- The menu bar network speed icon now redraws only when its text changes, instead of rebuilding the image every 2 seconds while the network is idle.
- With the network speed display turned off, background system information sampling runs every 60 seconds instead of every 2 seconds. The System Info settings page still refreshes live. The lunar date in the menu may then update up to a minute late.
- Clipboard history does less repeated work while checking in the background: the list is no longer rebuilt unless a limit is exceeded, image sizes reuse the value measured at copy time, and settings thumbnails are encoded once.
- Each settings page reply looks up configured app icons once instead of twice.

This release adds no features and does not change settings, interface, configuration format or permissions.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 62 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证

All 36 Lua regression files, command-line JavaScript and Python checks and the privacy scan passed. The 35 settings UI suites passed in an isolated WKWebView in Simplified Chinese, Traditional Chinese, English and Japanese, light and dark, plus a 620-point compact window (350 checks). A locally signed test build of the same product changes ran in place of 2.0.1 without runtime errors. The final app and DMG passed notarization, stapling and Gatekeeper checks; all embedded Mach-O files are arm64.

Menu bar redraw timing, background sampling intervals and clipboard polling are covered by Lua unit tests, not by native end-to-end measurement. Other Mac/macOS combinations and a live Sparkle installation of Build 62 have not been claimed as tested.

## Source and artifacts / 源码与产物

Product source: `b9db87155ddff5425a45dd00e43f8a98feb45e28`. The release tag adds public documentation; it does not change product files. The notarized package was built from this commit in a neutral temporary directory, with the Hammerspoon runtime rebuilt from the pinned upstream commit and all patches in `scripts/fetch-runtime.sh` order.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.0.2-build62-arm64.zip` | `6b46dd1774a1efb1fe77fa5a1c05ebf276372331b4efda488e672595fa810720` |
| `Nivlet-2.0.2-build62-arm64.dmg` | `707caa25abdb8344c504f7481cc6b0e91f84e3cb565ff56e1ea2845056344d3a` |

ZIP: 11,399,096 bytes; DMG: 13,316,784 bytes. App notarization `21b96d8a-45f4-48f5-9f45-f1ba23a39830` and DMG notarization `285e0a75-1f49-46b4-b8b6-f4428d2885e6` were Accepted.

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.2) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)

Public verification: `v2.0.2` resolves to `756c38f22e328b07e547dee749dce077521b9b11`. All three public attachments were downloaded anonymously and match the accepted artifacts byte for byte; the downloaded app passes strict signing, stapling and Gatekeeper checks. The 11 earlier releases and their assets remain unchanged.

公开回核：三份附件匿名下载与已验收产物逐字节一致，下载 App 的严格签名、票据与 Gatekeeper 通过。正式 tag 对应上述提交，11 个历史版本及其附件保持不变。
