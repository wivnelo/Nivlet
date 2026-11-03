# Nivlet for Mac 分发与验收

当前发行：**2.0.2 / Build 62**，macOS 13+、仅 Apple Silicon（arm64）。[版本说明](RELEASE-v2.0.2.md)记录源码、范围、校验值和验证边界。历史 GitHub 版本及附件保留，1.0.8 / Build 55 是最后 Intel 版。

## 官方流程

1. 在隔离目录固定源码、Runtime 与 Sparkle 2.10.0，递增 Build；不覆盖旧附件或未提交工作区。Git author/committer 使用指定 noreply 身份。
2. 完成相关回归、独立审阅、原生构建和产物隐私检查。所有内嵌 Mach-O 必须仅 arm64，Toolkit 资源与源码逐文件相同。
3. 签名前只裁剪不参与运行的框架开发文件，保留运行资源、许可证、更新器及匹配 dSYM；dSYM 不进入安装包。
4. 使用既有 Developer ID、Team、Bundle ID 和 entitlement 签名嵌套代码；不增加权限。App ZIP 公证 Accepted 后 staple，最终 DMG 同样签名、公证、staple，二者均通过严格签名与 Gatekeeper。
5. 隔离生成 appcast，使用 Keychain 中已有 Sparkle Ed25519 密钥签名；验证版本、Build、实际架构、公钥、SHA-256 和篡改拒绝。新项必须包含 `hardwareRequirements=arm64`。
6. 用户授权发布后上传版本 tag 和 ZIP/DMG/SHA-256；重新下载附件核对，再将已验证 feed 与官网状态发布到 `main` 的 `docs/`，回查 GitHub Pages 和 CI。
7. 不上传个人配置、私钥、公证凭据、内部日志或私人截图。不将静态前端测试写成原生或跨设备验证，不将停止 Intel 构建写成 ARM 包体减半。

## 2.0.2 / Build 62 命令

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_ARCH=arm64 NIVLET_BUILD_NUMBER=62 NIVLET_DERIVED_DATA_PATH="$PWD/build/release-2.0.2-build62/arm64/DerivedData" sh scripts/build-release.sh
NIVLET_SIGN_IDENTITY=签名身份 NIVLET_TEAM_ID=团队标识 NIVLET_NOTARY_PROFILE=钥匙串配置 NIVLET_BUILD_NUMBER=62 NIVLET_RELEASE_DIR=build/release-2.0.2-build62 python3 scripts/sign-notarize.py arm64
python3 scripts/generate-update-feed.py build/release-2.0.2-build62/dist/Nivlet-2.0.2-build62-arm64.zip --output build/release-2.0.2-build62/appcast-candidate.xml
python3 tests/updates.py --build 62 --dist build/release-2.0.2-build62/dist --appcast build/release-2.0.2-build62/appcast-candidate.xml
```

构建前确认 `vendor/hammerspoon` 与按 `scripts/fetch-runtime.sh` 重建的结果一致；不一致时在中性临时目录重建运行时后构建，不覆盖现有 vendor。构建目录可自定义，已有输出拒绝覆盖。已验收的 Build 62 包不得只因文档更新而重签名或换包；发行源码的产品文件必须保持与该包一致。应用内更新仍为手动检查、用户确认安装；完整新版本 Sparkle 安装需单独证据。

## 历史发行说明

1.0.8 / Build 55 于 2026-10-29 发布双架构 ZIP、DMG 与 SHA-256；v1.0.8 tag 保留原位置。1.0.7 / Build 53 复用已验收 Build 49 的原生程序与匹配 dSYM，只更新 Toolkit 和版本元数据后重签名；2.0.0 必须使用新版本元数据重新编译、签名和公证，不改名复用旧候选。

## 1.0.6 构建兼容说明

本次 Xcode 27 中性目录构建遇到第三方 Runtime 的 `poison-system-directories` 诊断升级为错误。临时 xcconfig 仅添加 `OTHER_CFLAGS = $(inherited) -Wno-error=poison-system-directories` 与 `OTHER_CPLUSPLUSFLAGS = $(inherited) -Wno-error=poison-system-directories`，通过 `XCODE_XCCONFIG_FILE` 传入；该诊断仍保留为警告，其余错误检查不变。双架构从源码完整构建，架构裁剪、dSYM、严格签名和隐私门禁全部通过。原生依赖构建兼容性仍需后续独立修正，不应把这里的临时参数泛化成关闭其他警告。


## 历史双架构更新源（1.0.2–1.0.8）

历史生成器同时接收同版本、Build、公钥的 arm64 与 x86_64 ZIP。Sparkle 2.10.0 同版本选择首个兼容项，ARM 项在前且带 `hardwareRequirements=arm64`，Intel 回退项在后。此段仅解释历史 feed；2.0.0 起不再使用双包生成流程，也不能去掉新 ARM 项的硬件限制。
