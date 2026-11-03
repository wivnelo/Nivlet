#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
upstream_dir="$project_dir/vendor/hammerspoon"
expected=$(mktemp -d "${TMPDIR:-/tmp}/nivlet-runtime-XXXXXX")
cleanup() { git -C "$upstream_dir" worktree remove --force "$expected/runtime" >/dev/null 2>&1 || true; rm -rf "$expected"; }
trap cleanup EXIT
git -C "$upstream_dir" worktree add -q --detach "$expected/runtime" 1469832361b4c3687ec7d589c1b4efe4d3b742ee
sh "$project_dir/scripts/apply-runtime-patches.sh" "$expected/runtime" >/dev/null
drift=$(diff -rq -x .git -x build -x xcuserdata -x '*.xcuserstate' -x .DS_Store "$upstream_dir" "$expected/runtime" 2>&1 | grep -v 'Directory loop detected' | sed "s|$expected/runtime|<expected>|g" || true)
if [ -n "$drift" ]; then
    echo "$drift" >&2
    echo "vendor/hammerspoon does not match patches/series; rebuild it with scripts/fetch-runtime.sh." >&2
    exit 1
fi
echo "Runtime matches patches/series."
