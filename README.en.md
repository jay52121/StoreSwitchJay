<p align="center">
  <img src="docs/assets/storeswitch-icon.png" width="152" alt="StoreSwitch icon">
</p>

<h1 align="center">StoreSwitch</h1>

<p align="center">
  <a href="README.md">简体中文</a> · <strong>English</strong>
</p>

<p align="center">
  A native macOS utility for securely managing and switching multiple App Store accounts.
</p>

<p align="center">
  <a href="https://github.com/jackljp/StoreSwitch/releases/latest"><img src="https://img.shields.io/github/v/release/jackljp/StoreSwitch?display_name=tag&sort=semver" alt="GitHub release"></a>
  <img src="https://img.shields.io/badge/macOS-15.0%2B-111827" alt="macOS 15+">
  <img src="https://img.shields.io/badge/SwiftUI-native-2563EB" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-22C55E" alt="MIT License"></a>
</p>

## Why StoreSwitch?

If you use Apple IDs from multiple regions—for example, China, the United States, or Japan—installing region-specific apps usually means repeatedly opening the App Store, signing out, signing in, entering credentials, and handling two-factor authentication. StoreSwitch turns that repetitive flow into a small native utility while keeping credentials in macOS Keychain instead of scripts, configuration files, or the clipboard.

StoreSwitch **only changes the account used by the App Store**. It does not sign out of or modify the primary iCloud account on your Mac.

## Features

- Add, edit, and remove any number of App Store accounts
- Assign a display name, region, region code, and notes to each account
- Store Apple IDs and passwords only in macOS Keychain
- Confirm before switching to prevent accidental sign-outs
- Open the App Store, sign out, and fill in the selected account automatically
- Hand two-factor authentication, terms, and security checks back to the user
- Native SwiftUI interface with a Universal macOS build

## Security and privacy

StoreSwitch is designed to minimize credential exposure:

- Display names, regions, and notes are stored locally in `UserDefaults`
- Apple IDs and passwords are stored in macOS Keychain
- Credentials are never written to Git, logs, command-line arguments, temporary files, or the clipboard
- The automation script is rendered and executed only in memory
- The app does not upload account data and contains no analytics SDK

The source is available for inspection. See [SECURITY.md](SECURITY.md) for security reporting guidance.

## Installation

### Download a release

1. Open [Releases](https://github.com/jackljp/StoreSwitch/releases/latest) and download `StoreSwitch-v0.2.0-macos.zip`.
2. Extract the archive and move `StoreSwitch.app` to `/Applications` or `~/Applications`.
3. If macOS blocks the first launch, right-click the app in Finder and choose **Open**.

The current public build is not Apple-notarized, so macOS may show an unidentified developer warning. After verifying the download source, you can also run:

```bash
xattr -dr com.apple.quarantine /Applications/StoreSwitch.app
open /Applications/StoreSwitch.app
```

### Build from source

You need Xcode, XcodeGen, and macOS 15 or later:

```bash
git clone https://github.com/jackljp/StoreSwitch.git
cd StoreSwitch
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
bash scripts/install.sh
```

The installer prefers a valid local Apple Development signing identity. You can select another identity with `STORESWITCH_SIGNING_IDENTITY`. If no development certificate is available, it uses a local ad-hoc signature with a fixed designated requirement.

## Usage

1. Open StoreSwitch and click **新增账号** (Add Account).
2. Enter a display name, region, Apple ID, password, and optional notes.
3. Select an account and click **切换到这个账号** (Switch to This Account).
4. On the first switch, allow StoreSwitch under **System Settings → Privacy & Security → Accessibility**.
5. Allow control of System Events or the App Store if macOS asks.
6. Complete any two-factor authentication, terms, or security checks in the App Store window.

If you upgraded from an early ad-hoc build and see Keychain error `-25293`, edit or switch the account again, re-enter the Apple ID and password once, and save. StoreSwitch 0.2 includes a recovery flow for this case.

## Build and test

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
xcodebuild -project StoreSwitch.xcodeproj -scheme StoreSwitch \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/storeswitch-derived-data \
  CODE_SIGNING_ALLOWED=NO test
```

Create a release archive:

```bash
bash scripts/package-release.sh
```

Artifacts are written to `dist/`. Public archives use an ad-hoc signature with a fixed designated requirement, which avoids embedding a maintainer development identity. The build is still not Apple-notarized.

## How it works

StoreSwitch reads the selected credentials from Keychain, renders an AppleScript in memory, and uses the macOS Accessibility API to operate the App Store menus and sign-in window. The real password never becomes a shell argument or a script file on disk.

Major App Store updates may change the accessibility hierarchy. If a menu or sign-in flow stops working, open an Issue with your macOS/App Store version and sanitized error text that contains no account information.

## Project structure

```text
StoreSwitch/
├── Resources/                  # App icon and AppleScript resource
├── Sources/                    # SwiftUI, Keychain, state, and automation
├── Tests/                      # Credential isolation, recovery, and templates
├── docs/assets/                # README icon assets
├── scripts/install.sh          # Local build, stable signing, and installation
├── scripts/package-release.sh  # Release packaging
└── project.yml                 # XcodeGen project definition
```

## Current limitations

- Requires macOS 15 or later
- Switches only the App Store account, not iCloud, Apple Music, or other Media & Purchases entry points
- Cannot bypass two-factor authentication, verification codes, terms, or security checks
- Depends on App Store accessibility elements and may need updates after major macOS releases
- The current release is not Apple-notarized

## Roadmap

- Developer ID signing and notarization
- Detect the currently signed-in App Store account
- End-to-end encrypted credential export and import
- More languages and accessibility improvements

## Contributing

Issues and pull requests are welcome. Never include real Apple IDs, passwords, Keychain exports, credential-bearing logs, or private screenshots in code, fixtures, Issues, or commits. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 jackljp

Apple, macOS, App Store, and Apple ID are trademarks of Apple Inc. StoreSwitch is an independent open-source project and is not affiliated with or endorsed by Apple Inc.
