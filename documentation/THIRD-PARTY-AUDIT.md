# 第三方许可工程核查

当前发行：1.0.8 / Build 54。Apple Developer ID 签名与 Apple 公证已完成；签名、公证与第三方许可人工复核分别记录，不以公证通过代替许可复核。包内收集 81 份许可原文及 Sparkle 声明，收集脚本回归覆盖 suffix-named 许可文件。完整特殊许可人工复核仍开放，见 [ROADMAP](../ROADMAP.md)。不将工程收集成功视为法律审查完成。

## 当前来源

Runtime 固定为 Hammerspoon 1.1.1，commit `1469832361b4c3687ec7d589c1b4efe4d3b742ee`，含 Nivlet 定制补丁；不是未修改的上游官方安装包。固定依赖由 `scripts/fetch-runtime.sh` 准备，不自动跟随上游更新。

| 来源 | 声明收集方式 |
| --- | --- |
| Hammerspoon | 根目录 THIRD-PARTY-NOTICES.md 保留上游 MIT 声明 |
| CocoaPods 依赖 | Pods-Hammerspoon-acknowledgements.markdown 整体收集，含 ASCIImage、CocoaAsyncSocket、CocoaHTTPServer、CocoaLumberjack、MIKMIDI、ORSSerialPort、PocketSocket、Sentry、SocketRocket、Sparkle |
| Runtime 扩展及附带库 | 收集 checkout 中 LICENSE、LICENSE.md、LICENSE.txt、COPYING、COPYRIGHT 文件，排除 .git 和 Headers 重复目录 |
| Lua 5.4.7 | 单独收集 README 中的版权与许可 |
| Nivlet | 自有 LICENSE 随包保留，不能替代第三方许可证 |

`scripts/collect-notices.py` 生成合并声明，放在应用 `Contents/Resources/Toolkit/THIRD-PARTY-NOTICES.md`；“关于”页读取此文件。当前构建收集日志为 81 个许可文件，另含 CocoaPods acknowledgements 和 Lua README；数量本身不证明全部义务已经满足。

## 发布前核查

- 对照当前包中 Framework、动态库、辅助程序和链接依赖，确认每个来源有对应声明，不能只按界面上实际启用的模块统计。
- 更新依赖后重新收集声明；检查非标准名称的许可文件、嵌入版权和附加分发条款，文件名扫描可能遗漏这些内容。
- 保留上游版权和定制修改来源；不宣称本项目得到 Hammerspoon 官方背书。
- 校验合并声明与最终 ZIP/DMG 中的文件一致；安装包不带个人数据或凭据。
- 本文是工程检查记录，不是法律意见；发现不明确的分发条款时先核实再发布。

## 当前边界

已检查收集流程、固定来源和依赖 acknowledgements；完整二进制来源映射和所有特殊条款的人工复核仍是正式发布门槛。不得仅因收集脚本成功就将“第三方许可全面审查”标为完成。
