# Nivlet 会话交接 · 2026-10-29

## 当前状态 · 2026-10-29

本节取代下方历史记录中的“当前”，旧记录保留原日期。

- 当前发行与开发基准为 **1.0.8 / Build 55**，于 2026-10-29（Asia/Manila）在既有 GitHub Release v1.0.8 新增六附件；Build 54 附件保留，tag 仍解引用至 `0772475`。
- Shortcuts 和 AppleScript 不再能执行 Lua；localhost、单标签主机名和 IPv6 链接可打开。主 App 使用 `Native/Nivlet.entitlements`。
- 双架构 Developer ID 签名、Apple 公证、附加票据及 Gatekeeper 检查通过。feed 发布于 `338adfb`；`NIVLET_BUILD_NUMBER=55` 更新测试通过。
- 单台 Apple Silicon Mac 经本地测试 feed 完成正式 54 → 55 Sparkle 升级，EdDSA 与安装后 CDHash 核对通过。Intel 无运行环境，仅完成签名、公证、lipo、spctl、stapler 检查。
- 测试机辅助功能需重授，推测与此前 ad-hoc 开发版的 cdhash requirement 有关；正式 54/55 的 designated requirement 相同，但两次 Developer ID 正式发行间的权限延续尚未验证。
- 正式包：`build/release-1.0.8-build55/dist/`；构建使用 `NIVLET_BUILD_NUMBER=55`。后续 PR 观察项：`NSAllowsArbitraryLoads=true`（考虑 `NSAllowsLocalNetworking`）及麦克风请求缺少 audio-input entitlement（54 已存在）。详见 VALIDATION；A15 仍未开始。

## 当前状态 · 2026-10-28

本节取代下方历史记录中的“当前”“等待确认”，旧记录保留原日期。

- 正式版及本机安装元数据均为 **1.0.8 / Build 54**。GitHub Latest 于今日发布，六附件齐全；tag 指向 `0772475`，发布后的 main 为 `6568a6d`（更新 feed 和发行测试）。
- Issue #1 已关闭。`6cfa035` 修复 FinalShell `st` 等无点号 Bundle ID 被拒绝的问题，统一规则保存、前端检查和应用刷新校验。不是尚待诊断的问题。
- 同步前本地 main 与 GitHub main 一致；本地 codex/screenshot 为 main 祖先，落后 27 个提交且无独有提交。远端无该分支，保持原状。
- 本轮重跑全部 Lua、四项相关 JS 和双架构更新测试；复核正式 App 代码签名、App/DMG 公证票据及六附件服务端 digest，全部通过。未将检查扩展为真实升级、回滚、Intel 真机或完整 UI 验收。
- 知识库已迁移为 GitHub 标准 Markdown 工作流，不再依赖 Obsidian；仅更新 Nivlet 项目摘要，保留其他项目未提交修改。
- 下一建议仍为 A15 导入摘要预览，未开始；V01、A19、V02 继续按 ROADMAP 收集证据。本轮不新增功能或替换应用，不改个人配置和系统权限。

## 历史：独立任务恢复 · 2026-10-26

- **项目与目标**：Nivlet 是独立的免费开源 macOS 菜单栏工具，集中提供剪贴板、窗口管理、应用快捷启动、输入法切换与浏览器分流等操作。仓库为 [wivnelo/Nivlet](https://github.com/wivnelo/Nivlet)，本地路径为 `本地 Nivlet 项目目录`；不与其他项目混用开发上下文。
- **已完成**：本轮完成项目身份、路径、交接与远端状态盘点。GitHub Latest 仍为 [1.0.7 / Build 53](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.7)；本地 main 与远端最新提交均为 [`823ae44`](https://github.com/wivnelo/Nivlet/commit/823ae4488d0e27a2a980c767cb98bbf7a12e21fb)。本轮已只读核对本机安装版本元数据为 1.0.7 / 53。既有发行与测试证据沿用下文及 VALIDATION，不视为本轮复测。
- **当前状态：等待确认**。尚未接到新的开发任务；没有正在执行的代码开发、修复或发布。外部 [Issue #1](https://github.com/wivnelo/Nivlet/issues/1) 仍开放，报告添加 FinalShell 输入法规则后无法保存；[评论](https://github.com/wivnelo/Nivlet/issues/1#issuecomment-6368291282) 提供 bundle ID 为 `st`、无点号的线索。此为外部报告，尚未复现或确认根因，也不代表用户已授权修复。
- **下一步建议／待用户确认**：先选择优先级：诊断 Issue #1 的保存问题，或继续 ROADMAP 中未开始的 A15 配置导入摘要预览。功能或设计改动须先说明影响，再由用户决定；本轮不启动任一开发项。
- **协作与保护边界**：主对话用于任务调度，具体工作留在 Nivlet 独立任务。按需整理交接，保留历史，不擅自停止运行中的工作。`website/` 仍是独立本地仓库，保持不动，线上官网来源仍为 `docs/`。本轮仅更新本交接摘要，不改代码、不操作前台 UI 或模拟器、不提交或推送发布；未运行测试。

## 当前状态（2026-10-23 交接记录）

- 当前正式版：**1.0.7 / Build 53**，macOS 13+，Apple Silicon / Intel，旧正式版 1.0.6 / Build 49 保留。
- 双架构 App 已 Developer ID 签名、Apple 公证并附加票据；正式 DMG 也已公证、附加票据并通过 Gatekeeper。ZIP/DMG 内容、源码一致性、校验值、双架构更新签名和篡改拒绝均通过。六附件已公开重新下载，逐个 SHA-256 相同；官网与 appcast 和源码逐字节相同。
- 本机当前为 **1.0.7 / Build 53**：2026-10-23 只读核对安装包版本元数据；Build 52 的 General 权限、“重新检测”和 About 验收属于历史记录，不扩展为 Build 53 全功能验收。
- 以 1.0.7 / Build 53 作为后续开发、验收和文档的统一基准。相较 Build 52 本地候选，Build 53 的主要交付是将 Apple Developer ID 正式签名与 Apple 公证纳入 1.0.7 公开发行及双架构分发流程，沿用已验收的权限修复，不新增业务功能。Build 52 已有签名、公证候选验收记录，保留为历史，不作为当前版本。
- `website/` 是独立本地仓库，保持不动；真正 GitHub Pages 来源是本仓库 main 的 `docs/`。

- [v1.0.7](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.7) 已发布为 Latest，tag 指向 `5137915`；main 后续只补发布验收与交接记录。官网 GitHub Pages 已部署。2026-10-21 本机 Build 52 手动检查曾发现 1.0.7，说明显示正确，选择稍后提醒，当时未安装；2026-10-23 已核对本机为 Build 53。
- 个人知识库的 Nivlet 项目笔记、项目说明与首页索引已同步，备份与核对清单位于本地证据目录；未复制凭据、代码或安装包。

## 本轮最终变更

1. 正式启用 Developer ID 签名与 Apple 公证，双架构 App/DMG 都附加票据。Sparkle Ed25519 继续校验 ZIP 完整性。
2. 修复权限误报：同进程 trust API 为 false，但 Finder AXWindows 成功、用户确认窗口快捷键可用。现在通过实际跨应用访问核实状态，明确 API disabled 仍拒绝；不以 AXRole 读取成功推断全部能力。
3. 统一窗口设置、配置导入、直接粘贴与页面判断；权限变化回调、回到 App 及“重新检测”共同刷新。移除中途多加的退出按钮及无依据的退出重开提示，原界面布局保留。
4. 同步中英文 README、安装/使用/分发/开发文档、官网、版本说明与推广用语。首次旧 ad-hoc → Developer ID 可能需重授一次；后续稳定身份通常可沿用，公证不是权限本身，不作绝对免重授承诺。

## 验证与证据

- 所有 Lua、相关 JS、隐私、第三方声明及真实中英文 WebView 回归通过；WebView 包括权限刷新、草稿保留和普通退出保护。
- Build 53 复用 Build 49 原生程序及匹配 dSYM，只更新已验收的 Build 52 Toolkit 和版本元数据后重签名；不是原生全新编译。
- 证据：本地 `build/release-1.0.7-build53/`；此前安装与同进程诊断记录在 `build/permission-recovery52/` 和 VALIDATION。旧安装副本、正式包、dSYM 保留，不做额外清理。
- 最新包尚未重复 Intel 真机、再一轮系统权限开关和 Option 粘贴；历史 Intel 用户反馈与本轮包级验证分开记录。

## 续开发

先读 BASELINE.md、ROADMAP.md、documentation/VALIDATION.md，并检查实际 Git 与本机安装状态。本轮结束后等待用户新任务，不自动开发。下一建议仍是 A15 配置导入摘要预览，未开始；温度、原生重写、GPL、捐赠与后台自动更新均未实施。

保护个人配置、剪贴板、默认浏览器、系统权限和个人 Hammerspoon。不要把 build/、私钥、公证凭据或知识库内容提交到公开仓库。证书/公证/更新私钥留本机 Keychain，不导出。无需重新生成证书或重复存储公证密码。

个人知识库只同步项目状态、决策与入口，不复制代码、安装包或凭据。后续新聊天以本文件及实时核验为准。
