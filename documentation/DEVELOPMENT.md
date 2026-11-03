# 开发与构建

当前正式基准为 **2.0.2 / Build 62**，macOS 13+，仅 Apple Silicon（arm64）。发行门槛见 [分发流程](DISTRIBUTION.md)。[1.0.8 / Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8) 是最后一个 Intel 版本；历史资产保留，后续停止 Intel 构建、发行与支持。

1.0.9 / Build 56 是未发布的历史候选；其构建、签名、公证和本机测试记录仅对应当时的产物。2.0.1 / Build 61 已完成独立的最终包验收；后续构建仍须重新验证，不能沿用旧包结论。

## 隔离 Release 构建

使用完整 Xcode、Python 3、固定 Runtime 与 Sparkle 2.10.0。首次使用 `sh scripts/fetch-runtime.sh` 准备 Runtime，已有目录不自动覆盖。不要为发行自动升级依赖。

Release 入口先检查当前仓库与 Git author/committer，再把源码和依赖复制到新的中性临时目录构建，避免复用个人目录的对象文件。仅将 App 和匹配 dSYM 复制回指定输出目录；已有输出拒绝覆盖。

```sh
python3 tests/privacy.py
python3 scripts/check-privacy.py --repo .
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_ARCH=arm64 NIVLET_BUILD_NUMBER=62 NIVLET_DERIVED_DATA_PATH="$PWD/build/release-2.0.2-build62/arm64/DerivedData" sh scripts/build-release.sh
```

构建不会自动安装。正式签名、公证、ZIP/DMG 和更新源使用 [DISTRIBUTION](DISTRIBUTION.md) 的后续流程；`scripts/package-local.sh` 只生成本地验证包，不表示公证发行。

## 架构与体积

- 本次及后续正式包只构建 arm64。主程序、system-probe 和全部内嵌 Mach-O 必须具有且仅保留 arm64 切片；缺少切片时停止。
- Release 主程序去除调试符号前，必须验证外部 dSYM 的 UUID 匹配；保留导出符号。dSYM 不进入 ZIP/DMG。
- 发行副本在签名前裁剪明确的框架开发 Headers、PrivateHeaders、Modules 及对应顶层符号链接，保留运行库、Resources、版本链接、XPC、更新器和许可证。源码依赖保持完整。
- 关于页 PNG 使用 160 × 160 资源；品牌图、Dock 和菜单栏资源保持原样。不为缩小体积删除 Nivlet 的功能。
- `scripts/trim-runtime.py` 在签名前移除 Nivlet 无法访问的 Hammerspoon 扩展（相机、定位、语音、HID/USB/MIDI、IPC 与 `hs` 命令行、HTTP 服务器、文档浏览器等），并把 API 文档 `docs.json`/`lua.json` 清空为 `[]`（核心启动时会把 `docs.json` 路径传给 Lua，文件必须存在），共约 16.3 MB。动态加载的 network、window 子模块及其依赖（spaces、spaces.watcher、plist、redshift）保留。只删除脚本中明确列出的路径，任一路径缺失或剩余 Mach-O 链接被删 dylib 即停止；未列出的模块一律保留。`tests/runtime_trim.py` 确保 Toolkit 不引用被删模块。新增 Toolkit 功能需用到被删模块时，先从列表移除再使用。
- 最终体积以同架构 ZIP 与 App 实测比较为准；停止打 Intel 包与单个 ARM 包的压缩收益分别说明。

## 回归与隐私检查

```sh
sh scripts/check-runtime.sh
sh scripts/run-tests.sh
git diff --check
```

`run-tests.sh` 运行全部 Lua、Python（`updates.py` 需发行产物，单独运行）、非 UI 的 JS 测试和隐私扫描。`check-runtime.sh` 按 `patches/series` 在临时工作树重建运行时并与 `vendor/hammerspoon` 比对；不一致时 `build-dev.sh` 停止，需移走旧目录后重新运行 `scripts/fetch-runtime.sh`。补丁顺序只在 `patches/series` 维护。GitHub Actions（`.github/workflows/tests.yml`）在每次推送和 PR 时重建运行时并运行上述测试及四语言 × 深浅色设置页 UI 回归。

原生文件路径探针只处理隔离测试文件，不打开用户文件或修改默认应用。UI 回归应使用合成配置，实机测试不得覆盖用户草稿。完整验收状态按最终候选记录，不能把旧包或其他架构的结果用于本次。

构建、打包与 feed 生成均检查个人 home 路径、常见凭据和敏感文件，失败只输出文件与问题类型。仅精确放行已核对的 Runtime 文档示例路径；这不替代截图检查、完整历史审计或未知凭据识别。公证和更新私钥留 Keychain。

## 历史 Intel 构建示例（不用于后续发行）

以下记录保留历史构建命令，不表示 2.0.0 继续支持 Intel。

Intel 本地候选包沿用 1.0.0 功能，使用 Build 33，要求 macOS 13.0+；与已发布 Build 32 arm64 包分开，不能视为已经在 Intel 真机通过验收。

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer NIVLET_ARCH=x86_64 NIVLET_BUILD_NUMBER=33 NIVLET_DERIVED_DATA_PATH="$PWD/build/intel-1.0.0-build33/DerivedData" sh scripts/build-release.sh
NIVLET_BUILD_CONFIGURATION=Release NIVLET_DERIVED_DATA_PATH="$PWD/build/intel-1.0.0-build33/DerivedData" sh scripts/package-local.sh
```


以上为 1.0.0 / Build 33 历史证据。1.0.8 / Build 55 是最后 Intel 发行；后续新 feed 仅含受 arm64 硬件限制的项。
