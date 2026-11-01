# Nivlet for Mac 分发准备与验收

## 当前候选（2026-11-01）

**1.0.9 / Build 56，仅 Apple Silicon（arm64），macOS 13+。** 本文为待发布流程；最终构建、回归、公证和实机验收全部通过后才可发布。实际状态见 [BASELINE](../BASELINE.md)、[候选说明](RELEASE-v1.0.9.md) 与 [验收](VALIDATION.md)。旧候选包的通过结果不能用于变更后的新包。

最新已发布版本为 [1.0.8 / Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8)，这是最后一个 Intel（x86_64）版本。历史 Intel 资产继续保留；从 1.0.9 起不再构建、发布或支持 Intel，不宣称经过 Intel 真机验证。新版本使用独立 tag、Build 和附件，不覆盖 v1.0.8 的 tag 或 Build 54/55 资产。

- 固定 Runtime 与 Sparkle 2.10.0，不在发行时升级依赖；许可收集保留原文。
- 在新的隔离目录构建：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_ARCH=arm64 NIVLET_BUILD_NUMBER=56 NIVLET_DERIVED_DATA_PATH="$PWD/build/release-1.0.9-build56/arm64/DerivedData" sh scripts/build-release.sh`。已有输出拒绝覆盖；构建不自动安装。
- 新 feed 只接受一个 arm64 ZIP；先隔离生成：`python3 scripts/generate-update-feed.py <arm64 ZIP> --output build/release-1.0.9-build56/appcast-candidate.xml`，未完成发布门槛前不覆盖 `docs/appcast.xml`。发行说明来自 `release-notes/1.0.9-build56.md`；草稿标记必须在真实门槛通过后删除。
- Feed 的每个新发行项必须保留 `sparkle:hardwareRequirements=arm64`，不把 arm64 包作为无架构限制的通用回退。Intel 用户继续使用最后的 1.0.8 Build 55。
- Ed25519 私钥、公证配置和证书私钥留 Keychain，不导出到源码、日志、安装包或知识库。

## 正式发布门槛

1. 核对最终源码提交、版本 1.0.9、Build 56 与新 tag；Git author/committer 均使用指定 noreply 身份。
2. 完成独立性能和稳定性审阅、相关回归和 arm64 原生构建。全部内嵌 Mach-O 必须仅含 arm64；App 中 Toolkit 逐文件与源码一致。
3. 只在发行副本、签名前精简明确的框架 Headers、PrivateHeaders、Modules 与对应顶层符号链接。保留框架二进制、Resources、版本链接、XPC 服务、更新器、许可证和其他运行资源。dSYM 留在构建产物中，与主程序 UUID 匹配，不放入安装包。
4. Developer ID 签名全部嵌套代码，沿用既有 Team、Bundle ID 与 `Native/Nivlet.entitlements`；不新增权限。
5. 提交 App ZIP 公证，收到 Accepted 后 staple；生成最终 ZIP/DMG，DMG 同样签名、公证与 staple。严格 codesign、stapler、Gatekeeper 校验均需通过。
6. 验证包内容、许可证、个人数据隔离和本机非破坏性验收；对未验证的系统、硬件或路径如实记录。只要必须完成的门槛仍阻塞，就保持待发布。
7. 上传新 Release 附件后，回读 tag/commit、下载并核对最终 SHA-256，再发布引用这些真实资产的 feed。完成签名与更新源校验，保留回退产物，不删历史 Intel 资产。

体积报告必须比较实际同架构 ZIP 字节数与 App 普通文件总字节数，另列磁盘占用；停止提供 Intel 包不会自动缩小本来已单架构的 ARM 包。只报告实际测得收益，不用预估代替结果。

## 正式签名与公证

版本读取仓库 `VERSION`，示例：

```sh
NIVLET_SIGN_IDENTITY=签名身份 NIVLET_TEAM_ID=团队标识 NIVLET_NOTARY_PROFILE=钥匙串配置 NIVLET_BUILD_NUMBER=56 NIVLET_RELEASE_DIR=build/release-1.0.9-build56 python3 scripts/sign-notarize.py arm64
```

默认只处理 arm64；`--dry-run` 可预览，已有输出拒绝覆盖。沿用本机已有 `Nivlet-notary` 公证配置。主 App entitlement 仅为既有 `com.apple.security.automation.apple-events`；公证不代替辅助功能授权，也不等于 App Store 分发。

应用内更新仍从关于页手动检查、用户确认安装；有草稿先处理。签名后的 ZIP 使用既有 Sparkle Keychain 密钥签名，feed 生成器验证实际架构、版本、Build、公钥和包内容，再生成架构受限的项。发布前运行 `python3 tests/updates.py --build 56 --dist build/release-1.0.9-build56/dist --appcast build/release-1.0.9-build56/appcast-candidate.xml` 及相应负向检查，确保 Intel 不会获得新的 arm64 包。

## 历史发行说明

1.0.8 / Build 55 于 2026-10-29 发布双架构 ZIP、DMG 与 SHA-256；v1.0.8 tag 保留原位置。1.0.7 / Build 53 复用已验收 Build 49 的原生程序与匹配 dSYM，只更新 Toolkit 和版本元数据后重签名；该历史做法不适用于本次原生修复，1.0.9 必须重新编译。

## 1.0.6 构建兼容说明

本次 Xcode 27 中性目录构建遇到第三方 Runtime 的 `poison-system-directories` 诊断升级为错误。临时 xcconfig 仅添加 `OTHER_CFLAGS = $(inherited) -Wno-error=poison-system-directories` 与 `OTHER_CPLUSPLUSFLAGS = $(inherited) -Wno-error=poison-system-directories`，通过 `XCODE_XCCONFIG_FILE` 传入；该诊断仍保留为警告，其余错误检查不变。双架构从源码完整构建，架构裁剪、dSYM、严格签名和隐私门禁全部通过。原生依赖构建兼容性仍需后续独立修正，不应把这里的临时参数泛化成关闭其他警告。


## 历史双架构更新源（1.0.2–1.0.8）

历史生成器同时接收同版本、Build、公钥的 arm64 与 x86_64 ZIP。Sparkle 2.10.0 同版本选择首个兼容项，ARM 项在前且带 `hardwareRequirements=arm64`，Intel 回退项在后。此段仅解释历史 feed；1.0.9 起不再使用双包生成流程，也不能去掉新 ARM 项的硬件限制。
