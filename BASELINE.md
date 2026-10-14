# Nivlet 当前基准

更新日期：2026-10-14。

当前候选（发布准备中）：**1.0.6 / Build 49**，macOS 13+，arm64 / x86_64。本机为 1.0.5 / Build 48 重复应用提示修复测试版。正式发布与验证见 documentation/VALIDATION.md。

设置错误统一在底部显示，冲突字段标红；应用未安装状态紧跟名称并使用红色；新增应用状态与浏览器列表刷新、卸载后浏览器改选和未安装应用标记；保留 Safari / Chrome 清除浏览数据入口（只打开原生确认界面）、菜单状态修复及再次唤起保留当前页；现有窗口、剪贴板、输入法、应用启动、浏览器分流、系统信息、配置导入导出和手动确认更新保留。

没有 Apple Developer ID 签名或公证。1.0.0 / Build 32 是此前人工确认基准；1.0.6 的代码审计、局部本机检查与跨机器验收边界分别记录，不混同。

权限重授后部分机器需重启的现象仅列 P2 待查，见 [已知问题](documentation/KNOWN-ISSUES.md)，本轮未修改权限检测。

续开发先读本页、[ROADMAP](ROADMAP.md)、[VALIDATION](documentation/VALIDATION.md) 和[代码审计](documentation/CODE-REVIEW-2026-10-14.md)，检查 Git 状态。保护未提交成果，不访问个人剪贴板，不修改个人 Hammerspoon、系统权限或默认浏览器。website/ 为独立仓库，不纳入发布。
