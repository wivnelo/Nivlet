> 当前正式发行：1.0.1 / Build 41；下方 Intel Build 33 为历史构建示例。正式构建请使用新的隔离目录及 NIVLET_BUILD_NUMBER=41。

# 开发与构建

## 当前工程基准（2026-10-12）

当前发行版本为 1.0.0 / Build 32（arm64-only），纳入默认浏览器关联修复、权限检测、底部居中圆点及统一折叠箭头。最终构建与回归见 [Build 32 验收](VALIDATION.md)，安装及发布状态以 [BASELINE.md](../BASELINE.md) 为准。

- Runtime 固定来源；构建通过 `scripts/prepare-updater.sh` 准备固定 Sparkle 2.10.0，许可收集包含其原文。
- Release 构建使用完整 Xcode：`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_BUILD_NUMBER=32 sh scripts/build-release.sh`。32 为本次 1.0.0 发行 Build；下一构建继续递增 Build；构建不自动安装。
- 更新入口位于关于页，原生 Sparkle 桥接由 `patches/nivlet-updater.patch` 注入；有草稿先处理，默认手动检查、用户确认安装。
- Feed 为 `docs/appcast.xml`，使用 `scripts/generate-update-feed.py <ZIP>` 生成、`tests/updates.py` 验证。Ed25519 私钥留 Keychain，不导出到源码、日志或安装包。
- 发布顺序：新版本/Build → 构建和回归 → 打包/签名校验 → 上传新附件 → 发布 feed → 实测升级及最新检查 → 保留回滚备份。


## 发布隐私检查（2026-10-12）

Release 入口现在先检查当前仓库和 Git 提交身份，再把固定源码与依赖复制到全新的中性临时目录构建；不复用个人目录下的对象文件。完成扫描和签名后，仅将 App 与匹配 dSYM 复制回 `build/PrivateRelease/Build/Products/Release/`。已有输出目录时停止，可通过 `NIVLET_DERIVED_DATA_PATH` 指定另一空目录，避免覆盖旧产物。Debug 开发构建入口保留。

```sh
python3 tests/privacy.py
python3 scripts/check-privacy.py --repo .
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_BUILD_NUMBER=32 sh scripts/build-release.sh
NIVLET_BUILD_CONFIGURATION=Release sh scripts/package-local.sh
```

32 为本次隐私修正版构建。构建和打包使用相同 `NIVLET_DERIVED_DATA_PATH`；打包可用 `NIVLET_PACKAGE_OUTPUT` 指定独立目录。打包检查仓库、App、ZIP；feed 生成前再次检查仓库与 ZIP，发现个人 home 路径、常见凭据或敏感文件即停止，日志只输出文件和问题类型。仅精确放行 Runtime 两个文档资源内已核对的示例路径，不放行可执行文件里的用户目录。此规则不替代截图人工审查、完整历史审计或未知凭据识别。


## 常用检查

### 当前发行包的体积优化

- Xcode 与 `system-probe` 编译为 arm64；打包前遍历所有 Mach-O，去除 Sparkle 等嵌套组件的 Intel 切片，缺少 arm64 时停止构建。
- 关于页 PNG 生成 160 × 160 资源，对应 80 × 80 Retina 显示；原始品牌图、Dock 与菜单栏图标保持原样。
- 可用 `NIVLET_DERIVED_DATA_PATH` 指定独立的绝对构建目录；构建与打包必须传入相同值。例如 `NIVLET_DERIVED_DATA_PATH="$PWD/build/DerivedData-arm64"`，避免覆盖旧双架构构建产物。

从仓库根目录执行：

```sh
for test_file in tests/*.lua; do lua "$test_file" || exit 1; done
python3 tests/dock_activation.py
node tests/launcher_replace.js
git diff --check
```

构建前需要完整 Xcode、Python 3 和固定 Runtime；首次使用 `sh scripts/fetch-runtime.sh` 准备 Runtime，已有目录不自动覆盖。不要自动升级依赖或替换已安装 App。

## 按架构独立构建（2026-10-13）

`NIVLET_ARCH` 支持 `arm64`（默认）与 `x86_64`。主程序、原生 system-probe 及全部内嵌 Mach-O 必须具有目标架构；优化阶段统一裁剪，缺少切片即停止。Release 仍要求匹配架构的 dSYM，并保留隐私检查与严格签名检查。

Intel 本地候选包沿用 1.0.0 功能，使用 Build 33，要求 macOS 13.0+；与已发布 Build 32 arm64 包分开，不能视为已经在 Intel 真机通过验收。

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_ARCH=x86_64 NIVLET_BUILD_NUMBER=33 NIVLET_DERIVED_DATA_PATH="$PWD/build/intel-1.0.0-build33/DerivedData" sh scripts/build-release.sh
NIVLET_BUILD_CONFIGURATION=Release NIVLET_DERIVED_DATA_PATH="$PWD/build/intel-1.0.0-build33/DerivedData" sh scripts/package-local.sh
```

当前公开 appcast 仍仅面向 arm64。本次本地 Intel 打包不修改 feed；未来发布 Intel 更新前需单独完善双架构更新条目和选择验证，不能用现有 arm64-only feed 生成脚本直接发布 Intel 包。
