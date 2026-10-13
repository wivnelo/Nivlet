# Nivlet 1.0.1 · Build 41

- 浏览器页右上角新增“清除浏览数据…”：选择已安装的 Safari / Chrome 后打开原生清除窗口，最终由用户选择范围并确认。需要辅助功能权限。
- 修复快捷键或 Dock 再次唤起 Nivlet 时跳回通用页面，保留原页面。
- 修复浏览器菜单刷新焦点、切页残留和过期请求问题。

macOS 13.0+。Apple Silicon 为当前更新通道支持架构；另附 Intel (x86_64) 候选包，**待 Intel 真机验证**，请按芯片下载。Intel 包不进入自动更新 feed。

配置和剪贴板数据保留在本机。使用 ad-hoc 签名，没有 Apple Developer ID 签名或公证；更新后可能需要重新授权辅助功能。首次安装见[安装指南](INSTALLATION.md)。

## English

- Add a browser-data action for Safari and Chrome. Select a browser, then choose and confirm what to clear in its native dialog. Accessibility permission is required.
- Preserve the current settings page when reopening Nivlet through an app shortcut or the Dock.
- Fix menu focus loss, stale menus across pages and delayed permission responses.

Requires macOS 13+. The signed update feed targets Apple Silicon. An Intel candidate is included for manual testing; Intel hardware validation is pending. No Developer ID signature or notarization yet. Settings and clipboard data remain local.
