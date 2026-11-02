#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
upstream_dir="$project_dir/vendor/hammerspoon"
if [ -e "$upstream_dir" ]; then
    echo "Runtime directory already exists; refusing overwrite." >&2
    exit 1
fi
mkdir -p "$project_dir/vendor"
git clone --depth 1 --branch 1.1.1 https://github.com/Hammerspoon/hammerspoon.git "$upstream_dir"
test "$(git -C "$upstream_dir" rev-parse HEAD)" = 1469832361b4c3687ec7d589c1b4efe4d3b742ee
git -C "$upstream_dir" apply --check "$project_dir/patches/runtime-isolation.patch"
git -C "$upstream_dir" apply "$project_dir/patches/runtime-isolation.patch"
git -C "$upstream_dir" apply "$project_dir/patches/xcode-compatibility.patch"
git -C "$upstream_dir" apply "$project_dir/patches/branding.patch"
git -C "$upstream_dir" apply "$project_dir/patches/general-appearance.patch"
git -C "$upstream_dir" apply "$project_dir/patches/browser-startup.patch"
cp "$project_dir/Hammerspoon-Downstream.xcconfig" "$upstream_dir/Hammerspoon-Downstream.xcconfig"

git -C "$upstream_dir" apply "$project_dir/patches/single-settings.patch"
git -C "$upstream_dir" apply "$project_dir/patches/menu-image-visibility.patch"

git -C "$upstream_dir" apply "$project_dir/patches/browser-sender.patch"

git -C "$upstream_dir" apply "$project_dir/patches/browser-background.patch"

git -C "$upstream_dir" apply "$project_dir/patches/dock-settings-lifecycle.patch"

git -C "$upstream_dir" apply "$project_dir/patches/settings-title-icon.patch"

git -C "$upstream_dir" apply "$project_dir/patches/nivlet-updater.patch"

git -C "$upstream_dir" apply "$project_dir/patches/settings-draft-guard.patch"


git -C "$upstream_dir" apply "$project_dir/patches/update-recovery.patch"


git -C "$upstream_dir" apply "$project_dir/patches/keyboard-focus.patch"


git -C "$upstream_dir" apply "$project_dir/patches/browser-url-only.patch"


git -C "$upstream_dir" apply "$project_dir/patches/browser-file-url.patch"


cp "$project_dir/Native/Nivlet.entitlements" "$upstream_dir/Hammerspoon/Hammerspoon.entitlements"

git -C "$upstream_dir" apply "$project_dir/patches/nivlet-keep-awake.patch"
cp "$project_dir/Native/keep_awake.h" "$upstream_dir/extensions/caffeinate/nivlet_keep_awake.h"
