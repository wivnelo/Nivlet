# 配置备份与导入

> 适用于当前正式版 1.0.0 / Build 32（配置格式版本仍为 1）。当前状态见 [BASELINE.md](../BASELINE.md)。直接编辑配置并重新加载仍在开发计划中，本页说明现有导入导出功能。


在 **设置 → 通用 → 配置备份与迁移** 中操作。

- **导出配置…**：选择文件夹，生成带时间戳的 `Nivlet-config-*.json`，包含各功能当前已保存的设置。不会保存界面中的草稿。
- **导出默认示例…**：生成同格式的 `Nivlet-defaults-*.json`，各功能提供完整默认值；窗口、输入法、剪贴板、浏览器分流和应用启动默认关闭，无预设快捷键。
- **导入配置…**：选择 JSON，校验后显示将替换的模块配置；点击 **确认导入** 才应用。取消不修改配置。

也可以下载 [默认示例](../examples/configuration.json)，用文本编辑器修改后导入。JSON 不支持注释或末尾多余逗号。

## 只导入需要的功能

`modules` 中可以只保留需要更新的模块。每个包含的模块整体替换，不合并其中的规则；没有包含的模块保持现状。确认导入也会替换对应模块的未保存输入，请先保存需要保留的草稿。

例如，导入以下文件，仅为 Calculator 设置 Control+Option+9。应用已打开时切换到前台：

```json
{
  "format": "Nivlet",
  "version": 1,
  "modules": {
    "launcher": {
      "enabled": true,
      "rules": [
        {
          "bundleID": "com.apple.calculator",
          "name": "Calculator",
          "shortcut": {"key": "9", "mods": ["ctrl", "alt"]}
        }
      ]
    }
  }
}
```

按键支持字母、数字、`left`、`right`、`up`、`down`、`return`、`=` 和 `-`；修饰键为 `ctrl`、`alt`、`cmd`、`shift`，至少选择前三种中的一种。快捷键不得与窗口管理、剪贴板菜单、其他应用规则或系统占用重复。`popupShortcut: false` 表示解除剪贴板菜单快捷键。

窗口模块为 `windows`，`shortcuts` 支持以下操作名（全部默认留空）：

- 基本：`left`、`right`、`top`、`bottom`、`maximize`、`restore`。
- 四角与居中：`topLeft`、`topRight`、`bottomLeft`、`bottomRight`、`center`。
- 三分区：`leftThird`、`middleThird`、`rightThird`、`leftTwoThirds`、`rightTwoThirds`；竖屏按上、中、下对应。
- 九宫格：`grid1`–`grid9`，从左上到右下编号。
- 大小与屏幕：`grow`、`shrink`、`screenLeft`、`screenRight`。

旧文件中的四项操作仍兼容；旧版 Nivlet 不支持新操作名，更新软件后再导入这些字段。

输入法模块为 `input`，规则填写应用的 `bundleID` 和本机的 `sourceID`。浏览器模块为 `browser`，域名规则使用 `domain`、`browser`（浏览器 Bundle ID）和 `subdomains`，来源应用规则使用 `bundleID`、`name`、`browser`。其他字段见默认示例。

## 校验与数据保护

文件最大 1 MB，当前格式版本为 1；未知模块、字段、不支持的版本、非法值、重复规则、快捷键冲突和本机不可用的目标都会提示，不自动换成其他应用。启用窗口管理需要辅助功能权限。系统权限、登录项及 macOS 默认浏览器不会随配置导入。

校验通过后统一应用；保存或快捷键注册失败时恢复本次导入前的配置和绑定。若恢复也失败，会明确提示检查设置。应用期间不要退出软件。

配置文件不包含剪贴板历史、图片缓存、日志或窗口恢复记录。导入后不会把文件内容变成剪贴板记录。若剪贴板已有历史，关闭图片、关闭已有的持久保存，或缩小容量/保留时间的导入会被阻止；请先在剪贴板设置中单独处理，不会因导入自动清空历史。关闭记录仅停止采集，不删除已有历史，仍受容量与保留时间限制。

导出的应用规则可能包含个人应用名称和 Bundle ID，公开分享前请自行检查。导出默认示例不包含个人规则。

通用配置可选 `tabOrder` 数组保存标签顺序，例如 `["launcherSection", "windowSection", "inputSection", "clipSection", "systemSection", "browserSection"]`。不包含固定的 `generalSection`；重复或未知标识会被拒绝。省略时使用默认顺序，新标签自动追加。

设置标签顺序仅控制中间功能：通用固定最左，关于固定最右。旧配置中的关于位置会自动忽略，其余功能的相对顺序保留。

## 剪贴板保留时间

`clipboard.minutes` 为整数：`0` 表示永久，`1–1440` 为分钟数。界面提供 30/60/120/240/480/720/1440/0；旧自定义分钟数与条数保留。`limit` 仍为 10–100 的整数，默认 50；永久模式仍限制条数与最多 10 张图片。`persistent` 独立控制跨重启保留。已有历史时，导入从永久改为限时可能清理记录，会要求先到剪贴板设置中处理，不隐式删除历史。

通用配置可选布尔字段 `sleepShortcut`（省略或 `false` 默认关闭）；为 `true` 时注册 Command + L 系统睡眠，会检查窗口、剪贴板及应用启动快捷键冲突。登录项仍属于当前 Mac，不进入 JSON。设置页右下角统一保存，剪贴板页同时保存历史选项和菜单快捷键。
