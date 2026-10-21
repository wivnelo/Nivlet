# Nivlet 1.0.7 · Build 53

- **正式启用 Apple Developer ID 签名，并通过 Apple 公证。** Apple Silicon（arm64）与 Intel（x86_64）的 App 和 DMG 均已公证并附加票据。
- 修复重新授权后辅助功能状态误报：通过实际跨应用访问核实权限，避免功能可用却显示未授权。
- 接入系统权限变化通知，保留回到 App 自动检测与“重新检测”；统一窗口设置、配置导入和 Option 直接粘贴的权限判断。
- 保留原有界面布局，不新增退出按钮或要求退出重开的提示。

macOS 13+，免费开源，无需账号。请选择对应芯片的 DMG 或 ZIP，SHA-256 文件用于核对下载。旧正式版保留。

### 安装与升级

从本次 Release 下载，将 Nivlet.app 放入 Applications。签名与公证不代替辅助功能授权，也不代表 App Store 上架。首次从旧 ad-hoc 版迁移时，macOS 可能要求重新授权；此后保持同一开发者身份的正常更新通常可沿用授权，但不作所有系统均免授权的保证。授权后回到通用页自动检测，或点击“重新检测”。不需要关闭 Gatekeeper；如出现损坏或恶意软件警告，应停止安装并反馈。

[安装与升级指南](https://github.com/wivnelo/Nivlet/blob/main/documentation/INSTALLATION.md) · [官网](https://wivnelo.github.io/Nivlet/) · [反馈 Issue](https://github.com/wivnelo/Nivlet/issues)

## English

- **Now signed with Apple Developer ID and notarized by Apple.** Apple Silicon (arm64) and Intel (x86_64) apps and DMGs are notarized with stapled tickets.
- Fix false Accessibility status after reauthorization by checking live cross-app access instead of relying only on a stale trust Boolean.
- Refresh status on permission-change notifications; retain automatic checks on return and the Recheck button. Use a consistent permission check for window settings, configuration imports and Option-paste.
- Preserve the existing settings layout without an extra quit button or restart instruction.

Requires macOS 13+. Free and open source, with no account required. Choose the DMG or ZIP for your chip; SHA-256 files verify download integrity. Previous releases are retained.

Signing and notarization do not grant Accessibility access and do not mean App Store distribution. Moving from an older ad-hoc build may require reauthorization once. Subsequent updates with a stable developer identity generally retain permission, subject to macOS behavior. Return to General or click Recheck after granting access. Do not disable Gatekeeper; stop and report any damaged-app or malware alert.
