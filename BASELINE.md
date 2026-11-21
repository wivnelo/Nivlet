# Nivlet 当前基准

更新日期：2026-11-21。

当前正式版本为 [2.1.2 / Build 69](https://github.com/wivnelo/Nivlet/releases/tag/v2.1.2)，macOS 13+、Apple Silicon（arm64）。产品源码 `4adffefc5618848a1730c28960066765e53bd663`；发行 tag 在该提交上增加公开说明，不把文档变动计为产品差异。

2.1.2 修复截图文字识别：常驻截图助手长时间运行（报告中约 9 小时）后，Vision 识别每次立即失败，截图“识别文字”、截图翻译与双击 Ctrl 识别都提示“识别失败”，重启后恢复；同一截图在新进程中可正常识别。现在常驻进程识别失败时，改用一次性子进程（`capture-helper --recognize`，PNG 经标准输入、JSON 经标准输出，不落盘）重试，Vision 错误经 `recognitionError` 事件写入 Nivlet 日志、不弹窗。失效的确切原因未查明。产品改动仅 `Native/capture/Recognition.swift`、`main.swift` 与 `Toolkit/modules/capture.lua`；设置项、配置格式与权限不变。ZIP 8.20 MB、DMG 9.37 MB。

65 项命令行回归本地与 CI 通过，新增 `tests/capture_recognition.py`（编译截图助手，验证子进程识别中英文与拒绝非图片输入）与 `tests/capture.lua` 的错误日志用例；设置页未改动，未重跑 UI 套件。候选包 Toolkit 与源码一致、67 个 Mach-O 均为 arm64、无个人路径、`docs.json` 为 `[]`，构建出的截图助手子进程识别正常。用户在本机签名测试版上确认截图识别与双击 Ctrl 识别正常；本地检查版启动后 291 ms 创建菜单栏项。长时间运行后的失效状态无法按需复现，重试路径只单独验证、未在真实故障中触发。App/DMG 均已签名、公证、附加票据并通过 Gatekeeper；appcast 候选的版本、SHA-256、EdDSA 签名与篡改拒绝通过。

上一版 [2.1.1 / Build 68](https://github.com/wivnelo/Nivlet/releases/tag/v2.1.1) 为翻译提速与卡片重排，记录见 [2.1.1 版本说明](documentation/RELEASE-v2.1.1.md)。

更早的 [2.1.0 / Build 67](https://github.com/wivnelo/Nivlet/releases/tag/v2.1.0) 新增截图（标注、识别、贴图）与系统翻译，并大幅降低启动内存、加快菜单与设置窗口，记录见 [2.1.0 版本说明](documentation/RELEASE-v2.1.0.md)。

更早的 [2.0.6 / Build 66](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.6) 为 DMG 安装窗口更新，记录见 [2.0.6 版本说明](documentation/RELEASE-v2.0.6.md)。

更早的 [2.0.5 / Build 65](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.5) 更换应用与菜单栏图标并重做官网和 README，记录见 [2.0.5 版本说明](documentation/RELEASE-v2.0.5.md)。

更早的 [2.0.4 / Build 64](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.4) 修复浏览器分流丢链接，记录见 [2.0.4 版本说明](documentation/RELEASE-v2.0.4.md)。

更早的 [2.0.3 / Build 63](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.3) 为运行时瘦身（安装后 40.5 → 24.8 MB），并统一快捷键校验、合并运行时补丁、加入 CI，记录见 [2.0.3 版本说明](documentation/RELEASE-v2.0.3.md)。更早的 [2.0.2 / Build 62](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.2) 为后台性能优化，记录见 [2.0.2 版本说明](documentation/RELEASE-v2.0.2.md)。

官网来源为 `docs/`，中英文媒体使用真实前端与合成数据，不代表原生录像。知识库由独立同步流程维护，不包含私人配置、凭据或安装包。历史 GitHub 发行保留；1.0.8 / Build 55 为最后 Intel 版。

## 历史：2.0.0



当时状态：**[2.0.0 / Build 57 已正式发布](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.0)**，macOS 13+，仅 Apple Silicon（arm64）。最终产品源码为 `9c96dc0`，输出 `build/release-2.0.0-build57-r2/`。构建、Developer ID 签名、App/DMG Apple 公证、票据/Gatekeeper、最终资源/压缩包核对及本地更新签名、篡改拒绝和 Intel 不匹配检查通过。正式 tag 指向 `9937af75694e2784815f23ce5c01e34690f15984`，产品源码保持 `9c96dc0`。三份公开附件下载与最终本地产物一致，下载 App 的严格签名和 Gatekeeper 通过；线上 arm64 appcast、Pages 与新版媒体均已核验通过；知识库维护另行同步并记录。详见 [2.0.0 说明](documentation/RELEASE-v2.0.0.md) 及 [VALIDATION](documentation/VALIDATION.md)。

历史正式发行 **[v1.0.8 / Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8)**，Build 55 资产于 2026-10-29 发布。该 Release 保留 Build 54 与 Build 55 的双架构 ZIP、DMG 和 SHA-256；v1.0.8 tag 解引用至 `0772475f731ca887b23ca6ae49878d4e520c70c1`，未因新增 Build 55 资产而移动。本次 v2.0.0 使用独立 tag 与新资产；已核验旧版全部附件保持不变。

**1.0.8 / Build 55 为最后 Intel（x86_64）版本。** 由于缺少 Intel 真机验收条件，从 2.0.0 起不再构建、发布或支持 Intel；历史 Intel 发行资产保留。新更新源只提供有 `hardwareRequirements=arm64` 限制的 Apple Silicon 项，不能向 Intel 发送 arm64 包。

2.0.0 改动范围：八个设置页采用左侧导航与右侧内容；本地 `.html`/`.htm` 交给已配置的实际浏览器；“保存全部设置”处理所有 dirty 页面并保留未成功保存的草稿；修复审阅确认的稳定性缺陷。新增繁体中文（台湾用语）与日语，香港环境使用繁中回退，不宣称母语人工审校。剪贴板菜单快捷键采用固定 ⌘⇧V 启用开关，保留旧自定义配置直至实际切换并保存；移除独立暂停/恢复，只保留独立卡片中的历史总开关，关闭不清历史。点击缩略图或聚焦后按 Enter / Space 打开图片预览；支持 Nivlet 窗口内图片框外关闭，修复异步刷新后焦点恢复。保存栏正常态 60px，并精简用户指定的说明。权限、其他快捷键、规则、复制/Option 粘贴和历史保留期限不变。浏览器并非支持任意协议或文件格式，详见 [2.0.0 说明](documentation/RELEASE-v2.0.0.md)。

发行包仅移除明确不参与运行的框架开发文件，运行资源、许可证和 dSYM 保留。最终 ZIP 11,395,276 bytes、DMG 13,313,896 bytes、App 普通文件 41,733,870 bytes，磁盘占用 41,444 KiB；校验值和相对 1.0.8 Build55 的比较见 VALIDATION。新包证据独立于旧 1.0.9 产物，不改名套用。另清理 295 条普通自有注释，必要工具/法律/第三方内容保留；语义审阅、256 项隔离 UI 检查及静态实现等价核对通过，不扩大为新包全量真机验收。

历史未发布候选 1.0.9 / Build 56 r2（`32d3395`）已完成签名、公证及本机测试阶段；旧菜单关闭异常在用户手工停止共享并重开后恢复，没有菜单产品补丁，也不扩大为其他场景通过。该候选 ZIP 11,400,155 bytes、App 普通文件 41,741,328 bytes，仅保留为历史测量，详细证据见 VALIDATION。

历史 1.0.8 Build 55：双架构签名、公证、附加票据与 Gatekeeper 检查通过；单台 Apple Silicon Mac曾通过本地测试 feed 完成正式 Build 54 → 55 Sparkle 升级。Intel 仅完成包级检查，不能写成真机通过。完整历史证据见 [VALIDATION](documentation/VALIDATION.md)。

官网来源为本仓库 `docs/`；独立本地 `website/` 不纳入当前提交。不得覆盖原工作区已有未提交内容。知识库仅同步项目摘要、决策和入口，不复制安装包、私人配置或凭据。
