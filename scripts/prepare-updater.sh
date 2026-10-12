#!/bin/sh
# Pinned official Sparkle distribution; private signing key stays in Keychain.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source="$project_dir/vendor/sparkle-2.10.0"
if [ ! -d "$source/Sparkle.framework" ]; then
    archive=$(mktemp /private/tmp/nivlet-sparkle.XXXXXX)
    trap 'rm -f "$archive"' EXIT HUP INT TERM
    curl -fL https://github.com/sparkle-project/Sparkle/releases/download/2.10.0/Sparkle-2.10.0.tar.xz -o "$archive"
    echo "c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c  $archive" | shasum -a 256 -c -
    mkdir -p "$source"
    tar -xf "$archive" -C "$source"
fi
test "$(/usr/libexec/PlistBuddy -c Print:CFBundleShortVersionString "$source/Sparkle.framework/Resources/Info.plist")" = 2.10.0
codesign --verify --deep --strict "$source/Sparkle.framework"
app_path=$1
rm -rf "$app_path/Contents/Frameworks/Sparkle.framework"
ditto "$source/Sparkle.framework" "$app_path/Contents/Frameworks/Sparkle.framework"
