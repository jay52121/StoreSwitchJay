# Changelog

All notable changes to StoreSwitch are documented here.

## [0.2.1] - 2026-07-17

### Added

- Complete English and Simplified Chinese localization for the interface, alerts, validation errors, automation errors and Apple Events permission text.
- Automatic language selection from macOS preferences, with English as the fallback for unsupported languages.

### Fixed

- Detect the App Store password field by its locale-independent `AXSecureTextField` subrole instead of the localized accessibility description. This fixes false “password field did not appear” failures on Chinese macOS.

## [0.2.0] - 2026-07-16

### Added

- Native SwiftUI account list, editor, notes and region labels.
- macOS Keychain storage for Apple ID credentials.
- App Store sign-out and sign-in automation with manual 2FA handoff.
- Recovery flow for credentials created by early ad-hoc builds.
- Stable local signing installer and reproducible public release packaging.
- StoreSwitch app icon and public project documentation.

### Security

- Credentials never enter command-line arguments, temporary files, the clipboard or application logs.
- Public release archives use a fixed designated requirement without embedding a maintainer development identity.
