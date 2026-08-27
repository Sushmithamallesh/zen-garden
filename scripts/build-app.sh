#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"

mkdir -p "$project_root/.build/module-cache"
export CLANG_MODULE_CACHE_PATH="$project_root/.build/module-cache"

# Some Command Line Tools installations retain an older compatible SDK beside
# the active one during an update. Prefer Xcode's selected SDK when Xcode is
# installed; otherwise use the known-compatible fallback when it is present.
if [[ ! -d /Applications/Xcode.app && -d /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk ]]; then
  export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
fi

swift build -c release --disable-sandbox
binary_directory="$(swift build -c release --disable-sandbox --show-bin-path)"
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

resource_bundle="$binary_directory/ZenGarden_ZenGarden.bundle"
if [[ -d "$resource_bundle" ]]; then
  cp -R "$resource_bundle" "$app_bundle/Contents/Resources/"
fi

packaged_resources="$app_bundle/Contents/Resources/ZenGarden_ZenGarden.bundle"
for required_resource in Blocked.html ZenGardenHero.png ZenGardenHeroBrowser.jpg; do
  if [[ ! -f "$packaged_resources/$required_resource" ]]; then
    print -u2 "Missing packaged resource: $required_resource"
    exit 1
  fi
done

chmod 755 "$app_bundle/Contents/MacOS/ZenGarden"
codesign \
  --force \
  --deep \
  --sign - \
  --entitlements "$project_root/ZenGarden.entitlements" \
  "$app_bundle" >/dev/null

print "$app_bundle"
