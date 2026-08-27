#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$project_root/.build/module-cache"

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
if [[ ! -d /Applications/Xcode.app && -d /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk ]]; then
  sdk_path=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
fi

swiftc \
  -sdk "$sdk_path" \
  -module-cache-path "$project_root/.build/module-cache" \
  "$project_root/Sources/ZenGarden/Models.swift" \
  "$project_root/scripts/CoreTests.swift" \
  -o "$project_root/.build/zen-garden-core-tests"

"$project_root/.build/zen-garden-core-tests"

swiftc \
  -sdk "$sdk_path" \
  -module-cache-path "$project_root/.build/module-cache" \
  "$project_root/Sources/ZenGarden/Models.swift" \
  "$project_root/Sources/ZenGarden/SettingsStore.swift" \
  "$project_root/scripts/StoreTests.swift" \
  -o "$project_root/.build/zen-garden-store-tests"

"$project_root/.build/zen-garden-store-tests"
