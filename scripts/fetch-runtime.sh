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
sh "$project_dir/scripts/apply-runtime-patches.sh" "$upstream_dir"
