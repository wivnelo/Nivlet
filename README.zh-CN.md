<p align="center">
  <img src="assets/nivlet-icon.png" alt="Nivlet 应用图标" width="112">
</p>

<h1 align="center">Nivlet for Mac</h1>

<p align="center">
  <strong>让常用桌面操作更顺手。</strong><br>
  剪贴板、窗口管理、应用快捷启动与浏览器分流，集中在 Mac 菜单栏。
</p>

<p align="center">
  <strong>简体中文</strong> · <a href="README.md">English</a>
</p>

<p align="center">
  <a href="https://wivnelo.github.io/Nivlet/">官网</a> ·
  <a href="https://github.com/wivnelo/Nivlet/releases/latest">下载安装</a> ·
  <a href="documentation/USAGE.md">使用指南</a> ·
  <a href="https://github.com/wivnelo/Nivlet/issues">问题反馈</a>
</p>

---

Nivlet 是一款免费开源的 macOS 菜单栏工具，将常用操作放在一处。按需启用功能、配置自己的快捷键，无需编写代码，也无需另外安装 Hammerspoon。

## 界面预览

界面参考：浏览器页为 1.0.1 / Build 41，其余页面沿用 1.0.0 / Build 32；中文界面。所有剪贴板文字、网络地址、软件名称/图标、规则及快捷键均为演示数据，不代表默认配置。点击图片可查看大图。

<table>
<tr>
<td width="50%" valign="top"><strong>窗口管理</strong><br><a href="docs/assets/screenshots/windows.jpg"><img src="docs/assets/screenshots/windows.jpg" alt="窗口管理 — synthetic demonstration" width="480"></a></td>
<td width="50%" valign="top"><strong>剪贴板历史</strong><br><a href="docs/assets/screenshots/clipboard.jpg"><img src="docs/assets/screenshots/clipboard.jpg" alt="剪贴板历史 — synthetic demonstration" width="480"></a></td>
</tr>
</table>

<details>
<summary>查看其他六个页面</summary>

<table>
<tr>
<td width="50%" valign="top"><strong>通用设置</strong><br><a href="docs/assets/screenshots/general.jpg"><img src="docs/assets/screenshots/general.jpg" alt="通用设置 — synthetic demonstration" width="480"></a></td>
<td width="50%" valign="top"><strong>输入法切换</strong><br><a href="docs/assets/screenshots/input.jpg"><img src="docs/assets/screenshots/input.jpg" alt="输入法切换 — synthetic demonstration" width="480"></a></td>
</tr>
<tr>
<td width="50%" valign="top"><strong>浏览器分流</strong><br><a href="docs/assets/screenshots/browser.jpg"><img src="docs/assets/screenshots/browser.jpg" alt="浏览器分流 — synthetic demonstration" width="480"></a></td>
<td width="50%" valign="top"><strong>应用快捷启动</strong><br><a href="docs/assets/screenshots/launcher.jpg"><img src="docs/assets/screenshots/launcher.jpg" alt="应用快捷启动 — synthetic demonstration" width="480"></a></td>
</tr>
<tr>
<td width="50%" valign="top"><strong>系统信息</strong><br><a href="docs/assets/screenshots/system.jpg"><img src="docs/assets/screenshots/system.jpg" alt="系统信息 — synthetic demonstration" width="480"></a></td>
<td width="50%" valign="top"><strong>关于与更新</strong><br><a href="docs/assets/screenshots/about.jpg"><img src="docs/assets/screenshots/about.jpg" alt="关于与更新 — synthetic demonstration" width="480"></a></td>
</tr>
</table>

</details>

[浏览完整截图画廊](https://wivnelo.github.io/Nivlet/screenshots.html)

## 能做什么

| 功能 | 用法与亮点 |
| --- | --- |
| **剪贴板历史** | 留存文字与图片，支持搜索、缩略图、放大预览和 Option 直接粘贴；可暂停、排除应用与设置保留期限 |
| **窗口管理** | 29 项操作，覆盖半屏、四角、三分区、九宫格、居中、缩放、跨屏与恢复 |
| **应用快捷启动** | 自定义快捷键，启动应用或切到前台；支持更换应用、拖动排序与冲突检查 |
| **浏览器分流** | 按域名或来源应用选择浏览器，让不同链接去往合适的目标 |
| **输入法切换** | 为应用指定输入法，切换应用时自动切换 |
| **系统信息** | 菜单栏查看网速，按需展示 CPU、内存、磁盘、网络地址和日期 |
| **个性化与迁移** | 中英文、深浅色、标签排序，以及 JSON 配置导入导出 |

## 开始使用

1. 从 [GitHub Releases](https://github.com/wivnelo/Nivlet/releases/latest) 下载 **DMG 或 ZIP**，任选一个。
2. 将 `Nivlet.app` 放入“应用程序”文件夹并打开。
3. 点击菜单栏 **N 图标 → 设置…**，启用需要的功能并配置规则。
4. 点击右下角 **保存设置**。切换页面会保留草稿，未保存页面的标签下方有小橙点提示。

功能按需开启，快捷键由你配置。窗口管理和 Option 直接粘贴需要**辅助功能权限**；浏览器分流需要将 **Nivlet 设为默认浏览器**。

## 正式开发者签名与 Apple 公证

**v1.0.8 / Build 55 已启用 Apple Developer ID 正式签名，并通过 Apple 公证。** Apple Silicon（arm64）与 Intel（x86_64）的 App、DMG 均附加公证票据。系统要求 macOS 13.0+。

从 [GitHub Releases](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8) 下载对应芯片的 DMG 或 ZIP，将 `Nivlet.app` 放入应用程序后打开，无需另装 Hammerspoon。

签名与公证不代替**辅助功能授权**。从旧 ad-hoc 版首次迁移可能需要重新授权；此后同一开发者身份的正常更新通常可沿用授权，具体仍取决于 macOS。授权后回通用页自动检测，或点击“重新检测”。无需关闭 Gatekeeper；若出现恶意软件、应用损坏或校验不符提示，请停止安装并反馈。

详见[安装、升级和卸载指南](documentation/INSTALLATION.md)。关于页保留手动“检查更新…”，确认后安装。

## 本地处理，按需记录

无需账号。配置、剪贴板与系统信息在本机处理，不上传服务器；核心桌面工具可离线使用。打开网页、外部链接与主动检查更新会联网。

剪贴板历史默认退出后清空，可选择跨重启保留；持久历史使用**本地明文缓存**，复制敏感内容前可以暂停记录。清空历史会同时清空系统当前剪贴板，操作前会提示确认。

## 了解更多

- [使用指南](documentation/USAGE.md) · [配置导入导出](documentation/CONFIGURATION.md)
- [版本记录](https://github.com/wivnelo/Nivlet/releases) · [开发计划](ROADMAP.md)
- [开发与构建](documentation/DEVELOPMENT.md)

遇到问题或有建议，请提交 [GitHub Issue](https://github.com/wivnelo/Nivlet/issues)，附上应用版本、macOS 版本与复现步骤。请勿上传敏感剪贴板、私人配置或凭据。

## 许可证与致谢

Nivlet 使用 [MIT License](LICENSE)。内置 Runtime 基于 [Hammerspoon](https://github.com/Hammerspoon/hammerspoon)；第三方组件保留各自许可证，见 [第三方声明](THIRD-PARTY-NOTICES.md)。

1.0.8 修复 FinalShell 等无点号 Bundle ID 应用无法保存规则的问题，继续采用正式开发者签名与 Apple 公证。详见[版本说明](documentation/RELEASE-v1.0.8.md)。
