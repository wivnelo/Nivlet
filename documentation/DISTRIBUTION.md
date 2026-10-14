# Nivlet for Mac 分发准备与验收

## 当前工程基准（2026-10-14）

当前发行版本为 1.0.5 / Build 47（arm64 / x86_64），包含底部统一错误、名称后未安装标签、应用状态与浏览器列表刷新及卸载后的浏览器改选。最终构建与回归见 [Build 47 验收](VALIDATION.md)，安装及发布状态以 [BASELINE.md](../BASELINE.md) 为准。旧构建记录仅作历史证据。

- Runtime 固定来源；构建通过 `scripts/prepare-updater.sh` 准备固定 Sparkle 2.10.0，许可收集包含其原文。
- Release 构建使用完整 Xcode：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_BUILD_NUMBER=47 sh scripts/build-release.sh`。47 为本次 1.0.5 发行 Build；下一构建继续递增 Build；构建不自动安装。
- 更新入口位于关于页，原生 Sparkle 桥接由 `patches/nivlet-updater.patch` 注入；有草稿先处理，默认手动检查、用户确认安装。
- Feed 为 `docs/appcast.xml`，使用 `python3 scripts/generate-update-feed.py <arm64 ZIP> <x86_64 ZIP>` 生成、`tests/updates.py` 验证。Ed25519 私钥留 Keychain，不导出到源码、日志或安装包。
- 发布顺序：新版本/Build → 构建和回归 → 打包/签名校验 → 上传新附件 → 发布 feed → 实测升级及最新检查 → 保留回滚备份。


## 发布检查清单

- 核对版本、Build、源码提交和新 tag；构建不会自动安装。
- 验证严格签名、架构、ZIP/DMG/SHA-256、依赖许可及个人数据隔离。
- 在最终安装版检查升级、回滚、配置和历史保留；结果见 [当前验收](VALIDATION.md)。
- 上传附件后再更新 feed，核验公开下载与最新检查；保留可恢复旧包。
- 当前 ad-hoc 与 Ed25519 包签名不等于 Developer ID/Apple 公证；跨机器验证边界必须对外明确。提供 Apple Silicon（arm64）和 Intel（x86_64）独立包；更新 feed 同时提供双架构项；发布前核验 feed 的架构兼容性筛选，避免向 Intel Mac 提供 arm64-only 更新。

用户安装与恢复操作见 [安装指南](INSTALLATION.md)，许可核查见 [第三方许可核查](THIRD-PARTY-AUDIT.md)。

## 1.0.5 构建兼容说明

本次 Xcode 27 中性目录构建遇到第三方 Runtime 的 `poison-system-directories` 诊断升级为错误。临时 xcconfig 仅添加 `OTHER_CFLAGS = $(inherited) -Wno-error=poison-system-directories` 与 `OTHER_CPLUSPLUSFLAGS = $(inherited) -Wno-error=poison-system-directories`，通过 `XCODE_XCCONFIG_FILE` 传入；该诊断仍保留为警告，其余错误检查不变。双架构从源码完整构建，架构裁剪、dSYM、严格签名和隐私门禁全部通过。原生依赖构建兼容性仍需后续独立修正，不应把这里的临时参数泛化成关闭其他警告。


## 双架构更新源（1.0.2 起）

生成器必须同时接收 arm64、x86_64 的正式 ZIP，检查实际主程序架构及相同版本、Build、更新公钥，分别签名。缺少一个包或顺序/架构不符时拒绝生成，不覆盖已有 feed。

Sparkle 2.10.0 仅支持 arm64 硬件限制，没有 x86_64 对称限制；同版本按首个兼容项选择。feed 固定 ARM 项在前（hardwareRequirements=arm64），Intel 回退项在后（不加未知硬件字段）。禁止调换顺序或只删除 ARM 限制。每次发布运行 tests/updates.py，验证双项、同版本、架构分流、签名与篡改拒绝，再回核公开 appcast。后续 Sparkle 升级需复核此选择规则。
