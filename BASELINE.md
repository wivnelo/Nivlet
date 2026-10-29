# Nivlet 当前基准

更新日期：2026-10-29。

当前正式发行与开发基准：**1.0.8 / Build 55**，macOS 13+，Apple Silicon（arm64）与 Intel（x86_64）。GitHub Latest 为 v1.0.8，Build 55 发布于 2026-10-29（Asia/Manila）；tag 解引用至 `0772475`。双架构 App 和 DMG 继续使用 Apple Developer ID 签名、Apple 公证与附加票据。

本次禁止 Shortcuts 和 AppleScript 在 Nivlet 中执行 Lua（安全加固），修复 localhost、单标签主机名和 IPv6 链接无法打开的问题；主 App 使用仓库 `Native/Nivlet.entitlements`。既有 v1.0.8 Release 新增六个 Build 55 附件，Build 54 附件保留，tag 未移动。正式包位于本地忽略目录 `build/release-1.0.8-build55/dist/`，构建使用 `NIVLET_BUILD_NUMBER=55`。

同步前本地 main 与 origin/main 均为 `6568a6d`，无提交差异；远端只有 main 分支。本地 `codex/screenshot` 位于 `30ec30e`，是 main 的祖先，落后 27 个提交，无独有提交，无需合并或删除。该数量仅对应此次文档同步前快照。

Build 55 双架构签名、公证、附加票据与 Gatekeeper 检查通过；feed 已发布。单台 Apple Silicon Mac 通过本地测试 feed 完成正式 Build 54 → 55 Sparkle 升级，EdDSA 与安装后 CDHash 核对通过；Intel 未运行，仅完成包级检查。辅助功能曾需重授，推测与此前 ad-hoc 开发版有关；两个 Developer ID 正式版之间的权限延续尚未验证。详见 [VALIDATION](documentation/VALIDATION.md)。

2026-10-28 只读核对本机应用版本为 **1.0.8 / Build 54**；这不等同全功能实测。本轮仅同步文档，不修改用户配置、剪贴板、默认浏览器或系统权限。

下一开发建议仍为 A15 配置导入摘要预览，未开始；真实环境、双语辅助功能与特殊许可人工复核仍开放，见 [ROADMAP](ROADMAP.md)。

官网来源为本仓库 `docs/`；独立本地 `website/` 不纳入当前提交。知识库使用 GitHub 与标准 Markdown，只同步项目摘要、决策和入口，不复制代码、安装包、配置或凭据。旧版本及原有验收证据保留，不能当作 Build 55 本轮实测。
