#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
derived_data="${STORESWITCH_DERIVED_DATA:-/tmp/storeswitch-release-derived-data}"
output_dir="${1:-$project_dir/dist}"

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
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$source_app/Contents/Info.plist")"
work_dir="$(mktemp -d /tmp/storeswitch-release.XXXXXX)"
trap '/bin/rm -rf "$work_dir"' EXIT

release_app="$work_dir/StoreSwitch.app"
/usr/bin/ditto "$source_app" "$release_app"
/usr/bin/codesign \
  --force \
  --deep \
  --sign - \
  --requirements '=designated => identifier "com.jplinx.storeswitch"' \
  "$release_app"
/usr/bin/codesign --verify --deep --strict "$release_app"

mkdir -p "$output_dir"
archive="$output_dir/StoreSwitch-v${version}-macos.zip"
/bin/rm -f "$archive"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$release_app" "$archive"
(
  cd "$output_dir"
  archive_name="$(basename "$archive")"
  /usr/bin/shasum -a 256 "$archive_name" > "$archive_name.sha256"
)

printf 'Created %s\n' "$archive"
printf 'Created %s\n' "$archive.sha256"
