# Nivlet 当前基准

更新日期：2026-11-01。

当前开发候选：**1.0.9 / Build 56**，macOS 13+，仅 Apple Silicon（arm64）。最终候选尚待独立代码审阅、回归、原生构建、Developer ID 签名、Apple 公证、Gatekeeper 与本机验收完成，未正式发布。安装状态、候选编号和真实验证结果以 [UI 实施与验收记录](documentation/UI-A-IMPLEMENTATION.md) 及 [VALIDATION](documentation/VALIDATION.md) 的对应版本记录为准；旧包通过不代表新包通过。

已核验的最新正式发行仍为 **[v1.0.8 / Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8)**，Build 55 资产于 2026-10-29 发布。该 Release 保留 Build 54 与 Build 55 的双架构 ZIP、DMG 和 SHA-256；v1.0.8 tag 解引用至 `0772475f731ca887b23ca6ae49878d4e520c70c1`，未因新增 Build 55 资产而移动。下一版必须使用新 tag 和新资产，绑定最终源码提交，不覆盖历史发行。

**1.0.8 / Build 55 为最后 Intel（x86_64）版本。** 由于缺少 Intel 真机验收条件，从 1.0.9 起不再构建、发布或支持 Intel；历史 Intel 发行资产保留。新更新源只提供有 `hardwareRequirements=arm64` 限制的 Apple Silicon 项，不能向 Intel 发送 arm64 包。

1.0.9 改动范围：八个设置页采用左侧导航与右侧内容；本地 `.html`/`.htm` 交给已配置的实际浏览器；“保存全部设置”处理所有 dirty 页面并保留未成功保存的草稿；修复审阅确认的稳定性缺陷。新增繁体中文（台湾用语）与日语，香港环境使用繁中回退，不宣称母语人工审校。本轮另按用户要求把剪贴板菜单快捷键改为固定 ⌘⇧V 启用开关，保留旧自定义配置直至实际切换并保存；移除独立暂停/恢复，只保留历史记录总开关，关闭不清历史。图片预览支持 Nivlet 窗口内图片框外关闭；保存栏和两处指定说明同步简化。权限、其他快捷键、规则、复制/Option 粘贴和历史保留期限不变。浏览器并非支持任意协议或文件格式，详见 [1.0.9 说明](documentation/RELEASE-v1.0.9.md)。

发行包仅在签名前去除明确不参与运行的框架开发头文件与模块描述；安装包保留运行组件、资源、许可证和有效签名；匹配 dSYM 独立保留在构建目录，不进入安装包。实际压缩包与安装体积需在最终产物上核对，不按预估宣传收益。

历史 1.0.8 Build 55：双架构签名、公证、附加票据与 Gatekeeper 检查通过；单台 Apple Silicon Mac曾通过本地测试 feed 完成正式 Build 54 → 55 Sparkle 升级。Intel 仅完成包级检查，不能写成真机通过。完整历史证据见 [VALIDATION](documentation/VALIDATION.md)。

官网来源为本仓库 `docs/`；独立本地 `website/` 不纳入当前提交。不得覆盖原工作区已有未提交内容。知识库仅同步项目摘要、决策和入口，不复制安装包、私人配置或凭据。
