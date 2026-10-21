# Nivlet 会话交接 · 2026-10-21

## 本轮最新状态 · Build 51 权限恢复

- 本机 /Applications/Nivlet.app 已正常退出备份后切换至 1.0.6 / Build 51 ARM Developer ID 公证测试版，启动、版本及权限重新检测通过。正式签名 Build 49 → 50 无需删除重加辅助功能授权；本轮未修改系统权限。
- 新包复用 Build 49 原生程序及其匹配 dSYM，只更新 Toolkit 和版本元数据后以同一 Developer ID 重签名；并非原生源码重新编译。双架构 App 公证 Accepted、凭证附加和 Gatekeeper 通过；DMG 最终记录见 documentation/VALIDATION.md。
- 统一权限判断，系统返回 false 时也做跨进程只读探测；信任与能力不一致仍拒绝受保护操作并提示退出重开。接入权限变化回调；仅提供退出重开文字引导，并说明非持久化历史退出后清空；按用户要求不新增退出按钮。
- 全部 Lua 回归、真实中英 WebView 权限转换/草稿保留/退出取消、JS 语法、隐私与 diff 检查通过。工具未主动撤销本机权限；用户重授后的状态不同步已观察到，重启 Build 51 后恢复，没有新增 Intel 真机运行验收。
- 公开 Release/tag/feed 均保持 1.0.6 / Build 49，公开附件没有替换；Build 51 仅本地候选。旧 Build 49 和 Build 50 安装副本分别保留于本地 build/permission-recovery50/installed-backup49/ 与 build/permission-recovery51/installed-backup50/。
- 本轮代码与文档可按用户授权审计后提交推送；不据此自动新建 Release。website/ 继续排除。私钥和公证凭据只在钥匙串，不导出或提交。

## 2026-10-14 历史发布状态

当前正式版本：1.0.6 / Build 49，macOS 13+，arm64 / x86_64；GitHub Latest 为 v1.0.6，tag 指向 49687b3。1.0.0–1.0.5 旧正式版保留。

本机 /Applications/Nivlet.app 为 1.0.5 / Build 48 重复应用提示修复测试版，复用 Build 47 原生程序/dSYM、更新资源后重签名；已安装启动核对。本轮 Build 49 为双架构全新源码构建，不自动安装。此前 Build 45 权限恢复为历史证据，不能当作 Build 48/49 当前授权状态。

本轮1.0.6 / Build49正式发布及收尾完成：六附件、官网和双架构feed回核通过，旧版保留；权限观察列P2，下一开发项A15，等待新指令。最新提交以 git log 为准，避免本文件自引用提交号。

## 已完成

- 重复添加应用仍定位/高亮原配置，但底部提示改为信息，3 秒消失且切页返回不再恢复；不再写入 footerErrors，真实校验/保存错误优先。

- 复制成功提示进入底部，3 秒消失；移除历史工具栏提示行，列表和滚动位置不跳动；失败/预览/刷新复用底部，切页后迟到响应不串页。

- 浏览数据入口只支持已安装 Safari / Chrome，原按钮自然宽度、同宽菜单和 24×24 图标保留；只打开浏览器原生确认窗口，不执行清除。
- 应用安装/卸载后返回设置、切入相关页或添加应用会刷新状态、图标和浏览器选择；卸载后的浏览器改选首个可用项，保存后写入配置，无浏览器时禁用。应用规则/快捷键保留。
- 未安装状态紧跟名称，中文“（未安装）”、英文“ (Not installed)”，复用主题红色。
- 设置错误统一底部，相关字段标红，不在顶部/每行重复；保留校验、首个错误定位与草稿。
- Sparkle 2.10.0 双架构 feed：同版本 ARM 受限项在前、Intel 无硬件限制回退项在后；生成脚本强制双包、架构和版本匹配，防止再次遗漏 Intel。

## 回归与发布证据

先读 BASELINE.md、ROADMAP.md、documentation/VALIDATION.md、documentation/CODE-REVIEW-2026-10-14.md 和 documentation/RELEASE-v1.0.6.md。Build 45 七组安装资源隔离真实 WebView，Build 47 八组、Build 49 九组源码真实 WebView、全部 Lua、相关 JS/隐私/Dock 回归及双包签名/篡改拒绝通过。公开六附件、官网与 feed 已回核；Build 45 的本机版本/权限与检查更新历史记录保留，Build 49 不自动安装。未发现范围内新的可确认 P0/P1/P2。

Build45安装资源QA副本build/installed-regression45/已按授权清理，审计和验收记录保留；累计发行证据在build/refresh-1.0.2-verification/；本轮验证在 build/release-1.0.6-verification/，发行 App/dSYM 在 build/release-1.0.6-{arm64,x86_64}/；包在 build/packages/。证据和产物不提交。

## 后续边界

权限重新添加后在部分机器需彻底退出重开，按用户决定记录为 P2 待查、不阻塞发布，详见 documentation/KNOWN-ISSUES.md；没有确认是架构差异，不擅自改检测或系统权限。后续开发仍优先 A15 导入预览，其他按 ROADMAP 每次一项。

等待用户反馈或新需求，每次只做一个优化项。Intel 既有 Build 42 用户实测记录保留，本轮没有 Intel Build 49 实际升级验收。其他 macOS、完整更新故障注入、特殊第三方许可人工复核仍按原记录区分。

仍为 ad-hoc 签名，没有 Developer ID/公证；重新授权可能需要移除旧权限条目再添加当前 App。私有更新密钥保留 Keychain，不导出。Xcode 27 第三方 Runtime 的 poison-system-directories 仍用临时 xcconfig 保留为警告，尚未独立修正。

website/ 是独立未跟踪仓库，始终排除。个人 Hammerspoon、默认浏览器、系统权限与个人数据不得随意修改。本轮未读取个人剪贴板内容或清理个人数据目录。按确认的21条路径清理约200.6MiB旧测试候选/夹具/缓存，明细保留于build/release-1.0.6-verification/cleanup-result.json；当前Build48、正式包/dSYM与验收证据保留，不重复清理。非持久化历史按原设计随退出清空，不声称逐条核验历史内容。

截图工具已取消；日志导出、Homebrew 和 V2EX 发布只是讨论，不能当作实施授权。不重复清理旧候选或注册残留。当前文档提交不构成后续功能开发、删除或发布的长期授权。
