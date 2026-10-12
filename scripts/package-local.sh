#!/bin/sh
# Local validation artifacts. Developer ID signing and notarization are separate release gates.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
configuration=${NIVLET_BUILD_CONFIGURATION:-Debug}
case "$configuration" in Debug|Release) ;; *) echo "Unsupported build configuration: $configuration" >&2; exit 1 ;; esac
if [ "$configuration" = Release ]; then
    default_data="$project_dir/build/PrivateRelease"
else
    default_data="$project_dir/build/DerivedData"
fi
derived_data=${NIVLET_DERIVED_DATA_PATH:-"$default_data"}
app_path="$derived_data/Build/Products/$configuration/Nivlet.app"
version=$(cat "$project_dir/VERSION")
build=$(/usr/libexec/PlistBuddy -c Print:CFBundleVersion "$app_path/Contents/Info.plist")
test "$(/usr/libexec/PlistBuddy -c Print:CFBundleShortVersionString "$app_path/Contents/Info.plist")" = "$version"
codesign --verify --deep --strict "$app_path"
python3 "$project_dir/scripts/check-privacy.py" --repo "$project_dir"
python3 "$project_dir/scripts/check-privacy.py" --app "$app_path"
arch=$(lipo -archs "$app_path/Contents/MacOS/Nivlet" | tr ' ' '-')
output=${NIVLET_PACKAGE_OUTPUT:-"$project_dir/build/packages"}
mkdir -p "$output"
base="Nivlet-$version-build$build-$arch-local"
if [ "$configuration" = Release ]; then base="$base-release"; fi
stage=$(mktemp -d "$project_dir/build/package-stage.XXXXXX")
trap 'rm -rf "$stage"' EXIT HUP INT TERM
ditto "$app_path" "$stage/Nivlet.app"
ln -s /Applications "$stage/Applications"
printf 'Nivlet for Mac %s — 直接分发包 / Direct distribution build\n\n' "$version" > "$stage/安装说明-Read-Me.txt"
cat >> "$stage/安装说明-Read-Me.txt" <<'TXT'
仅支持 Apple Silicon Mac（arm64），不支持 Intel Mac（x86_64/x86）。
将 Nivlet.app 拖入 Applications 后打开。无需另装 Hammerspoon。
在通用设置配置外观和语言；窗口、剪贴板、输入法、浏览器及应用快捷启动按需开启。
窗口管理和 Option 直接粘贴需要在系统设置中允许辅助功能。
配置与历史保存在本机；升级时只替换 App，不删除数据目录。
此包使用开发签名，尚未经过 Developer ID 签名、公证与其他机器验收。

Apple Silicon Mac (arm64) only. Intel Mac (x86_64/x86) is not supported.
Drag Nivlet.app into Applications. No separate Hammerspoon installation is needed.
Enable modules in Settings. Window management and Option-paste require Accessibility permission.
Settings and history are stored locally. Updating the App does not require deleting its data.
This build has no Developer ID signature or notarization and has not passed cross-machine validation.
TXT
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$output/$base.zip"
python3 "$project_dir/scripts/check-privacy.py" --zip "$output/$base.zip"
hdiutil create -quiet -volname "Nivlet $version" -srcfolder "$stage" -ov -format UDZO "$output/$base.dmg"
(cd "$output" && shasum -a 256 "$base.zip" "$base.dmg" > "$base.sha256")
printf '%s\n' "$output/$base.zip" "$output/$base.dmg"
