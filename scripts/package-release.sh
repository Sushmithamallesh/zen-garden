#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
app_bundle="$project_root/dist/Zen Garden.app"
zip_path="$project_root/dist/Zen-Garden.zip"
dmg_path="$project_root/dist/Zen-Garden.dmg"
checksums_path="$project_root/dist/SHA256SUMS.txt"

if [[ ! -d "$app_bundle" ]]; then
  print -u2 "Build the app first with ./scripts/build-app.sh"
  exit 1
fi

codesign --verify --deep --strict "$app_bundle"

staging_directory="$(mktemp -d "$project_root/.build/ZenGardenRelease.XXXXXX")"
trap 'rm -rf "$staging_directory"' EXIT

rm -f "$zip_path" "$dmg_path" "$checksums_path"

ditto "$app_bundle" "$staging_directory/Zen Garden.app"
ln -s /Applications "$staging_directory/Applications"

ditto -c -k --sequesterRsrc --keepParent "$app_bundle" "$zip_path"
hdiutil create \
  -volname "Zen Garden" \
  -srcfolder "$staging_directory" \
  -ov \
  -format UDZO \
  "$dmg_path" >/dev/null

cd "$project_root/dist"
shasum -a 256 "Zen-Garden.dmg" "Zen-Garden.zip" > "$(basename "$checksums_path")"

print "$dmg_path"
print "$zip_path"
print "$checksums_path"
