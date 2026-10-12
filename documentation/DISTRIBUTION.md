# Nivlet for Mac 分发准备与验收

## 当前工程基准（2026-10-12）

当前发行版本为 1.0.0 / Build 32（arm64-only），纳入默认浏览器关联修复、权限检测、底部居中圆点及统一折叠箭头。最终构建与回归见 [Build 32 验收](VALIDATION.md)，安装及发布状态以 [BASELINE.md](../BASELINE.md) 为准。旧构建记录仅作历史证据。

- Runtime 固定来源；构建通过 `scripts/prepare-updater.sh` 准备固定 Sparkle 2.10.0，许可收集包含其原文。
- Release 构建使用完整 Xcode：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_BUILD_NUMBER=32 sh scripts/build-release.sh`。32 为本次 1.0.0 发行 Build；下一构建继续递增 Build；构建不自动安装。
- 更新入口位于关于页，原生 Sparkle 桥接由 `patches/nivlet-updater.patch` 注入；有草稿先处理，默认手动检查、用户确认安装。
- Feed 为 `docs/appcast.xml`，使用 `scripts/generate-update-feed.py <ZIP>` 生成、`tests/updates.py` 验证。Ed25519 私钥留 Keychain，不导出到源码、日志或安装包。
- 发布顺序：新版本/Build → 构建和回归 → 打包/签名校验 → 上传新附件 → 发布 feed → 实测升级及最新检查 → 保留回滚备份。


## 发布检查清单

- 核对版本、Build、源码提交和新 tag；构建不会自动安装。
- 验证严格签名、架构、ZIP/DMG/SHA-256、依赖许可及个人数据隔离。
- 在最终安装版检查升级、回滚、配置和历史保留；结果见 [当前验收](VALIDATION.md)。
- 上传附件后再更新 feed，核验公开下载与最新检查；保留可恢复旧包。
- 当前 ad-hoc 与 Ed25519 包签名不等于 Developer ID/Apple 公证；跨机器验证边界必须对外明确。当前仅支持 Apple Silicon（arm64），不支持 Intel（x86_64/x86）；发布前核验 feed 的架构兼容性筛选，避免向 Intel Mac 提供 arm64-only 更新。

用户安装与恢复操作见 [安装指南](INSTALLATION.md)，许可核查见 [第三方许可核查](THIRD-PARTY-AUDIT.md)。
