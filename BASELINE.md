# Nivlet 当前基准

更新日期：2026-11-02。

当前正式版本为 [2.0.1 / Build 61](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.1)，macOS 13+、Apple Silicon（arm64）。产品源码 `9ddcbf9dd6ac951463a9c0c8ed929357c44996c9` 与已安装验收包的产品文件一致；发行 tag 在该提交上增加公开说明和媒体，不把文档变动计为产品差异。

本次范围：保持唤醒与保持屏幕长亮两个默认关闭的开关；统一五款已知浏览器的资料和图标、增加 Brave 原生清理确认入口；移除 MAC 地址行及对应设置。保持 2.0.0 已确认的其他功能和设计。没有亮度调节。

54 个回归文件、408 项隔离 UI/布局检查、独立审阅和本机安装核验通过。App/DMG 均已签名、公证、附加票据并通过 Gatekeeper。31 个偏好键在最终升级前后语义无变化；未测试的物理时序、其他设备和完整更新安装路径如实列于[版本说明](documentation/RELEASE-v2.0.1.md)。

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
