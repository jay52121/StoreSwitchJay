# Contributing

Thanks for helping improve StoreSwitch.

## Before opening a pull request

1. Create a focused branch.
2. Update `project.yml` instead of hand-editing generated build settings.
3. Run `xcodegen generate` after project changes.
4. Run the unit tests with DerivedData under `/tmp`.
5. Keep real Apple IDs, passwords, Keychain data, authentication codes and private screenshots out of code, fixtures, Issues and commits.

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
xcodebuild -project StoreSwitch.xcodeproj -scheme StoreSwitch \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/storeswitch-derived-data \
  CODE_SIGNING_ALLOWED=NO test
```

Automated tests must use in-memory credentials and must not perform a real App Store account switch.
