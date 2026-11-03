#!/bin/sh

set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source="$project_dir/vendor/sparkle-2.10.0"
sh "$project_dir/scripts/fetch-sparkle.sh"
app_path=$1
rm -rf "$app_path/Contents/Frameworks/Sparkle.framework"
ditto "$source/Sparkle.framework" "$app_path/Contents/Frameworks/Sparkle.framework"
