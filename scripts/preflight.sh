#!/bin/sh
set -eu
if ! xcodebuild -version; then
    echo "完整 Xcode 尚未就绪；可设置 DEVELOPER_DIR 指向 Xcode.app/Contents/Developer 后重试。" >&2
    exit 1
fi
command -v luac >/dev/null && luac -p "$(dirname "$0")/../Toolkit/init.lua"
echo "构建工具检查通过；此结果不代表 App 已构建或 Runtime 已验证。"
