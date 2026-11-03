#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runtime_dir=$1
test "$(git -C "$runtime_dir" rev-parse HEAD)" = 1469832361b4c3687ec7d589c1b4efe4d3b742ee
while IFS= read -r patch; do
    [ -n "$patch" ] || continue
    git -C "$runtime_dir" apply --check "$project_dir/patches/$patch"
    git -C "$runtime_dir" apply "$project_dir/patches/$patch"
done < "$project_dir/patches/series"
cp "$project_dir/Hammerspoon-Downstream.xcconfig" "$runtime_dir/Hammerspoon-Downstream.xcconfig"
cp "$project_dir/Native/Nivlet.entitlements" "$runtime_dir/Hammerspoon/Hammerspoon.entitlements"
cp "$project_dir/Native/keep_awake.h" "$runtime_dir/extensions/caffeinate/nivlet_keep_awake.h"
