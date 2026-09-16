#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
app_bundle="$project_root/dist/Zen Garden.app"
info_plist="$app_bundle/Contents/Info.plist"
executable="$app_bundle/Contents/MacOS/ZenGarden"

if [[ ! -d "$app_bundle" ]]; then
  print -u2 "Build the app first with ./scripts/build-app.sh"
  exit 1
fi

plutil -lint "$project_root/Info.plist" "$project_root/ZenGarden.entitlements" "$info_plist"
codesign --verify --deep --strict "$app_bundle"

bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info_plist")"
minimum_system="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$info_plist")"
url_scheme="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "$info_plist")"
menu_bar_only="$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$info_plist")"

[[ "$bundle_identifier" == "com.sushmithamallesh.zengarden" ]]
[[ "$minimum_system" == "13.0" ]]
[[ "$url_scheme" == "zengarden" ]]
[[ "$menu_bar_only" == "true" ]]
[[ -x "$executable" ]]

resource_bundle="$app_bundle/Contents/Resources/ZenGarden_ZenGarden.bundle"
for required_resource in \
  Blocked.html \
  Inter-OFL.txt \
  InterVariable.ttf \
  InterVariable.woff2 \
  ZenGardenHero.png \
  ZenGardenHeroBrowser.jpg; do
  if [[ ! -f "$resource_bundle/$required_resource" \
        && ! -f "$resource_bundle/Contents/Resources/$required_resource" ]]; then
    print -u2 "Missing packaged resource: $required_resource"
    exit 1
  fi
done

"$project_root/scripts/package-release.sh" >/dev/null
(
  cd "$project_root/dist"
  shasum -a 256 -c SHA256SUMS.txt
)

print "Verified Zen Garden app, DMG, ZIP, resources, metadata, signature, and checksums."
