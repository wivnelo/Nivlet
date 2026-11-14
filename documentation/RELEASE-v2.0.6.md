# Nivlet 2.0.6 · Build 66

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

- 新的 DMG 安装界面：打开安装包后，窗口左侧是 Nivlet，右侧是“应用程序”文件夹，中间有箭头和“拖到‘应用程序’即可安装”的中英提示，背景取自新图标的青蓝配色。
- 窗口隐藏了工具栏和侧栏，浅色和深色模式下文件名都清晰可读。

App 本身与 2.0.5 相同，只更新版本号；不新增功能，不改变设置项、配置格式或权限。

## English

- New DMG install window: Nivlet on the left, the Applications folder on the right, with an arrow and a bilingual “Drag Nivlet to Applications to install” hint on a teal background taken from the new icon.
- The window hides the toolbar and sidebar, and file names stay readable in both light and dark mode.

The app itself is the same as 2.0.5 apart from the version number. This release adds no features and does not change settings, configuration format or permissions.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 66 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证

All command-line regression files, the privacy scan and the runtime patch check passed locally and in CI. The DMG layout files, background, Applications link and the app signature inside the DMG were verified on a read-only mount. The final app and DMG passed notarization, stapling and Gatekeeper checks; all embedded Mach-O files are arm64.

Other Mac/macOS combinations and a live Sparkle installation of Build 66 have not been claimed as tested.

## Source and artifacts / 源码与产物

Product source: `386f844e26425c14830300f2f11950a72b50da9b`. The release tag adds public documentation; it does not change product files. The notarized package was built from this commit in a neutral temporary directory, with the Hammerspoon runtime rebuilt from the pinned upstream commit and `patches/series`, then trimmed by `scripts/trim-runtime.py`. The app differs from 2.0.5 only in its version metadata. The DMG is now built by `scripts/make-dmg.py` with dmgbuild 1.6.5 and the assets in `assets/dmg/`.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.0.6-build66-arm64.zip` | `ca0c37f64acfb4949c3e08992c66c2e33eccb7d6ea518d8fd0eeb2d43a680e3e` |
| `Nivlet-2.0.6-build66-arm64.dmg` | `0da54c703bd329de37fc2b6aac4b180d9b80db2c135ae56592d74786fd418c54` |

ZIP: 7,926,514 bytes (2.0.5: 7,926,957); DMG: 9,077,737 bytes (2.0.5: 8,489,358), the difference being the install-window background. App notarization `b8bc85d2-c103-42a5-8e07-0b2f1c43cfe0` and DMG notarization `e6b4daa1-eff5-46d3-9aa6-77a3975a3f74` were Accepted.

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.6) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)
