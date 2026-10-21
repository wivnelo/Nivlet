# Nivlet for Mac 分发准备与验收

## 当前工程基准（2026-10-21）

当前发行版本为 1.0.7 / Build 53（arm64 / x86_64），包含底部统一错误、名称后未安装标签、应用状态与浏览器列表刷新及卸载后的浏览器改选。最终构建与回归见 [Build 53 验收](VALIDATION.md)，安装及发布状态以 [BASELINE.md](../BASELINE.md) 为准。旧构建记录仅作历史证据。

- Runtime 固定来源；构建通过 `scripts/prepare-updater.sh` 准备固定 Sparkle 2.10.0，许可收集包含其原文。
- Release 构建使用完整 Xcode：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_BUILD_NUMBER=53 sh scripts/build-release.sh`。53 为本次 1.0.7 发行 Build；下一构建继续递增 Build；构建不自动安装。
- 更新入口位于关于页，原生 Sparkle 桥接由 `patches/nivlet-updater.patch` 注入；有草稿先处理，默认手动检查、用户确认安装。
- Feed 为 `docs/appcast.xml`，使用 `python3 scripts/generate-update-feed.py <arm64 ZIP> <x86_64 ZIP>` 生成、`tests/updates.py` 验证。Ed25519 私钥留 Keychain，不导出到源码、日志或安装包。
- 发布顺序：新版本/Build → 构建和回归 → 打包/签名校验 → 上传新附件 → 发布 feed → 实测升级及最新检查 → 保留回滚备份。


## 发布检查清单

- 核对版本、Build、源码提交和新 tag；构建不会自动安装。
- 验证严格签名、架构、ZIP/DMG/SHA-256、依赖许可及个人数据隔离。
- 在最终安装版检查升级、回滚、配置和历史保留；结果见 [当前验收](VALIDATION.md)。
- 上传附件后再更新 feed，核验公开下载与最新检查；保留可恢复旧包。
- 当前 App/DMG 已正式 Developer ID 签名、公证并附加票据；Sparkle Ed25519 另行保护更新包完整性。跨机器验证边界记录于 VALIDATION。提供 Apple Silicon（arm64）和 Intel（x86_64）独立包；更新 feed 同时提供双架构项；发布前核验 feed 的架构兼容性筛选，避免向 Intel Mac 提供 arm64-only 更新。

用户安装与恢复操作见 [安装指南](INSTALLATION.md)，许可核查见 [第三方许可核查](THIRD-PARTY-AUDIT.md)。

## 正式签名与公证流程（1.0.7 起）

1. 版本号与 Build 递增；相同 Bundle ID、Developer ID Team 与兼容 designated requirement 保持稳定。
2. 原生依赖及主 App 使用 Developer ID 签名、Hardened Runtime 和安全时间戳；只保留必要 entitlements。检查所有嵌套签名。
3. 用本机 Keychain 中的 `Nivlet-notary` 配置提交 App ZIP，等待 Accepted，附加 App 票据并验证 Gatekeeper。
4. 将附加票据后的 App 放入正式 ZIP/DMG；DMG 单独签名、公证、附加票据。之后才计算最终 SHA-256，签名 Sparkle ZIP 并生成 feed。
5. 校验 ZIP 内容、DMG 挂载与严格签名、公证票据、源码资源一致性和下载回核。先上传 Release 附件，再部署引用它们的 feed。
6. 公证凭据、证书私钥与更新私钥只保留在 Keychain；不复制到仓库、安装包、日志或知识库。公证不替代辅助功能授权。

1.0.7 / Build 53 复用已验收 Build 49 的原生程序与匹配 dSYM，只更新 Toolkit 及版本元数据后重签名；原生源码未重新编译。原生构建时的 Xcode 兼容参数与历史记录见 VALIDATION，后续原生修改仍需完整干净构建。

## 1.0.6 构建兼容说明

本次 Xcode 27 中性目录构建遇到第三方 Runtime 的 `poison-system-directories` 诊断升级为错误。临时 xcconfig 仅添加 `OTHER_CFLAGS = $(inherited) -Wno-error=poison-system-directories` 与 `OTHER_CPLUSPLUSFLAGS = $(inherited) -Wno-error=poison-system-directories`，通过 `XCODE_XCCONFIG_FILE` 传入；该诊断仍保留为警告，其余错误检查不变。双架构从源码完整构建，架构裁剪、dSYM、严格签名和隐私门禁全部通过。原生依赖构建兼容性仍需后续独立修正，不应把这里的临时参数泛化成关闭其他警告。


## 双架构更新源（1.0.2 起）

生成器必须同时接收 arm64、x86_64 的正式 ZIP，检查实际主程序架构及相同版本、Build、更新公钥，分别签名。缺少一个包或顺序/架构不符时拒绝生成，不覆盖已有 feed。

Sparkle 2.10.0 仅支持 arm64 硬件限制，没有 x86_64 对称限制；同版本按首个兼容项选择。feed 固定 ARM 项在前（hardwareRequirements=arm64），Intel 回退项在后（不加未知硬件字段）。禁止调换顺序或只删除 ARM 限制。每次发布运行 tests/updates.py，验证双项、同版本、架构分流、签名与篡改拒绝，再回核公开 appcast。后续 Sparkle 升级需复核此选择规则。
