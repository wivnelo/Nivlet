# Nivlet 2.0.4 · Build 64

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

- 浏览器分流不再丢弃无法解析的链接：带登录信息（`user@host`）、端口异常、域名未使用 punycode 或格式不规范，以及超过 16 KB 的 HTTP / HTTPS 链接，现在原样交给“默认打开浏览器”，此前只显示一条提示。
- 这类链接不参与域名规则和来源应用规则匹配，一律使用默认打开浏览器。
- 其他协议、含空白或控制字符、缺少主机名以及超过 1 MB 的链接仍然拒绝。

本版本不新增功能，不改变设置项、界面、配置格式或权限。

## English

- Browser routing no longer drops links it cannot parse. HTTP / HTTPS links with sign-in information (`user@host`), an invalid port, a host that is malformed or not in punycode, or a length over 16 KB are now handed unchanged to the configured default browser. Previously they only produced an alert.
- These links skip domain rules and source application rules and always use the default browser.
- Other schemes, links with whitespace or control characters, links without a host and links over 1 MB are still rejected.

This release adds no features and does not change settings, interface, configuration format or permissions.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 64 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证

All command-line regression files, the privacy scan and the runtime patch check passed locally and in CI. The settings UI suites, which this release does not change, passed in CI in Simplified Chinese, Traditional Chinese, English and Japanese, light and dark. A locally signed copy of the build launched without errors. The final app and DMG passed notarization, stapling and Gatekeeper checks; all embedded Mach-O files are arm64.

The routing fallback is covered by Lua unit tests, not by clicking such links in a running app. Other Mac/macOS combinations and a live Sparkle installation of Build 64 have not been claimed as tested.

## Source and artifacts / 源码与产物

Product source: `b0c64e7c6bbc968439f2e3c652373fe10f959331`. The release tag adds public documentation; it does not change product files. The notarized package was built from this commit in a neutral temporary directory, with the Hammerspoon runtime rebuilt from the pinned upstream commit and `patches/series`, then trimmed by `scripts/trim-runtime.py`. The runtime, patches and trim list are the same as in 2.0.3; the product change is limited to `Toolkit/modules/browser.lua`.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.0.4-build64-arm64.zip` | `9351440b9c66914cd946983bcbd4d5e9ab0732ebc85dee9288c952b91552d2e7` |
| `Nivlet-2.0.4-build64-arm64.dmg` | `535d5045bdc418019e1b922824b14f954397e03ad9a6d58ec7d29ec7e67b42be` |

ZIP: 8,650,518 bytes (2.0.3: 8,651,839); DMG: 9,208,054 bytes (2.0.3: 9,209,202); installed app about 24.8 MB, unchanged. App notarization `5c30fbd5-b3b6-4d07-bc67-ebddd32674fa` and DMG notarization `2d7be8b0-5081-4b6f-bcf1-16bee9c9fcd0` were Accepted.

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.4) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)
