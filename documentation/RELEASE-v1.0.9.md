# Nivlet 1.0.9 · Build 56

**候选，尚未发布。** 最终源码、构建、回归、Apple 公证与本机验收完成后再发布，状态见 [BASELINE](../BASELINE.md)。此说明不能替代最终验收结果。

## 改动范围

- 八个设置页统一采用系统设置式左侧边栏与右侧内容，保留原有模块、规则及权限边界。
- “保存全部设置”一次处理所有已修改页面：先校验再保存，未修改页面不被覆盖；失败保留相关草稿并定位错误。“取消当前页修改”仍只取消当前页。跨模块运行时应用不宣称具备完整原子事务。
- 增加本机 `.html`、`.htm` 文件转交，使用已配置的实际浏览器，保持现有 HTTP/HTTPS 分流语义。中文、空格及特殊字符的文件路径由原生 URL 构造处理。
- 增加繁体中文（台湾用语）与日语；界面语言为简体中文、English、繁體中文、日本語及跟随系统。香港语言环境使用繁体中文回退，不是独立港式本地化；不宣称完成母语人工审校。
- 稳定性审阅包含异常 URL query 解码的空值防护；其余修复及回归结果以最终审阅记录为准。只修确定缺陷，不为优化改动无关业务。
- 安装包仅精简不参与运行的框架开发头文件、模块描述和对应链接，保留所有运行组件与许可。压缩后收益待最终包实测，不预先承诺比例。

## 设置与剪贴板交互调整

以下是本候选新增的明确改动范围，仍须随最终实现完成回归与实机验收。

- **保存区域**：底部保存栏正常状态高度为 60px；保存反馈与按钮位置保持稳定，避免反馈出现或消失时跳动。全局保存、校验失败定位和草稿保留沿用上文语义。
- **通用页说明**：仅移除“在菜单栏显示 Nivlet 主图标”开关下的说明文字；开关及其作用保持原样。
- **剪贴板菜单快捷键**：设置页只提供启用开关，启用采用固定 **⌘⇧V**。新安装或没有该配置时默认开启；已有明确的 `false` 保持关闭。启动时保留旧配置中的自定义组合，不因加载设置或保存其他修改就重写；只有用户实际切换快捷键开关并保存，才应用固定组合或关闭绑定。
- **记录状态**：彻底移除独立的暂停/恢复状态与操作，使用“启用剪贴板历史”总开关控制记录。关闭只停止采集，不清空已有历史，原有数量和保留期限继续生效。旧保存配置如果明确包含 `paused: true`，则在启动迁移时关闭记录；缺少该字段时，不推测或恢复旧进程内存中的暂停状态。
- **剪贴板说明**：仅移除“如何使用剪贴板菜单”的折叠说明区。点击历史项复制、Option 点击粘贴、隐私说明与应用排除功能保留。
- **图片预览**：移除独立关闭按钮。点击 Nivlet 窗口内、图片元素边框以外的区域可关闭预览；图片元素框内的透明像素仍属于图片，不触发关闭。Esc 关闭、焦点恢复和阻止点击穿透保留，不新增全局鼠标监听或权限。

## 原生菜单语言

原生菜单标题补齐简体中文、英文、繁体中文与日语资源，由 macOS 的应用启动语言选择。Toolkit 的语言偏好控制其自身界面，不强制 AppKit 或 Sparkle 原生对话框即时切换语言。繁体采用台湾用语，香港环境使用繁体回退，不宣称独立港式本地化或母语人工审校。

## 架构支持变化

从 **1.0.9 起仅支持 Apple Silicon（arm64）**，要求 macOS 13.0+。因没有 Intel 机器用于持续验收，后续不再构建、发布或支持 Intel。

**[1.0.8 / Build 55 是最后 Intel（x86_64）版本](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8)**，历史安装包继续保留。本次没有 Intel 真机测试；停止 Intel 新包不代表删除历史发行。

## 兼容性边界

- 本地文件支持范围仅为 `.html`/`.htm`，不是通用文件查看器；不新增 PDF、TXT、PNG/JPG、SVG、XHTML 或 `.url`/`.webloc` 内容解析承诺。
- `mailto:`、`tel:` 等继续由对应系统应用处理；不开放任意 scheme，也不转交执行 `javascript:`、`data:` 或 `blob:`。
- 本机 `file:` 支持与远程主机地址严格区分；不扩大网络文件或系统权限。
- 除上文明确列出的记录状态、菜单快捷键和图片预览变化外，复制与 Option 粘贴、清除数据确认、默认浏览器和系统权限语义保留。未完成的 Finder 到测试浏览器、更新或其他系统验收必须在最终记录中如实列出。

## Release candidate (English)

Version 1.0.9 / Build 56 is pending final release gates. It unifies eight settings pages with a sidebar, adds local HTML/HTM forwarding, saves changed pages together, and adds Traditional Chinese (Taiwan terminology) and Japanese. Hong Kong locales use the Traditional Chinese fallback; this is not a separate Hong Kong localization or a claim of native-speaker review.

The candidate also keeps the normal save footer at 60px, removes only the helper text below the main-icon switch, and simplifies clipboard controls. Recording uses one enable switch instead of a separate pause/resume state; disabling it keeps history subject to existing limits. The menu-shortcut switch uses ⌘⇧V: new or missing settings default on, explicit `false` stays off, and legacy custom shortcuts remain until the switch is actually changed and saved. An explicitly stored legacy `paused: true` state migrates to recording disabled at startup; an absent field does not imply a previous in-memory pause.

The clipboard menu-help disclosure is removed while copy, Option-click paste, privacy and app exclusions remain. Image previews have no close button: clicks inside Nivlet but outside the image element dismiss them; transparent pixels inside the image do not. Escape, focus restoration and click-through prevention remain, without new global mouse permissions. Native menu resources follow macOS's app startup language; changing the Toolkit preference does not force AppKit or Sparkle dialogs to switch immediately.

New releases support **Apple Silicon (arm64), macOS 13+ only**. [1.0.8 / Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8) remains the final Intel release, with its existing downloads retained. No Intel hardware test is claimed. Final signing, notarization, package size and acceptance results must be recorded before publication.
