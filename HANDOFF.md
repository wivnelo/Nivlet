# Nivlet 会话交接 · 2026-10-14

## 当前状态

当前正式版本 1.0.4 / Build 45，macOS 13+，提供 arm64 / x86_64 六个正式附件；GitHub Latest 为 v1.0.4，tag 指向 9e4572d。1.0.0–1.0.3 历史正式版保留，不覆盖旧附件。

本机 /Applications/Nivlet.app 已手动安装并启动 Build 45，与发行 App 全部普通文件及源码 Toolkit 一致，严格签名通过。用户明确授权后，从系统权限列表移除旧 Nivlet 并重新添加当前 App，真实 UI 已检测“辅助功能权限已开启”。不需要再次操作权限或安装。

当前收尾任务：按本机安装版复跑回归、审计和同步文档。功能源码已经提交发布；本次只提交最新文档与审计，不新增功能、改包或改版本。最新提交以 git log 为准，避免本文件自引用提交号。

## 已完成

- 浏览数据入口只支持已安装 Safari / Chrome，原按钮自然宽度、同宽菜单和 24×24 图标保留；只打开浏览器原生确认窗口，不执行清除。
- 应用安装/卸载后返回设置、切入相关页或添加应用会刷新状态、图标和浏览器选择；卸载后的浏览器改选首个可用项，保存后写入配置，无浏览器时禁用。应用规则/快捷键保留。
- 未安装状态紧跟名称，中文“（未安装）”、英文“ (Not installed)”，复用主题红色。
- 设置错误统一底部，相关字段标红，不在顶部/每行重复；保留校验、首个错误定位与草稿。
- Sparkle 2.10.0 双架构 feed：同版本 ARM 受限项在前、Intel 无硬件限制回退项在后；生成脚本强制双包、架构和版本匹配，防止再次遗漏 Intel。

## 回归与发布证据

先读 BASELINE.md、ROADMAP.md、documentation/VALIDATION.md、documentation/CODE-REVIEW-2026-10-14.md 和 documentation/RELEASE-v1.0.4.md。七组安装资源隔离真实 WebView、全部 Lua、相关 JS/隐私/Dock 回归及双包签名/篡改拒绝通过。公开六附件、官网与 feed 已回核；本机真实版本/权限已确认，手动检查更新返回当前已是 1.0.4 最新版。未发现范围内新的可确认 P0/P1/P2。

本地证据在 build/installed-regression45/ 与 build/refresh-1.0.2-verification/（后者累计包含 Build 43–45 的验证记录）；发行 App/dSYM 在 build/release-1.0.4-{arm64,x86_64}/；包在 build/packages/。证据和产物不提交。

## 后续边界

等待用户反馈或新需求，每次只做一个优化项。Intel 既有 Build 42 用户实测记录保留，本轮没有 Intel Build 45 实际升级验收。其他 macOS、完整更新故障注入、特殊第三方许可人工复核仍按原记录区分。

仍为 ad-hoc 签名，没有 Developer ID/公证；重新授权可能需要移除旧权限条目再添加当前 App。私有更新密钥保留 Keychain，不导出。Xcode 27 第三方 Runtime 的 poison-system-directories 仍用临时 xcconfig 保留为警告，尚未独立修正。

website/ 是独立未跟踪仓库，始终排除。个人 Hammerspoon、默认浏览器、系统权限与个人数据不得随意修改。本轮未读取个人剪贴板内容或清理数据目录。非持久化历史按原设计随退出清空，不声称逐条核验历史内容。

截图工具已取消；日志导出、Homebrew 和 V2EX 发布只是讨论，不能当作实施授权。不重复清理旧候选或注册残留。当前文档提交不构成后续功能开发、删除或发布的长期授权。
