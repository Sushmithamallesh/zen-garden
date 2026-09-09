#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"

universal=false
if [[ "${1:-}" == "--universal" ]]; then
  universal=true
  shift
fi

if (( $# > 0 )); then
  print -u2 "Usage: $0 [--universal]"
  exit 2
fi

if $universal && ! xcodebuild -version >/dev/null 2>&1; then
  print -u2 "A full Xcode installation is required for a universal release build."
  exit 1
fi

mkdir -p "$project_root/.build/module-cache"
export CLANG_MODULE_CACHE_PATH="$project_root/.build/module-cache"

# Some Command Line Tools installations retain an older compatible SDK beside
# the active one during an update. Prefer Xcode's selected SDK when Xcode is
# installed; otherwise use the known-compatible fallback when it is present.
if [[ ! -d /Applications/Xcode.app && -d /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk ]]; then
  export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
fi

build_arguments=(-c release --disable-sandbox)
if $universal; then
  build_arguments+=(--arch arm64 --arch x86_64)
fi

swift build "${build_arguments[@]}"
binary_directory="$(swift build "${build_arguments[@]}" --show-bin-path)"
app_bundle="$project_root/dist/Zen Garden.app"

case "$app_bundle" in
  "$project_root"/dist/*.app) ;;
  *)
    print -u2 "Refusing to replace an unexpected app path: $app_bundle"
    exit 1
    ;;
esac

rm -rf "$app_bundle"
mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"

cp "$binary_directory/ZenGarden" "$app_bundle/Contents/MacOS/ZenGarden"
cp "$project_root/Info.plist" "$app_bundle/Contents/Info.plist"

icon_temp_directory="$(mktemp -d "$project_root/.build/AppIcon.XXXXXX")"
iconset_directory="$icon_temp_directory/AppIcon.iconset"
mkdir -p "$iconset_directory"
trap 'rm -rf "$icon_temp_directory"' EXIT
swift "$project_root/scripts/render-app-icon.swift" \
  "$project_root/Sources/ZenGarden/Resources/ZenGardenHero.png" \
  "$iconset_directory"
iconutil -c icns "$iconset_directory" -o "$app_bundle/Contents/Resources/AppIcon.icns"

resource_bundle="$binary_directory/ZenGarden_ZenGarden.bundle"
if [[ -d "$resource_bundle" ]]; then
  cp -R "$resource_bundle" "$app_bundle/Contents/Resources/"
fi

packaged_resources="$app_bundle/Contents/Resources/ZenGarden_ZenGarden.bundle"
for required_resource in Blocked.html ZenGardenHero.png ZenGardenHeroBrowser.jpg; do
  if [[ ! -f "$packaged_resources/$required_resource" \
        && ! -f "$packaged_resources/Contents/Resources/$required_resource" ]]; then
    print -u2 "Missing packaged resource: $required_resource"
    exit 1
  fi
done

chmod 755 "$app_bundle/Contents/MacOS/ZenGarden"
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$CODESIGN_IDENTITY" \
    --entitlements "$project_root/ZenGarden.entitlements" \
    "$app_bundle" >/dev/null
else
  codesign \
    --force \
    --deep \
    --sign - \
    --entitlements "$project_root/ZenGarden.entitlements" \
    "$app_bundle" >/dev/null
fi

codesign --verify --deep --strict "$app_bundle"

if $universal; then
  architectures="$(lipo -archs "$app_bundle/Contents/MacOS/ZenGarden")"
  if [[ "$architectures" != *arm64* || "$architectures" != *x86_64* ]]; then
    print -u2 "Universal build is missing an architecture: $architectures"
    exit 1
  fi
fi

print "$app_bundle"
