# 2026-10-13 代码复审 · Build 40

## 结论

本轮在已修复两项菜单状态问题及再次唤起跳页问题后复审，未发现新的可确认 P0/P1/P2 缺陷。此结论限定于下述源码差异和验证，不等于完整跨机器发布验收。未提交、推送或修改业务代码。

## 范围

对比 `d47a290` 至当前工作区，包括当天本地提交 `30ec30e` 的 Intel 构建支持及未提交修改。审计前共 13 个变更/新增文件：

- `Toolkit/init.lua`：浏览数据桥接、图标数据、请求编号回传、已有设置窗口再次唤起保留页面。
- `Toolkit/settings.html`：标题右侧按钮、同宽图标菜单、权限请求与状态生命周期；原按钮保持自然宽度。
- `Toolkit/modules/browser_data.lua`：仅支持 Safari / Chrome，权限检查、浏览器启动、清除窗口入口及超时。
- `Toolkit/modules/translations.lua`：新功能中英提示。
- `tests/browser_data.lua`、`tests/browser_data_ui.js`、`tests/runtime.lua`：对应功能与根因回归。
- `scripts/build-dev.sh`、`scripts/optimize-app.py`、`scripts/package-local.sh`：目标架构选择、Mach-O 裁剪及匹配 dSYM 验证、按架构打包说明。
- `ROADMAP.md`、`documentation/DEVELOPMENT.md`、`documentation/VALIDATION.md`：截图撤回、架构构建和本轮验收记录。

未跟踪的独立 `website/` 排除在本轮范围外。本报告是额外新增的审计产物。

## 三项修复复核

1. 权限刷新丢失菜单焦点：浏览器列表/名称/图标签名不变时不重建节点。实际 WebView 验证节点和焦点保持。
2. 切页残留菜单及延迟响应误打开：切离浏览器页关闭菜单并取消待处理打开请求；递增 requestID 区分响应。验证返回不自动展开、隐藏页晚到响应、新旧请求交错。
3. Option+H 再次唤起跳回通用：原 Runtime reopen 回调总传入 generalSection；现在已有窗口时不发送切页指令，首次打开仍进入通用。Runtime 根因回归修改前失败、修改后通过；此前本机从 Finder 按 Option+H 返回后仍为浏览器页。

## 影响范围和清理

- 其余七个设置页 HTML 与 `30ec30e` 逐段一致，全部原有 CSS 保留，包括无边框重新检测样式。
- 浏览器分流业务模块、窗口、剪贴板、输入法、系统信息、应用启动业务模块没有本轮修改；共用设置桥接和页面切换经相关回归复核。
- 前几版常驻选择框、选择记忆 API/桥接字段及旧样式已从源码清除；未改变个人配置或删除用户数据。
- 没有新增网络上传、遥测或直接删除浏览记录。最终清除仍由用户在浏览器确认。
- 本机 /Applications/Nivlet.app 为 Build 40，内嵌 Toolkit 与当前源码逐文件一致。

## 本轮验证

- 全部现有 Lua 测试通过，含浏览器清除权限/白名单/启动/焦点/超时及 Runtime reopen。
- 实际 WKWebView 五组回归通过：浏览数据菜单、保存反馈、离开确认、配置导入导出 UI、中英切换。
- 浏览数据回归覆盖图标规格、按钮与菜单左右边缘/宽度、键盘选择/关闭、权限先行、草稿保留、失败恢复、无浏览器状态、焦点刷新及过期响应。
- 仓库隐私扫描、JS/shell 语法、git diff --check、已安装 App 严格签名及 Build 40 ZIP CRC 通过。

## 验证边界

- Safari 原生清除窗口的完整操作与非中英文菜单、其他 macOS / Intel 真机仍未全面验收；Chrome 曾核对进入 clearBrowserData 页面，没有执行最终清除。
- Build 36–40 复用 Build 35 的原生二进制及 dSYM，更新 Toolkit 和版本号后重签名，没有重新编译原生代码。
- Build 35 当时使用临时 xcconfig 保留 Xcode 27 第三方运行时 poison-system-directories 警告为警告；正式发布前仍需独立处理构建兼容性。
- 当前本地包为 ad-hoc 签名，Developer ID / 公证及跨机器安装属于既有发布边界。
