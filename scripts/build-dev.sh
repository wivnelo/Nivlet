#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
configuration=${NIVLET_BUILD_CONFIGURATION:-Debug}
architecture=${NIVLET_ARCH:-arm64}
case "$architecture" in arm64|x86_64) ;; *) echo "Unsupported architecture: $architecture" >&2; exit 1 ;; esac
derived_data=${NIVLET_DERIVED_DATA_PATH:-"$project_dir/build/DerivedData"}
case "$configuration" in Debug|Release) ;; *) echo "Unsupported build configuration: $configuration" >&2; exit 1 ;; esac
sh "$project_dir/scripts/preflight.sh"
upstream_dir="$project_dir/vendor/hammerspoon"
# Release xcconfig signs Hammerspoon/Hammerspoon.entitlements. Use the audited file.
cp "$project_dir/Native/Nivlet.entitlements" "$upstream_dir/Hammerspoon/Hammerspoon.entitlements"
python3 "$project_dir/scripts/prepare-icon.py"
cd "$upstream_dir"
scheme=Hammerspoon
set --
if [ "$configuration" = Release ]; then
    scheme=Release
    set -- -enableAddressSanitizer NO -enableUndefinedBehaviorSanitizer NO DEBUG_INFORMATION_FORMAT=dwarf-with-dsym
fi
xcodebuild -workspace Hammerspoon.xcworkspace -scheme "$scheme" -configuration "$configuration" -derivedDataPath "$derived_data" "$@" ARCHS="$architecture" ONLY_ACTIVE_ARCH=NO VERSION_INFO_BUILDER=nivlet COPY_PHASE_STRIP=NO STRIP_INSTALLED_PRODUCT=NO CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM= CODE_SIGN_IDENTITY= CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER=NO build
app_path="$derived_data/Build/Products/$configuration/Nivlet.app"
test -d "$app_path"
/usr/libexec/PlistBuddy -c Print:CFBundleIdentifier "$app_path/Contents/Info.plist" | /usr/bin/grep -qx dev.local.DesktopToolkit
mkdir -p "$app_path/Contents/Resources/Toolkit"
cp -R "$project_dir/Toolkit/." "$app_path/Contents/Resources/Toolkit/"
/usr/bin/sips -z 160 160 "$project_dir/assets/nivlet-icon.png" --out "$app_path/Contents/Resources/Toolkit/nivlet-icon.png" >/dev/null
cp "$project_dir/LICENSE" "$app_path/Contents/Resources/Toolkit/"
sh "$project_dir/scripts/prepare-updater.sh" "$app_path"
python3 "$project_dir/scripts/collect-notices.py" "$app_path/Contents/Resources/Toolkit/THIRD-PARTY-NOTICES.md"
xcrun clang -fobjc-arc -Wall -Wextra -Werror -arch "$architecture" -mmacosx-version-min=13.0 -framework Foundation "$project_dir/Native/system_probe.m" -o "$app_path/Contents/Resources/Toolkit/system-probe"
python3 "$project_dir/scripts/optimize-app.py" "$app_path" "$configuration" "$architecture"
# Ad-hoc signing is only for this local probe, not a distribution signature.
python3 "$project_dir/scripts/configure-url-types.py" "$app_path/Contents/Info.plist"
if [ "$configuration" = Release ]; then
    python3 "$project_dir/scripts/check-privacy.py" --app "$app_path"
fi
codesign --force --deep --sign - "$app_path"
if [ "$configuration" = Release ]; then
    # Main bundle only. Nested components keep the signatures from --deep.
    codesign --force --sign - --entitlements "$project_dir/Native/Nivlet.entitlements" "$app_path"
fi
codesign --verify --deep --strict "$app_path"
echo "Local $configuration build: $app_path"
echo "App has not been launched. Complete isolation review before running it."
