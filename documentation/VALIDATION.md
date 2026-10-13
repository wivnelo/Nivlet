# 1.0.0 / Build 32 验收

本次仅重置推广版本与公开仓库，既有功能保持不变。

用户于 2026-10-12 确认当前 1.0.0 / Build 32 已完成整体人工检查，作为后续开发基准；此前多显示器验收记录保留。本次完成 32 项源码/独立回归、最终资源 132 项原生 WebView 回归（中英、深浅色与三种窗口尺寸），全部通过。干净 Release 构建、严格 ad-hoc 签名、包体隐私检查、ZIP 逐文件/CRC/SHA-256、DMG 完整性与只读挂载、Ed25519 签名和篡改拒绝检查通过。线上发布验收时：新仓库仅一条初始提交、一个 v1.0.0 标签及一个正式 Release；三个附件下载回核与本地完全一致。GitHub Pages 部署成功，官网、画廊及 appcast 与本地逐文件一致。旧 SHA 抽查被拒绝，不据此承诺 GitHub 全部缓存或外部副本均已清除。

其他 Mac/macOS、全部第三方输入法及完整跨机器 Gatekeeper 流程尚未全面覆盖。尚无 Apple Developer ID 签名或 Apple 公证。本机 /Applications/Nivlet.app 的 Info.plist 已核对为 1.0.0 / Build 32。

2026-10-12 按用户授权永久清理项目 build/ 中旧版本构建、安装包、测试产物与历史备份，保留 Build 32 正式包、当前构建及验收证据；定向注销 43 条不存在的历史 App/内嵌组件注册，另已注销旧 Build 30、31 构建 App。未修改默认浏览器。

## Intel 本地候选包 · 2026-10-13

1.0.0 / Build 33，x86_64，macOS 13.0+；沿用 Build 32 功能，未安装或公开发布。干净中性目录 Release 交叉构建通过；101 个内嵌 Mach-O 全为 x86_64，最低系统要求不高于 13.0；Release dSYM UUID 与导出符号检查、严格 ad-hoc 签名、仓库/App/ZIP 隐私扫描通过。Toolkit 源文件逐项与源码及 Build 32 arm64 资源一致。ZIP CRC 与 381 个包内文件逐字节核对通过，DMG 完整性、只读挂载、Intel 安装说明及挂载 App 签名通过；Intel 与原有 arm64 包 SHA-256 均核对通过，旧包未覆盖。

构建脚本新增目标架构参数；使用双架构编译样本验证 arm64/x86_64 裁剪与错误切片拒绝，5 项隐私回归、shell 语法及 diff 检查通过。未运行 Intel App，未在 2018 款 MacBook Pro 或其他 Intel 真机验收；本机 Apple Silicon 的构建成功不等于 Intel 运行验收。需在 macOS 13+ 的 Intel 机器检查启动、权限、主要模块及重启保留后，再考虑正式发布。公开 appcast 仍仅 arm64，本次不改变现有更新通道。证据在本地 build/intel-1.0.0-build33/，安装包位于 build/packages/。
