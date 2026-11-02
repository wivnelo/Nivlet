# Nivlet 2.0.1 · Build 61

macOS 13.0+ · Apple Silicon (arm64) only · Developer ID signed and Apple notarized.

## 简体中文

- 通用设置新增“保持唤醒”和“保持屏幕长亮”，默认关闭。先开启保持唤醒，才可启用屏幕长亮；使用“保存全部设置”生效，取消保留已保存状态。关闭总开关或退出时只释放 Nivlet 自己的保活。
- 统一已安装 Safari、Chrome、Firefox、Edge、Brave 的名称、图标与能力信息；三个浏览器选择框保留原生下拉，在旁边显示选中浏览器图标。新增 Brave 原生清除浏览数据入口，与 Safari、Chrome 一样仅打开确认界面，不自动清除。
- 移除不再需要的 MAC 地址展示、对应开关和“系统已隐藏”占位。IPv4、IPv6、网速及其他系统信息保持不变，兼容旧配置中的 MAC 字段。
- “保持屏幕长亮”采用最终名称，两条辅助说明已移除；简中、繁中、英文、日文同步。沿用八页设置、全局保存及取消行为。

保持唤醒仅防止闲置系统休眠，屏幕仍可按系统设置熄灭；屏幕长亮额外防止闲置熄屏，可能推迟依赖熄屏的自动锁定。不调节亮度，不修改系统永久电源或安全设置，不绕过锁屏密码。

## English

- General settings adds **Keep awake** and **Keep display on**, both off by default. Keeping the display on requires Keep awake. Changes use Save All Settings; cancelling retains saved values. Disabling Keep awake or quitting releases only Nivlet's own power assertions.
- Shares installed-browser names, icons and capabilities across Safari, Chrome, Firefox, Edge and Brave. The three native browser selectors now show the selected browser's icon beside them. Brave joins Safari and Chrome in opening the browser's own clear-data confirmation; Nivlet never confirms deletion for you.
- Removes the unused MAC address row, its display switch and hidden-address placeholder. IPv4, IPv6, network speed and other system information remain unchanged; older configuration files containing the MAC field remain accepted.
- Simplifies the two power-setting rows by removing their helper descriptions and finalizing the Chinese display label. All four interface languages retain the existing eight-page layout, global save and cancel behavior.

Keep awake prevents idle system sleep while allowing normal display sleep. Keep display on additionally prevents idle display sleep and may delay locks that depend on the display turning off. It does not adjust brightness, change persistent power/security settings or bypass a lock-screen password.

## Downloads / 下载

Choose either the DMG or ZIP. Both contain the same signed, stapled Build 61 app. Use the `.sha256` attachment to verify downloads. Version 1.0.8 / Build 55 remains the final Intel release; historical assets are retained.

## Verification / 验证

54 regression files and 408 isolated UI/layout checks passed, with independent code review. The final app and DMG passed notarization, stapling and Gatekeeper checks; all 101 embedded Mach-O files are arm64. Safari and Chrome confirmation/cancel paths were checked natively; Brave's confirmation and cancellation were confirmed manually by the user. The installed Build 61 retained all 31 preference keys without semantic changes during the final upgrade.

The screenshots and GIFs use the real settings frontend with synthetic data and simulated native responses. They are not native end-to-end recordings. Physical sleep/display/lock timing, other Mac/macOS combinations and a live Sparkle installation of Build 61 have not been claimed as tested. Signed-feed, archive-integrity and tamper-rejection checks are separate from live updater installation.

## Source and artifacts / 源码与产物

Product source: `9ddcbf9dd6ac951463a9c0c8ed929357c44996c9`. The release tag adds public documentation and media; it does not change product files. The notarized package was built from the identical validated product tree.

| Asset | SHA-256 |
| --- | --- |
| `Nivlet-2.0.1-build61-arm64.zip` | `bfa44d9803b5cb36d7c51a1d9fe65ea986dd20430bc1bd942f6d7a6eff04fc10` |
| `Nivlet-2.0.1-build61-arm64.dmg` | `8098ae35f0e10f184428561da6fba12dd4309109bc0013b5b005ef2ed7879a55` |

[Release](https://github.com/wivnelo/Nivlet/releases/tag/v2.0.1) · [Installation](INSTALLATION.en.md) · [使用指南](USAGE.md)

Public verification: `v2.0.1` resolves to `5cbdbbf98c154d55cc2120c5f2ceac1bf5372469`. All three public attachments were downloaded anonymously and match the accepted artifacts byte for byte; the downloaded app passes strict signing, stapling and Gatekeeper checks. ZIP: 11,400,025 bytes; DMG: 13,317,311 bytes. The 10 earlier releases and their asset metadata remain unchanged.

公开回核：三份附件匿名下载与已验收产物逐字节一致，下载 App 的严格签名、票据与 Gatekeeper 通过。正式 tag 对应上述提交，10 个历史版本及其附件信息保持不变。
