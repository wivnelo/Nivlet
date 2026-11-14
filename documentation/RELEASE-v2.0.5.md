# Nivlet 2.0.5 · Build 65

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

- 新的应用图标：保留折带 N 的造型，改用石墨灰底板配柔和的青蓝色 N，更贴近 macOS 风格，在深浅色背景下都清晰。
- 菜单栏 N 图标随之重绘，与新图标的折带造型一致。
- 设置窗口和“关于”页使用新图标。

本版本不新增功能，不改变设置项、配置格式或权限。

## English

- New app icon: the folded-ribbon N in soft teal and blue on a graphite plate, closer to macOS style and clear on light and dark backgrounds.
- The menu bar N is redrawn to match the new ribbon shape.
- The settings window and About page use the new icon.

This release adds no features and does not change settings, configuration format or permissions.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 65 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证


All command-line regression files, the privacy scan and the runtime patch check passed locally. A locally signed copy of the build replaced the installed app, launched without an error dialog and showed its menu bar items; the main N icon was hidden by that Mac's own setting, so the new menu bar glyph was checked in the packaged files rather than on screen. The final app and DMG passed notarization, stapling and Gatekeeper checks; all embedded Mach-O files are arm64.

Only icons and media change in this release. Other Mac/macOS combinations and a live Sparkle installation of Build 65 have not been claimed as tested.

## Source and artifacts / 源码与产物

Product source: `2a60c5568e6d3c98e8073e6d20ace8015caffc2a`. The release tag adds public documentation; it does not change product files. The notarized package was built from this commit in a neutral temporary directory, with the Hammerspoon runtime rebuilt from the pinned upstream commit and `patches/series`, then trimmed by `scripts/trim-runtime.py`. Runtime, patches, trim list and Lua code are the same as in 2.0.4; the product change is limited to `assets/nivlet-icon.png` and `Toolkit/assets/nivlet-menu.png` / `.svg`. README and website screenshots and demo GIFs were re-rendered with the new icon.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.0.5-build65-arm64.zip` | `af460f0ba28ddfb2682522aa0ec3f786c2edd3d412a5edfbb3a60d42e2590b02` |
| `Nivlet-2.0.5-build65-arm64.dmg` | `d2bdcdb913d44df6dc9b56dcf4c155209604645be1301eb7ee0c1854e7db3e3d` |

ZIP: 7,926,957 bytes (2.0.4: 8,650,518); DMG: 8,489,358 bytes (2.0.4: 9,208,054). The smaller icon source accounts for the difference. App notarization `bda8ce59-dd20-4a56-af57-17c787dcfdee` and DMG notarization `52925dcd-b13f-45b7-bc88-d938d37694ff` were Accepted.

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.5) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)

Public verification: `v2.0.5` resolves to `ef7fab246daf0a2923266e7604721721639f3d83`. All three public attachments were downloaded anonymously and match the accepted artifacts byte for byte; the downloaded app passes strict signing, stapling and Gatekeeper checks. `releases/latest` points to `v2.0.5`; 14 earlier releases remain listed.

公开回核：三份附件匿名下载与已验收产物逐字节一致，下载 App 的严格签名、票据与 Gatekeeper 通过。正式 tag 对应上述提交，`releases/latest` 指向 `v2.0.5`，此前 14 个版本仍在列表中。
