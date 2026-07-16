# Security Policy

StoreSwitch handles App Store credentials, so reports involving credential exposure or Keychain access are treated as security issues.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting for this repository. Do not include real Apple IDs, passwords, Keychain exports, authentication codes or screenshots containing private account data.

Include only the minimum reproduction details:

- StoreSwitch version
- macOS version
- whether the build came from Releases or was built locally
- sanitized error text
- steps that reproduce the issue without real credentials

## Security boundaries

- Credentials are stored as a generic password item in macOS Keychain.
- Display metadata is stored in local preferences and does not include credentials.
- Credentials are rendered into an in-memory AppleScript and are not written to disk, logs, shell arguments or the clipboard.
- StoreSwitch cannot bypass Apple two-factor authentication, terms, account locks or other security checks.

No software can guarantee the safety of a compromised Mac account. Keep macOS updated, use a login password and review Accessibility permissions regularly.
