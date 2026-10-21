# 1.0.0 / Build 32 验收

本次仅重置推广版本与公开仓库，既有功能保持不变。

用户于 2026-10-12 确认当前 1.0.0 / Build 32 已完成整体人工检查，作为后续开发基准；此前多显示器验收记录保留。本次完成 32 项源码/独立回归、最终资源 132 项原生 WebView 回归（中英、深浅色与三种窗口尺寸），全部通过。干净 Release 构建、严格 ad-hoc 签名、包体隐私检查、ZIP 逐文件/CRC/SHA-256、DMG 完整性与只读挂载、Ed25519 签名和篡改拒绝检查通过。线上发布验收时：新仓库仅一条初始提交、一个 v1.0.0 标签及一个正式 Release；三个附件下载回核与本地完全一致。GitHub Pages 部署成功，官网、画廊及 appcast 与本地逐文件一致。旧 SHA 抽查被拒绝，不据此承诺 GitHub 全部缓存或外部副本均已清除。

其他 Mac/macOS、全部第三方输入法及完整跨机器 Gatekeeper 流程尚未全面覆盖。尚无 Apple Developer ID 签名或 Apple 公证。本机 /Applications/Nivlet.app 的 Info.plist 已核对为 1.0.0 / Build 32。

2026-10-12 按用户授权永久清理项目 build/ 中旧版本构建、安装包、测试产物与历史备份，保留 Build 32 正式包、当前构建及验收证据；定向注销 43 条不存在的历史 App/内嵌组件注册，另已注销旧 Build 30、31 构建 App。未修改默认浏览器。

## Intel 本地候选包 · 2026-10-13

1.0.0 / Build 33，x86_64，macOS 13.0+；沿用 Build 32 功能，未安装或公开发布。干净中性目录 Release 交叉构建通过；101 个内嵌 Mach-O 全为 x86_64，最低系统要求不高于 13.0；Release dSYM UUID 与导出符号检查、严格 ad-hoc 签名、仓库/App/ZIP 隐私扫描通过。Toolkit 源文件逐项与源码及 Build 32 arm64 资源一致。ZIP CRC 与 381 个包内文件逐字节核对通过，DMG 完整性、只读挂载、Intel 安装说明及挂载 App 签名通过；Intel 与原有 arm64 包 SHA-256 均核对通过，旧包未覆盖。

构建脚本新增目标架构参数；使用双架构编译样本验证 arm64/x86_64 裁剪与错误切片拒绝，5 项隐私回归、shell 语法及 diff 检查通过。未运行 Intel App，未在 2018 款 MacBook Pro 或其他 Intel 真机验收；本机 Apple Silicon 的构建成功不等于 Intel 运行验收。需在 macOS 13+ 的 Intel 机器检查启动、权限、主要模块及重启保留后，再考虑正式发布。公开 appcast 仍仅 arm64，本次不改变现有更新通道。证据在本地 build/intel-1.0.0-build33/，安装包位于 build/packages/。

## 截图试验撤回 · 2026-10-13

用户决定取消截图功能，源码恢复至截图前基准 30ec30e（保留 Intel 构建支持），删除截图源码、测试和 Build 34 产物。本机恢复 1.0.0 / Build 32，配置及剪贴板数据目录不清理；截图不再列入开发队列。公开发行和更新源未改变。

撤回后补充核查：已停止残留截图 QA 进程，注销三条已删除的截图开发路径注册，并删除本轮临时编译/测试程序；回核截图辅助进程和注册均为零，偏好审计未发现截图专用字段。原有配置和剪贴板历史保留。

## 浏览数据入口候选 · 2026-10-13

浏览器页面顶部新增单行浏览器选择与清除入口，仅列出已安装的 Safari / Chrome，选择独立保存在本机，不进入分流配置或草稿判断。操作仅请求打开浏览器原生清除窗口，不执行最终清除；权限不足、启动失败、前台等待超时均有提示。Safari 当前支持中文/英文菜单。

现有全部 Lua 回归及新增浏览数据回归通过；实际 WKWebView 使用生产 HTML 和翻译表验证浏览器筛选、选择恢复、分流草稿保留、忙碌与失败恢复、空状态、中英切换和深浅色状态通过。尚未在真实 Safari / Chrome 完成按钮到原生窗口的端到端验收，也未在 Intel 或其他 macOS 验收。

Build 35 本地候选构建使用临时 xcconfig 将 Xcode 27 第三方运行时的 `poison-system-directories` 警告保留为警告（C/C++）；没有修改仓库构建配置。该兼容问题需在正式发布前单独处理。

Build 35 arm64 Release 构建及本地 DMG/ZIP 打包完成；严格签名、仓库/App/ZIP 隐私检查、ZIP CRC 和内嵌 Toolkit 与当前源码逐文件核对通过。未替换 /Applications 中的基准版本，未提交或推送。

本机替换验收：用户授权后正常退出 Build 32，安装并启动 Build 35，签名复验通过。实际设置页显示顶部单行入口，原有浏览器分流规则保留；观察到 Chrome 操作返回请求已发出，Chrome 前台地址为 chrome://settings/clearBrowserData。未执行清除，Safari 原生弹窗仍待确认。

## 浏览数据 UI 修正 · Build 36

恢复左侧浏览器图标、名称和下拉箭头，清除按钮右对齐，采用既有页面配色和控件圆角；权限及清除入口逻辑不变。复用 Build 35 原生二进制与匹配 dSYM，更新 Toolkit 资源及版本号为 36 后重新 ad-hoc 签名，没有重新编译原生代码。标准/620 点窗口 WebView 对齐回归通过，中英、主题、选择、空状态与分流草稿回归通过。

本机已安装并启动 Build 36，实际界面确认图标、名称、箭头及右侧按钮正常，下拉菜单包含 Safari / Chrome，原有分流规则保留。未清除浏览数据，未改系统权限，未提交或推送。

Build 37 UI 收敛：下拉选中项与每个选项均包含 App 图标和名称，直接复用应用启动列表 `.app-icon` 的 24×24 样式；文字继承现有字号，菜单与选择框等宽，移除额外行背景。实际 WKWebView 展开状态已检查，图标尺寸、菜单宽度、右侧按钮对齐及既有选择/草稿回归通过。本机资源已逐字节核对同步。复用 Build 35 原生二进制，仅更新资源/版本号并重签名；未执行清除、未提交或推送。

Build 37 样式追加：按用户反馈恢复浏览器选择和清除按钮的整行底色容器，选中项减弱边框；移除下拉箭头，图标/名称仍可展开带图标选项。本机已同步更新。

## 最终标题栏入口 Build 38

恢复原有浏览器页面主体，仅在标题右侧增加清除浏览数据按钮。权限检查通过后弹出 Safari / Chrome 菜单，图标复用应用列表 24×24 样式，菜单与按钮右对齐。原有重新检测无边框样式保持不变。旧常驻选择框、记忆选择 API、桥接字段及旧样式/测试已删除。全部 Lua 回归、JS 语法、标准/620 点 WebView 回归通过。本机已安装，配置与历史保留。原生二进制和 dSYM 复用 Build 35，资源更新重签名，DMG/ZIP 隐私及签名检查通过。未提交或推送；真实 Safari 弹窗和跨机器验收仍开放。

Build 38 等宽修正：按钮和菜单共用 190 点容器宽度，菜单 width:100%；回归同时验证左边缘、右边缘及宽度一致，本机已同步。

等宽实现更正：保留原清除按钮自然宽度，仅下方菜单 width:100% 跟随按钮，不固定或放大按钮；菜单图标不收缩，长名称截断。本机已更新，对齐与图标回归通过。

## Build 39 菜单生命周期修复

菜单仅在浏览器列表/名称/图标变化时重建，普通权限刷新保留原选项节点及焦点。切离浏览器页关闭菜单并取消待处理打开请求；权限请求携带递增 requestID，忽略已失效响应，防止切页返回或新旧请求交错导致误打开。原按钮自然宽度和现有 UI 样式不变。

全部 Lua 回归、JS 语法及标准/620 点实际 WebView 回归通过；新增验证刷新焦点保持、切页关闭、返回仍关闭、隐藏页晚到响应、新旧请求交错。本机 Build 39 已安装，复用原生二进制/dSYM 更新资源重签名，个人配置和历史保留。未提交或推送。

## Build 40 再次唤起保留页面

根因：Runtime applicationShouldHandleReopen 调用 dockIconClickCallback，原实现每次指定 generalSection。现在已有 settings 窗口时仅显示，不发送切页指令；首次创建仍进入通用。新增 Runtime 回归修改前失败、修改后通过，全部 Lua 回归通过。本机 Build 40 已安装；实际选择浏览器页、切到 Finder 后按 Option+H，Nivlet 页面仍保持浏览器。未更改应用启动配置、其他显式跳转入口或 UI 样式。复用原生二进制/dSYM 更新资源重签名，未提交或推送。

## 1.0.1 / Build 41 发布准备

2026-10-13：同步当前版本、安装与使用指南、官网、版本记录和更新源生成描述，历史验收保留原版本。计划同时打包 arm64 与 x86_64，Intel 待用户真机测试；feed 保持 arm64。发布、下载回核、清理与更新渠道升级结果随后补充。

1.0.1 / Build 41 arm64 与 x86_64 全新中性目录 Release 构建均成功，架构、版本号和全部 Toolkit 与源码核对通过；严格签名及仓库/App/ZIP 隐私检查通过，分别生成 DMG/ZIP/SHA-256。Xcode 27 第三方运行时使用临时 xcconfig 将 poison-system-directories 保留为警告，其他错误检查和包内隐私检查不变。Intel 尚待真机测试。公开浏览器截图同步为隔离真实 WebView 演示图。

## 1.0.1 / Build 41 发布完成与更新渠道验收

GitHub v1.0.1 已正式发布，包含 ARM 与 Intel 各 DMG/ZIP/SHA-256 六个附件；服务端 SHA-256 及全部公开下载逐字节与本地一致。官网 main/docs 部署成功，线上首页、浏览器截图和签名 appcast 与源码一致。feed 只提供 arm64，Intel 为待真机验证候选。

本机由 1.0.0 / Build 40 在“关于 → 检查更新”识别 1.0.1，经过公开 Sparkle 渠道更新并重启为 1.0.1 / Build 41；安装 App 全部普通文件与公开 arm64 包逐字节一致，严格签名通过。现有浏览器规则及通用设置仍在，未删除配置或个人剪贴板数据。用户随后在新版浏览器页操作，原生清除入口请求可返回。

按授权清理本轮 Build 35–40、历史 Intel Build 33 构建目录及对应 21 个候选附件，共 28 条项目内路径；清理本轮命名的临时 UI/编译/审计夹具。保留 Build 32 基准、1.0.1 双架构发行物、匹配 dSYM、构建和下载/升级验证证据。清理清单位于本地 build/release-1.0.1-verification/cleanup.json。

剩余边界：Intel 真机测试由用户后续进行；没有 Developer ID/Apple 公证；其他 macOS 与 Safari 非中英文菜单未全面验收。

清理后补充回核：七条已删除候选 App 的 LaunchServices 注册已定向注销，回核无残留；未修改默认浏览器或系统权限。

## 1.0.2 / Build 43 · 应用状态刷新与发布准备

用户反馈：另一台 Intel Mac 已验证 Build 42，主要功能、未安装浏览器隐藏及安装后使用正常；随后发现运行中新增浏览器需重启及卸载后的列表/图标刷新不足。本记录保留测试层级，公开文案不再重复机器验收提示。

根因：后端 browser.installed() 返回新列表，但前端已有选择框仅在初始化/保存时填充；图标的成功与失败缓存均不会随安装状态失效。修复：返回设置/切入相关页/添加应用后更新应用状态与图标，原生路径需存在才列为已安装；同步全部浏览器选择框，失效选值改选首个可用浏览器并要求保存；空列表禁用。应用规则及快捷键保留，卸载状态标记“未安装”，重装后恢复名称和图标；未保存草稿保留。

全部 Lua 回归、隐私回归、Dock 检查、应用更换及退出协调测试通过。隔离实际 WKWebView 六组通过：应用刷新、浏览器清除菜单、保存反馈、退出草稿确认、配置导入、双语 UI。配置导入初次夹具未初始化导致失败，按生产 load 流程初始化后通过，未降低断言。

arm64 / x86_64 均从全新中性目录完整 Release 源码构建为 1.0.2 / Build 43；各 101 个 Mach-O 架构检查、全部 Toolkit 与源码逐文件核对、ZIP CRC/普通文件逐字节比对、严格 ad-hoc 签名、仓库/App/ZIP 隐私扫描、SHA-256 通过。构建继续采用此前临时 poison-system-directories 兼容参数，未修改第三方构建告警策略。用户的 Build 42 反馈不代替 Build 43 新增刷新行为的真机验证；本轮未替换 /Applications 中 App 或清理个人数据。发布与线上回核随后追加。

### 1.0.2 发布完成

GitHub v1.0.2 / Build 43 已作为 Latest 正式发布，tag 指向 3e82b4d；arm64 与 x86_64 各 DMG/ZIP/SHA-256 共六个附件，全部公开下载与本地逐字节一致。Ed25519 feed 签名、真实发行 ZIP 校验及篡改拒绝通过；双架构 DMG 完整性通过。Pages 已部署 ff3c106，公开首页和签名 appcast 与源码逐字节一致。feed 继续仅向 arm64 提供更新，Intel 使用独立下载包。v1.0.0、v1.0.1 旧正式版保留；未覆盖旧附件、安装本机 App 或清理用户数据。本轮不包含通过公开 Sparkle 实际安装 Build 43 的验收，此前 Build 41 更新渠道实测记录保留。

公开 README、官网、双语安装说明、发行包 Read Me 与 Release 说明去掉过时的“未经过其他机器验证”/Intel 候选提示，不增加用户个人测试说明；签名及公证事实继续保留。未跟踪 HANDOFF.md 与独立 website/ 排除在全部提交之外。

## 1.0.2 Intel 更新源修复

用户在 Intel Build 42 检查更新时出现“Your Mac is too old / requires a new Apple silicon Mac”。根因是公开 feed 只列 ARM 更新项；Intel 安装包本身已发布。未重新打包 App，使用原有 1.0.2 / Build 43 ZIP 增加 Intel Ed25519 签名项。

核对 Sparkle 2.10.0 官方 SUAppcastDriver.m：filterSupportedAppcast 按 arm64HardwareRequirementIsOK 过滤，bestItemFromAppcastItems 同版本保留首项。因此固定同版本 ARM 受限项在前、Intel 无硬件限制回退项在后，不添加不受支持的 x86_64 hardwareRequirements。生成器强制双包、真实主程序架构与版本/Build/公钥一致；缺包、传反及重复架构拒绝且原 feed 不变。双包 CRC、SHA-256、签名与篡改拒绝及两种硬件选择回归通过。Intel 真机端本次检查更新/安装结果仍待用户复验；未修改系统权限或本机安装。

## 1.0.3 / Build 44 · 2026-10-14

按用户反馈，将未安装状态从行末移至应用名称后，在名称 label 内显示中文“（未安装）”或英文“ (Not installed)”，复用 var(--error) 与现有字号；安装后隐藏状态。应用启动、输入法、浏览器来源与剪贴板排除规则共用此显示，不改变配置或快捷键。

全部 Lua 回归与实际 WKWebView 六组回归通过，新增验证状态在名称内部、中英文括号/翻译、主题 error 色、重装隐藏及草稿保留；隔离布局预览已检查。颜色测试最初误用禁用的清除按钮作比较，改为直接比较主题 error 色；未降低断言。双架构全新中性目录 Release 构建为 1.0.3 / Build 44，各 101 个 Mach-O 架构、Toolkit 与源码、严格签名及隐私门禁通过；双包 ZIP CRC/普通文件逐字节核对通过。双架构更新源继续采用 ARM 优先、Intel 回退同版本项及防遗漏生成校验。旧包不覆盖，本机 App 和个人数据不改动。

此前 1.0.2 双架构更新源 772a13b 已部署成功，线上 appcast 与已签名源码逐字节一致；Intel 安装与更新的用户复验仍单独记录，不将静态分流校验写成 Intel 真机升级。

1.0.3 / Build 44 已作为 Latest 正式发布，tag 指向 db2f971。服务端六附件 SHA-256/大小与本地一致，全部公开下载逐字节回核通过；双架构更新源的 ZIP CRC、SHA-256、Ed25519 签名与篡改拒绝以及双架构 DMG 完整性均通过。旧正式版全部保留。本次未安装或替换本机 App，未改个人配置、权限和剪贴板数据。官网和双架构更新源随 main 发布，线上部署回核独立执行。

## 1.0.4 / Build 45 · 2026-10-14

按用户要求统一设置错误：删除顶部快捷键冲突汇总、行内 field-error 和 save-error 文字，字段保留 aria-invalid 红框，原因由底部状态栏显示。相同类型错误去重，多种字段错误显示简短汇总；后端失败按页面保留，切页不串页，返回页面恢复，编辑/取消/成功保存后清除。重复添加应用提示也进入底部。保留原校验、保存阻止、首个错误定位、草稿及双语反馈。

实际 WKWebView 七组通过：底部反馈、跨模块冲突、退出草稿确认、应用刷新、浏览器菜单、配置导入、双语 UI。新增四项相同快捷键全部红框且底部仅一句、不同错误汇总、域名冲突、后端失败页面隔离、编辑清除、保存阻止与中英文校验。布局预览确认四个红框及底部单条提示，无顶部/行间重复文字。双语旧夹具使用无修饰键 Z 导致新的错误提示优先显示；改为合法 Control+Z 草稿后通过，不改业务校验。全部 Lua、退出协调及隐私回归通过。双架构构建和公开包验证随后记录。

1.0.4 / Build 45 已正式发布为 Latest，tag 指向 9e4572d。全新双架构源码构建，各 101 个 Mach-O、源码资源、严格签名与隐私检查通过。双架构 ZIP 普通文件逐字节/CRC/SHA-256、更新签名/篡改拒绝/架构分流及 DMG 完整性通过；六附件服务端 SHA-256 与全部公开下载逐字节回核通过。旧正式版保留，未替换本机 App，未改个人配置/权限/剪贴板数据。官网与双架构更新源随 main 部署，线上资源单独回核。


## 本机安装版最终复验与文档收尾 · 2026-10-14

本机 /Applications/Nivlet.app 为 1.0.4 / Build 45 arm64，全部普通文件集合/内容与发行 App 一致，Toolkit 与当前源码逐文件一致，严格签名通过。以本机安装资源副本及合成配置在隔离实际 WKWebView 重跑七组回归，全部通过；全部 Lua、退出协调/应用更换 JS、隐私五项、Dock 策略及安装 JS 语法检查通过。当前双架构 feed/ZIP/SHA-256/签名/篡改拒绝通过；线上首页与 feed 再次逐字节匹配源码，Release 仍为六附件正式版。

本机真实关于页显示 Build 45；手动检查更新返回“您使用的就是最新版！Nivlet 1.0.4是当前的最新版本。”。辅助功能在此前用户明确授权移除旧权限条目、重新添加 /Applications/Nivlet.app 后恢复，本次只读确认通用页显示“辅助功能权限已开启”，未再次更改系统权限。未访问个人剪贴板内容、未向个人设置注入测试或保存配置。

审计 d2ad962 至 c59eaa0 的应用状态刷新、未安装标签、底部错误、草稿/退出与双架构更新生成逻辑，未发现范围内新的可确认 P0/P1/P2；详见 CODE-REVIEW-2026-10-14.md。文档修正旧交接、开发/英文使用基准、导航及权限恢复步骤；本次不修改业务代码、不重新打包或发布。Intel Build 45 实际升级及其他硬件/macOS 不纳入本轮已通过结论。


## 1.0.5 / Build 47 · 2026-10-14

用户确认本机 Build 46 复制提示修复整体使用正常，授权正式发布。复制成功使用底部状态栏且 3 秒消失，移除历史工具栏提示行；失败/预览/刷新统一反馈，隐藏剪贴板页不显示迟到响应。实际 WebView 八组、全部 Lua、退出协调/应用更换 JS 与隐私回归通过；复制回归验证提示出现/消失时列表 top、工具栏高度及滚动位置不变，页面隔离和草稿保持。双语旧测试在其他页模拟剪贴板状态，已调整在剪贴板页验证，与新页面隔离规则一致。

正式 Build 47 双架构从全新中性目录源码构建，与本机资源更新的 Build 46 测试候选区分。此次不自动安装、不改系统权限或读取个人剪贴板内容；发布验证随后补充。

1.0.5 / Build 47 已正式发布为 Latest，tag 指向 6b21bab。arm64/x86_64 各 101 个 Mach-O、版本/Build、Toolkit 源码一致性、严格签名、仓库/App/ZIP 隐私检查通过；ZIP CRC/全部普通文件逐字节、SHA-256、双架构更新分流、签名/篡改拒绝和 DMG 完整性通过。六附件服务端 SHA-256 与公开下载逐字节回核通过；首次回核时下载尚未完成，待下载进程成功退出后单独检查六文件大小、SHA-256 与内容，全部一致。旧版本保留，本机保持 Build 46 用户验收测试版，未自动替换或操作权限。线上首页与双架构 feed 随 main 部署并单独回核。


## 1.0.6 / Build 49 · 2026-10-14

用户授权将本机 Build 48 重复应用提示修复正式发布。修复前真实 WebView 回归复现提示被误存入 footerErrors；修复后使用3秒临时信息，切页清除且返回不恢复，仍定位/高亮原配置、保持草稿并让实际校验/保存错误优先。发布前九组实际 WebView、全部 Lua 和相关检查复验。正式双架构 Build 49 使用新中性目录源码构建，与资源更新的 Build 48 区分。

权限重授后 Intel 需彻底退出重开现象按用户决定仅记 P2，未确认架构差异或确切根因，见 KNOWN-ISSUES.md；本轮不修改权限实现。用户要求清理本轮测试产物，具体清单与确认结果另记；正式包、dSYM、验收证据与个人数据保留。


1.0.6 / Build 49 已正式发布为 Latest，tag 指向 49687b3。双架构各101个 Mach-O、版本/Build/Toolkit源码一致性、严格签名、仓库/App/ZIP隐私、ZIP CRC/普通文件逐字节、SHA-256、更新签名/篡改拒绝/双架构分流、DMG完整性通过。六附件服务端SHA-256及全部完成下载逐字节匹配，在线首页与双架构feed逐字节匹配源码。未自动安装；本机仍为Build48。

按用户确认的21条路径精确清理约200.6MiB：旧Build42/46测试候选及Build42附件、Build45安装资源QA副本、两份去签名比对副本、本轮命名的临时程序/脚本/模块缓存。删除前确认QA程序未运行，删除后确认21条路径不存在、本机Build48的Info.plist不变、保留安装包哈希不变；当前Build48候选App/dSYM与包、所有正式包和正式dSYM、发行/下载验收证据保留。个人配置、剪贴板数据、默认浏览器和系统权限未操作。清理明细在本地build/release-1.0.6-verification/cleanup-{proposed,result}.json，不提交本地路径明细。已清理的临时夹具可从源码重新生成。

权限重授现象按P2-AX01待查，不实施；后续开发首项仍A15导入预览，暂不扩展其他功能。导读、基准、计划、已知问题、双语安装/使用、分发/开发与交接同步完成。


## 1.0.6 / Build 51 · Developer ID 权限恢复候选 · 2026-10-21

本轮不是公开发行：GitHub 最新 Release、tag 和 feed 仍为此前 ad-hoc Build 49，附件未替换。ARM/Intel 候选复用 Build 49 原生程序（匹配 dSYM 仍对应原程序 UUID），只更新 Toolkit 和 Info.plist Build 后重签名；不声称原生源码全新构建。

源码：统一窗口保存、导入、窗口操作与直接粘贴的权限门禁；系统信任值为 false 时也进行 Finder 跨进程探测；不一致时保持拒绝并提供退出重开引导。接入 Runtime 授权状态通知；普通退出复用已有草稿保护；权限区域仅保留文字引导，按用户要求不新增退出按钮，并提示未持久化历史退出清空。全部 Lua 回归、真实 WKWebView 中英权限状态转换、通知不覆盖草稿、退出弹窗和取消、JS 语法、隐私扫描及 diff 检查通过。

双架构 App 已由同一 Developer ID 签名并通过 Apple 公证，凭证附加、严格签名及 Gatekeeper 返回 Notarized Developer ID。本机先从已公证 Build 49 切换为 Build 50，随后备份 Build 50 并替换为 ARM Build 51，实际运行路径与版本核对通过；启动及点击重新检测均显示辅助功能权限已开启。此次升级未删除重加授权或操作系统权限；原有设置仍加载，未清理个人数据目录。此前用户已确认 Build 49 授权重启后其他功能正常，但此反馈不代替 Build 51 全功能实测。

边界：工具未主动撤销权限；用户主动重授后观察到状态不同步，重启后恢复；尚不能保证任意重新授权均可免重启恢复。未在 Intel 硬件运行新候选，未通过公开 Sparkle 更新渠道安装 Build 51。系统是否保留授权取决于稳定签名要求，公证本身不是授权保留机制。候选及本机替换证据保存在本地 build/permission-recovery51/，私钥及公证密码未导出或纳入仓库。

用户随后主动重新操作了辅助功能授权，Build 50 旧进程显示信任与实际 AX 访问不同步；用户确认属于重新授权后的场景。按用户要求移除权限区域额外退出按钮后重新生成并安装 Build 51。Build 51 正常启动、版本核对和权限重新检测通过，未再次删除重加权限。Build 49 → 50 的普通签名升级沿用授权实测与此次重新授权后的进程恢复分开记录，不混同。

最终包核验：Build 51 双架构 App 与 DMG 均 Accepted，App/DMG 凭证附加及 Gatekeeper 返回 Notarized Developer ID；ZIP CRC、源码资源、挂载 DMG 的普通文件逐字节核对、安装版 383 个文件与 ARM 候选一致、跨 Build designated requirement 一致性均通过。四个最终附件的 SHA-256 已生成；App、ZIP 和仓库隐私扫描通过。本轮只推送源码、测试及文档，不上传候选附件或改变公开 feed。

## 2026-10-21 follow-up: live permission false negative

The earlier Build 51 restart guidance was not a proven recovery requirement. In the same running process, the trust Boolean returned false while Finder AXWindows returned a table successfully; the user also confirmed window shortcuts still worked. The corrected detector accepts successful cross-process AXWindows access (including an empty list), preserves explicit API-disabled denial, and removes the inferred restart requirement. Existing recheck, focus refresh and permission notifications remain.

All Lua tests, leave-guard tests and the real bilingual settings WebView regression passed. Loading only the corrected snapshot function into the existing process changed General to granted without a restart; clicking Recheck then confirmed granted. This was a live diagnostic validation, not a replacement of the signed installed bundle. The installed bundle remains Build 51 and will revert to its packaged detector on relaunch until a new signed package is installed. Permission revocation and transient failures are covered by mocks; another physical toggle cycle and Option-paste were not repeated in this follow-up. No release or push was performed.

### Build 52 packaging and local installation

ARM and Intel apps are Developer ID signed, Apple notarized and stapled. Build 52 reuses the Build 49 native executable with the corrected Toolkit resources. The installed ARM bundle matches all 383 ordinary files of the notarized candidate; the designated requirement matches Build 51. General shows granted, Recheck confirms granted, and About shows 1.0.6 / Build 52. No Accessibility permission settings were changed during this installation. Previous installed Build 51 is retained as a local backup. This supersedes the preceding “not packaged” status; no GitHub release or push was performed. A fresh permission-toggle cycle and Intel hardware execution were not repeated.

## 1.0.7 / Build 53 · 正式签名发布 · 2026-10-21

本次发行承接 Build 52 权限误报修复，版本递增为 1.0.7 / Build 53，保留旧正式版。复用 Build 49 原生程序/dSYM，仅更新 Toolkit 及版本元数据后 Developer ID 重签名；不称为原生全新编译。双架构 App 已 Apple 公证 Accepted、附加票据且 Gatekeeper 接受。DMG、公开下载和更新源发布回核将在完成后补记。

全部 Lua、leave guard、launcher replacement、shortcut capture、tab boundary、privacy、第三方 81 份许可及 browser URL-only 回归通过；真实中英文设置 WebView 权限转换、草稿保留及普通退出保护通过。仓库隐私检查通过。未新增功能或改系统权限；本机仍为已验收的 Build 52。旧版本用户 Intel 实测反馈沿用其原范围，不代替 Build 53 最新包真机运行。

Build 53 最终包验证：每架构 101 个 Mach-O 均为正确的单架构；双架构 App/DMG 公证 Accepted、票据验证、严格签名与 Gatekeeper 通过。DMG 校验及只读挂载 App 逐文件比对通过，ZIP CRC、全部普通文件与候选一致、Toolkit 与源码一致；六附件最终 SHA-256 已生成。双架构 feed 已按 ARM 优先、Intel 回退生成，版本、Build、实际主程序架构、Ed25519 校验与篡改拒绝均通过。

发布回核：v1.0.7 已作为正式 Latest 发布，tag 指向 5137915；1.0.6 及旧正式版保留。六附件服务端 digest 与本地一致，随后从公开下载地址完整下载六文件，逐个 SHA-256 与最终本地文件相同。GitHub Pages 构建成功，线上 index.html 和双架构 appcast.xml 与 docs/ 源码逐字节相同。main 和 tag 远端核对通过。相关中英文说明、官网、推广用语及个人知识库三个导航/项目笔记已同步。本机仍为 Build 52，无系统权限或数据清理操作；没有把包级检查写成最新 Intel 真机验证。

本机更新入口回核：在已安装 Build 52 的关于页点击“检查更新”，真实 Sparkle 窗口成功提示 1.0.7 可下载，并显示正式签名、公证和权限修复的中英文说明。点击“稍后提醒我”返回；没有下载或安装、没有改变版本和权限。此项验证更新发现与展示，不等同完整更新安装/回滚验收。
