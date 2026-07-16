#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
derived_data="${STORESWITCH_DERIVED_DATA:-/tmp/storeswitch-derived-data}"
destination_dir="${1:-$HOME/Applications}"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

cd "$project_dir"
xcodegen generate
xcodebuild \
  -project StoreSwitch.xcodeproj \
  -scheme StoreSwitch \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  build

source_app="$derived_data/Build/Products/Release/StoreSwitch.app"
signing_identity="${STORESWITCH_SIGNING_IDENTITY:-}"
if [[ -z "$signing_identity" ]]; then
  signing_identity="$(security find-identity -v -p codesigning | awk '/"Apple Development:/ { print $2; exit }')"
fi
if [[ -z "$signing_identity" ]]; then
  signing_identity="-"
fi

codesign_args=(--force --deep --sign "$signing_identity")
if [[ "$signing_identity" == "-" ]]; then
  codesign_args+=(--requirements '=designated => identifier "com.jplinx.storeswitch"')
fi
/usr/bin/codesign "${codesign_args[@]}" "$source_app"
/usr/bin/codesign --verify --deep --strict "$source_app"

mkdir -p "$destination_dir"
/usr/bin/ditto "$source_app" "$destination_dir/StoreSwitch.app"
/usr/bin/open -R "$destination_dir/StoreSwitch.app"

printf 'Installed StoreSwitch at %s\n' "$destination_dir/StoreSwitch.app"
