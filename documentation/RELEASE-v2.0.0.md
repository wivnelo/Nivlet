# Nivlet 2.0.0 · Build 57

**[2.0.0 / Build 57 已正式发布](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.0)。** 最终安装包已使用 Developer ID 签名并通过 Apple 公证，包校验与本地更新签名、篡改拒绝及 Intel 不匹配检查通过。正式 tag `v2.0.0` 指向 `9937af7`，产品源码为 `9c96dc0`；公开附件下载与最终产物一致。Pages、线上 appcast 与知识库同步仍待完成。原生测试保留实际来源和范围，详见 [验收记录](VALIDATION.md)。

## 改动范围

- 八个设置页统一采用系统设置式左侧边栏与右侧内容，保留原有模块、规则及权限边界。
- “保存全部设置”一次处理所有已修改页面：先校验再保存，未修改页面不被覆盖；失败保留相关草稿并定位错误。“取消当前页修改”仍只取消当前页。跨模块运行时应用不宣称具备完整原子事务。
- 增加本机 `.html`、`.htm` 文件转交，使用已配置的实际浏览器，保持现有 HTTP/HTTPS 分流语义。中文、空格及特殊字符的文件路径由原生 URL 构造处理。
- 增加繁体中文（台湾用语）与日语；界面语言为简体中文、English、繁體中文、日本語及跟随系统。香港语言环境使用繁体中文回退，不是独立港式本地化；不宣称完成母语人工审校。
- 稳定性修复包括异常 URL query 解码的空值防护、全局保存批次回执与重复提交保护、取消修改时保留最新运行数据，以及历史异步刷新后预览焦点恢复。剪贴板关闭采集后，仅在有待过期历史时安排清理计时器，避免无用轮询。
- 安装包仅精简不参与运行的框架开发头文件、模块描述和对应链接，保留所有运行组件与许可。体积须以最终 2.0.0 签后包实测，不把整版差值全部归因于裁剪。
- 清理 295 条普通自有注释（占用 296 行），保留换行、字符串和代码语义；保留版权与许可、shebang、工具/测试边界注释、Python docstring，以及第三方源码和补丁上下文。本项不新增功能，也不作为运行性能提升的声明。

## 设置与剪贴板交互调整

以下为本次 2.0.0 的功能与交互范围；历史候选回归和新版本最终验收分别记录。

- **保存区域**：底部保存栏正常状态高度为 60px；保存反馈与按钮位置保持稳定，避免反馈出现或消失时跳动。全局保存、校验失败定位和草稿保留沿用上文语义。
- **通用页说明**：仅移除“在菜单栏显示 Nivlet 主图标”开关下的说明文字；开关及其作用保持原样。
- **剪贴板菜单快捷键**：设置页只提供启用开关，固定组合显示为 **⌘⇧ + V**，实际绑定为 **⌘⇧V**。新安装或没有该配置时默认开启；已有明确的 `false` 保持关闭。启动时保留旧配置中的自定义组合，不因加载设置或保存其他修改就重写；只有用户实际切换快捷键开关并保存，才应用固定组合或关闭绑定。
- **记录状态**：彻底移除独立的暂停/恢复状态与操作，使用独立卡片中的“启用剪贴板历史”总开关控制记录。关闭只停止采集，不清空已有历史，原有数量和保留期限继续生效。旧保存配置如果明确包含 `paused: true`，则在启动迁移时关闭记录；缺少该字段时，不推测或恢复旧进程内存中的暂停状态。
- **剪贴板说明**：移除“如何使用剪贴板菜单”的折叠说明区及用户指定的三处剪贴板辅助说明。点击历史项复制、Option 点击粘贴、隐私说明与应用排除功能保留。
- **图片预览**：点击历史缩略图，或聚焦后按 Enter / Space 打开；移除独立预览按钮和关闭按钮。点击 Nivlet 窗口内、图片元素边框以外的区域可关闭预览；图片元素框内的透明像素仍属于图片，不触发关闭。Esc 关闭、焦点恢复和阻止点击穿透保留，修复历史异步刷新后的焦点恢复，不新增全局鼠标监听或权限。

## 原生菜单语言

原生菜单标题补齐简体中文、英文、繁体中文与日语资源，由 macOS 的应用启动语言选择。Toolkit 的语言偏好控制其自身界面，不强制 AppKit 或 Sparkle 原生对话框即时切换语言。繁体采用台湾用语，香港环境使用繁体回退，不宣称独立港式本地化或母语人工审校。

## 架构支持变化

从 **2.0.0 起仅支持 Apple Silicon（arm64）**，要求 macOS 13.0+。因没有 Intel 机器用于持续验收，后续不再构建、发布或支持 Intel。

**[1.0.8 / Build 55 是最后 Intel（x86_64）版本](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8)**，历史安装包继续保留。本次没有 Intel 真机测试；停止 Intel 新包不代表删除历史发行。

## 兼容性边界

- 本地文件支持范围仅为 `.html`/`.htm`，不是通用文件查看器；不新增 PDF、TXT、PNG/JPG、SVG、XHTML 或 `.url`/`.webloc` 内容解析承诺。
- `mailto:`、`tel:` 等继续由对应系统应用处理；不开放任意 scheme，也不转交执行 `javascript:`、`data:` 或 `blob:`。
- 本机 `file:` 支持与远程主机地址严格区分；不扩大网络文件或系统权限。
- 除上文明确列出的记录状态、菜单快捷键和图片预览变化外，复制与 Option 粘贴、清除数据确认、默认浏览器和系统权限语义保留。未完成的 Finder 到测试浏览器、更新或其他系统验收必须在最终记录中如实列出。
- 原生文档类型声明宽于本次本地 HTML 实现范围；冷启动只暂存一个尚未派发的事件，连续多文件打开仍有覆盖边界。此次未扩展为通用文件处理器，也未改变该既有行为。
- 保活功能仍处于设计咨询阶段，未实现，不属于本次发行。
- 测试时曾观察到原生菜单不能通过 Esc/外部点击关闭；用户关闭共享并手工重开后，菜单栏和快捷键两种入口均恢复正常。该人工对照支持远程控制状态干扰的判断，不构成本次菜单代码修复，也不代表所有原生场景均已验收。

## 构建、包体与验证记录

最终源码为 `9c96dc0`，产物为 `Nivlet-2.0.0-build57-arm64`。arm64 编译、Developer ID 签名、App/DMG 公证与票据、Gatekeeper、资源/架构/许可及压缩包核对通过；本地更新签名、篡改拒绝与 Intel 不匹配测试通过。实际 Sparkle 安装未在本轮执行。

最终 ZIP 为 11,395,276 bytes，DMG 为 13,313,896 bytes，App 普通文件合计 41,733,870 bytes，本机磁盘占用 41,444 KiB。与正式 1.0.8 / Build 55 arm64 比较，分别减少 0.8883%、6.1022%、0.4587% 与 0.7567%。差异包含资源、编译、签名和维护清理，不全部归因于框架裁剪或停止 Intel 构建。校验值与验证范围见 [VALIDATION](VALIDATION.md)；1.0.9 的历史测量保持原版本归属。

## Release notes (English)

Version 2.0.0 / Build 57 is now available. The final packages are Developer ID signed and notarized by Apple; package verification and local signed-update, tamper-rejection and Intel-mismatch checks have passed. The v2.0.0 tag points to `9937af7`, with product source `9c96dc0`; public downloads match the final artifacts. Website deployment and the online update feed still await synchronization. Historical native tests keep their original commit attribution and scope; this is not a claim that the new package completed a fresh full native test. The release unifies eight settings pages with a sidebar, adds local HTML/HTM forwarding, saves changed pages together, and adds Traditional Chinese (Taiwan terminology) and Japanese. Hong Kong locales use the Traditional Chinese fallback; this is not a separate Hong Kong localization or a claim of native-speaker review.

The release keeps the normal save footer at 60px, removes the helper text below the main-icon switch, and simplifies clipboard controls. Recording uses one enable switch in its own card instead of a separate pause/resume state; disabling it keeps history subject to existing limits. The menu-shortcut switch displays ⌘⇧ + V and binds ⌘⇧V: new or missing settings default on, explicit `false` stays off, and legacy custom shortcuts remain until the switch is actually changed and saved. An explicitly stored legacy `paused: true` state migrates to recording disabled at startup; an absent field does not imply a previous in-memory pause.

The clipboard menu-help disclosure and three requested clipboard explanations are removed while copy, Option-click paste, privacy and app exclusions remain. Click a thumbnail, or focus it and press Enter or Space, to open a preview without a separate preview button. There is no close button: clicks inside Nivlet but outside the image element dismiss the preview; transparent pixels inside the image do not. Escape and click-through prevention remain, and focus restoration after asynchronous history refresh is fixed, without new global mouse permissions. Native menu resources follow macOS's app startup language; changing the Toolkit preference does not force AppKit or Sparkle dialogs to switch immediately.

Stability work covers malformed URL query decoding, save-batch acknowledgements and duplicate submissions, preserving current runtime data when cancelling drafts, and avoiding clipboard expiry polling when nothing can expire. Save All Settings validates before applying changes, leaves unchanged pages untouched and preserves failed drafts; it is not a cross-module atomic transaction. Local file forwarding is limited to readable HTML/HTM files on this Mac. Other local formats, remote file hosts and arbitrary schemes are outside this change. Existing native document-registration and cold-start multi-event limitations remain. Keep-awake functionality is not implemented in this release.

Removed 295 ordinary first-party comments spanning 296 lines, preserving line breaks, strings and code semantics. Copyright and license notices, shebangs, tool/test markers, Python docstrings, and third-party source and patch context are retained. This maintenance change adds no features and makes no runtime-performance claim.

During testing, native menus temporarily failed to dismiss with Escape or an outside click. After the user stopped sharing and manually relaunched Nivlet, both the menu-bar and shortcut entry paths dismissed normally. This manual comparison supports interference from the remote-control state; no menu code patch was added, and the result does not establish acceptance of every native interaction.

New releases support **Apple Silicon (arm64), macOS 13+ only**. [1.0.8 / Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8) remains the final Intel release, with its existing downloads retained. No Intel hardware test is claimed. Runtime resources, all four native menu localizations and dependency licenses are verified in the final package. Final sizes, checksums and validation scope are recorded in VALIDATION; unpublished 1.0.9 measurements retain their historical attribution.
