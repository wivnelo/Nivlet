# Nivlet 当前基准

更新日期：2026-10-28。

当前正式发行与开发基准：**1.0.8 / Build 54**，macOS 13+，Apple Silicon（arm64）与 Intel（x86_64）。GitHub Latest 为 v1.0.8，发布于 2026-10-28；tag 解引用至 `0772475`。双架构 App 和 DMG 继续使用 Apple Developer ID 签名、Apple 公证与附加票据。

本次修复 [Issue #1](https://github.com/wivnelo/Nivlet/issues/1)：FinalShell 的 Bundle ID 为 `st`，旧校验错误要求包含点号，导致规则无法保存。`6cfa035` 统一后端 Bundle ID 校验，并同步前端检查及应用状态刷新入口，覆盖输入法、应用启动、浏览器来源与剪贴板排除；不新增业务功能。1.0.7 的权限误报修复继续保留。

同步前本地 main 与 origin/main 均为 `6568a6d`，无提交差异；远端只有 main 分支。本地 `codex/screenshot` 位于 `30ec30e`，是 main 的祖先，落后 27 个提交，无独有提交，无需合并或删除。该数量仅对应此次文档同步前快照。

本轮全部 Lua 回归及应用更换、退出保护、快捷键录入、标签边界 JS 回归通过；双架构更新源、ZIP CRC、SHA-256、签名及篡改拒绝通过。正式双架构 App 严格代码签名、App/DMG 公证票据验证通过；六附件本地 SHA-256 与 GitHub 服务端 digest 相同。未重新公开下载全部附件或执行实际更新安装、回滚及 Intel 真机验收。详见 [VALIDATION](documentation/VALIDATION.md)。

2026-10-28 只读核对本机应用版本为 **1.0.8 / Build 54**；这不等同全功能实测。本轮仅同步文档，不修改用户配置、剪贴板、默认浏览器或系统权限。

下一开发建议仍为 A15 配置导入摘要预览，未开始；真实环境、双语辅助功能与特殊许可人工复核仍开放，见 [ROADMAP](ROADMAP.md)。

官网来源为本仓库 `docs/`；独立本地 `website/` 不纳入当前提交。知识库使用 GitHub 与标准 Markdown，只同步项目摘要、决策和入口，不复制代码、安装包、配置或凭据。旧版本及原有验收证据保留，不能当作 Build 54 本轮实测。
