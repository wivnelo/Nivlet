# 公开截图与更新方式

## 当前媒体 · 2.0.0 / Build 57 · 2026-11-02

中英文 README 的 16 张截图与 2 个 GIF 均使用与 commit `32d3395` 一致的真实 `Toolkit/settings.html`；界面功能不变，展示版本同步为 2.0.0 / Build 57，版本元数据独立核对当前 `VERSION`。`docs/screenshots.html` 使用同一套中文截图。此次没有独立视频文件或视频嵌入。

这些是隔离浏览器中的真实前端演示，不是原生 App 端到端录像。图内持续标注“示例数据 / UI demo”；权限、默认浏览器、应用安装状态、剪贴板和系统数值都是演示值，不代表默认配置或实际检测结果。应用名/Bundle ID、规则、文本和网络地址使用虚构或文档示例；图片预览使用仓库公开 Nivlet 图标，不读取个人图片。

- 中文静态图：`docs/assets/screenshots/*.jpg`，8 页。
- 英文静态图：`docs/assets/screenshots/en/*.jpg`，8 页。
- 两套静态图均为 2560 × 1800；真实 UI 为 1280 × 872 CSS 像素，上方另有 28 像素媒体说明，2× 输出。
- 动态演示：`docs/assets/demos/overview-en.gif` 与 `overview-zh.gif`，1120 × 850、28 秒、224 帧、平均 8 帧/秒，无声循环。GIF 时间单位为 10 毫秒，因此帧延迟交替为 120 / 130 毫秒。

GIF 逐帧捕捉真实 DOM 操作：侧边栏导航、三分区与九宫格、点击缩略图放大/点击外部关闭、剪贴板搜索、修改默认浏览器与应用快捷键，最后用全局保存一起提交两页草稿。保存前后的 dirty 状态、批量请求内容和确认后的状态由脚本断言；预览返回和保存确认由隔离夹具模拟，图内明确标注。没有调用原生窗口操作、系统剪贴板、应用启动或真实持久化。

### 可重复生成

需要 Node.js、Lua、Playwright、本机 Chromium / Chrome，以及 macOS Swift / ImageIO（GIF 编码不需要 Pillow）。浏览器使用临时独立配置，拦截所有非本地网络请求，原生桥仅处理明确的模拟演示。生成前后会校验 `settings.html`、英文翻译与固定 UI 源码一致，并独立校验 `VERSION` 为 2.0.0。

```sh
NIVLET_SCREENSHOT_BUILD=57 node scripts/render-readme-screenshots.cjs
NIVLET_SCREENSHOT_BUILD=57 node scripts/render-readme-demo.cjs
python3 scripts/encode-readme-demo.py
# Inspect build/media-final/overview-*-contactsheet.png, then publish the reviewed GIFs.
cp build/media-final/overview-en.gif build/media-final/overview-zh.gif docs/assets/demos/
node scripts/verify-readme-media.cjs
```

可用 `NIVLET_SCREENSHOT_BROWSER` 指定浏览器可执行文件。截图先生成到被 Git 忽略的 `build/media-final/screenshots/`，通过语言、布局、图片及源码校验后复制到公开路径；GIF 帧和交互清单位于 `build/readme-demo/`，编码和逐帧回读报告位于 `build/media-final/`。只有最终 JPG/GIF 进入文档，所有临时素材均不进入安装包。

更新时逐页实际查看像素，再回读 GIF 帧数、尺寸、时间和循环信息，并用浏览器播放确认；核对 README/官网引用及版本说明。生成脚本只验证前端演示，不代替原生功能验收。保持 Git 中的旧媒体历史，不上传本机个人配置截图。

## 历史记录（已被本次媒体替换）

### 英文 README 截图 · 2026-10-30

英文 README 使用 `docs/assets/screenshots/en/` 下的 8 张英文图；中文 README 和现有官网画廊继续使用原中文图。两套图分别注明来源，不将旧图描述为当前版本实测。

英文图由 `scripts/render-readme-screenshots.cjs` 加载仓库真实 `Toolkit/settings.html`，使用 `Toolkit/modules/translations.lua` 的英文翻译，在独立无头 Chromium 中渲染。此次界面源码基于 commit `338adfb`，关于页演示版本为 1.0.8 / Build 55。图片为设置界面的浏览器渲染，不包含原生窗口边框，不作为 App 端到端验收。

夹具使用虚构应用名、规则、剪贴板文本、快捷键和系统数值；权限与默认浏览器状态也是演示值。网络地址使用文档示例地址。原生消息桥为空操作，不读取个人数据，不启动 Nivlet，不修改系统设置；页面网络请求被阻止。

重新生成需安装 Node.js、Lua、Playwright 及其 Chromium；从仓库根目录执行：

```sh
NIVLET_SCREENSHOT_BUILD=55 node scripts/render-readme-screenshots.cjs
```

使用本机 Chrome 时可设置 `NIVLET_SCREENSHOT_BROWSER` 为其可执行文件路径。生成前核对源码、`VERSION` 与演示 Build；更新截图后逐页检查语言、布局与演示数据，并核对 README 的图片链接。脚本会检查页面脚本错误、英文语言状态、横向溢出与表单校验错误。

### README 动态演示 · 2026-10-30

中英文 README 的截图上方分别居中嵌入 `docs/assets/demos/overview-en.gif` 与 `overview-zh.gif`。每段 16 秒、960 × 800、8 帧/秒，无声循环；展示窗口布局分组、剪贴板搜索、默认浏览器选择、应用快捷键编辑。图片内及正文均标明界面演示。首页显示宽度为 720 像素，8 张静态截图统一折叠，展开后按两列展示。

动图加载真实设置页，沿用截图隔离夹具，新增标题、操作指示与进度条。仅操作 DOM；原生桥为空操作，不执行真实窗口移动、剪贴板复制、浏览器接管、应用启动或保存配置。不代表这些系统功能的端到端验收。中文演示数据和说明也已本地化。

生成需要截图脚本的依赖，以及安装 Pillow 的 Python：

```sh
NIVLET_SCREENSHOT_BUILD=55 node scripts/render-readme-demo.cjs
python3 scripts/encode-readme-demo.py
```

可沿用 `NIVLET_SCREENSHOT_BROWSER` 指定浏览器。临时帧保存在被 Git 忽略的 `build/readme-demo/`，只有压缩后的 GIF 用于发布。生成后检查两种语言的关键帧、16 秒时长、循环标记及 README 引用。静态截图入口保留，供不便观看动画的读者使用。

### 中文截图历史

2026-10-13：浏览器页同步 1.0.1 / Build 41 真实 WebView 演示截图，其余页面保留原有 Build 32 界面参考；均使用隔离夹具，不读取个人数据。Safari / Chrome 图标是功能所支持的公开应用标识。

2026-10-12：当前发布为 1.0.0 / Build 32，功能界面未变；截图更新为 1.0.0 / Build 32 的界面参考，8 个页面，中文深色；资源位于 docs/assets/screenshots/。中英 README 正文展示窗口管理与剪贴板两张，其余六张默认折叠；官网 screenshots.html 提供完整响应式画廊。

截图来自独立身份的真实 Runtime WebView，加载正式 Build 32 settings.html。仅使用手工生成的演示夹具；bridge 为无写入回调。没有读取个人配置、应用清单、剪贴板或系统网络信息。软件名称/Bundle ID、图标、规则、快捷键、历史文字、网络地址和状态数值均为虚构示例。截图标题及文案注明演示，不代表默认配置或真实权限/接管检测结果。公开图只从这套演示窗口获取，未使用本机原始截图。

后续更新仍使用隔离演示数据，逐页核对页面、版本、可见内容与隐私，检查图片引用、尺寸和移动布局；应用版本变化时重新截图。旧 build/screenshots-* 本机截图不上传，可能包含个人配置或地址。

截图展示不等于全功能人工验收。
