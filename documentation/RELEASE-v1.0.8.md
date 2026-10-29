# Nivlet 1.0.8 · Build 55

发布：2026-10-29（Build 54 为 2026-10-28），macOS 13+，Apple Silicon / Intel。

- Build 55 安全加固：快捷指令和 AppleScript 不再能在 Nivlet 中运行 Lua 代码。
- Build 55 修复 localhost、单标签主机及 IPv6 地址链接无法打开的问题。
- 修复 FinalShell 等应用的 Bundle ID 不含点号时，输入法、应用启动、浏览器来源和剪贴板排除规则无法保存的问题（[Issue #1](https://github.com/wivnelo/Nivlet/issues/1)）。
- 统一前后端 Bundle ID 校验及应用状态刷新检查，继续拒绝空值、非法字符和超长标识。
- 继续使用 Apple Developer ID 签名与 Apple 公证；双架构 App 和 DMG 附加票据，更新 ZIP 由 Sparkle Ed25519 校验。

[正式下载](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8) · [安装与升级](INSTALLATION.md) · [验收边界](VALIDATION.md)

## English

- Build 55 security hardening: Shortcuts and AppleScript can no longer run Lua code in Nivlet.
- Build 55 fixes links to localhost, single-label hosts and IPv6 addresses failing to open.
- Fix rule saving for apps with dotless Bundle IDs, including FinalShell, across input-source rules, launcher rules, browser source rules and clipboard exclusions (Issue #1).
- Use consistent frontend/backend validation and application-refresh checks while rejecting empty, malformed and oversized identifiers.
- Retain Developer ID signing, Apple notarization and stapled app/DMG tickets for Apple Silicon and Intel. Sparkle Ed25519 signatures protect update ZIPs.

Requires macOS 13+. Signing and notarization do not grant Accessibility permission. See the [installation guide](INSTALLATION.en.md).
