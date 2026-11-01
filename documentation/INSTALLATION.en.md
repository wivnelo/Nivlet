# Installation, updates and removal

Candidate: **1.0.9 / Build 56, not yet published**, macOS 13.0+, Apple Silicon (arm64) only. Final build, signing, notarization and acceptance gates must pass first. [简体中文](INSTALLATION.md)

The latest published release remains [1.0.8 / Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8), the **final Intel (x86_64) release**. Its downloads stay available. New versions no longer build or support Intel; no Intel hardware validation is claimed for 1.0.9.

## Signing status

The published 1.0.8 apps and DMGs are Developer ID signed, Apple notarized and stapled. The 1.0.9 arm64 candidate must complete the same final gates before publication. Sparkle update signatures independently protect archive integrity. Notarization does not grant Accessibility permission or mean App Store distribution.

## Install

1. Download a published DMG or ZIP from [GitHub Releases](https://github.com/wivnelo/Nivlet/releases/latest). Intel users should use [1.0.8 Build 55](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.8).
2. Open the DMG and drag `Nivlet.app` to Applications, or extract the ZIP and move the app to Applications. Eject the DMG; use only the installed copy.
3. Launch `/Applications/Nivlet.app`. A normal downloaded-app confirmation may appear.
4. Open Settings from the N menu bar icon. Enable the tools you need, configure rules and, in 1.0.9, click Save All Settings to save every changed page. No separate Hammerspoon installation is needed.

### Unexpected system warnings

Do not disable Gatekeeper or remove quarantine as a routine installation step. If macOS reports an unverified developer, damage, malware or a checksum mismatch, check the version, source and SHA-256, then report the exact message. Managed Macs may impose additional restrictions.

### Permissions and browser routing

Window management, Option-click paste and opening browser clear-data dialogs need Accessibility. In General, click Open Accessibility Settings and allow `/Applications/Nivlet.app` under Privacy & Security → Accessibility. Return to Nivlet for automatic detection or click Check Again. Clipboard recording, app launching and system information do not need this permission.

For browser routing, save rules first, then choose Nivlet as the system default browser. Nivlet forwards links to the configured real browsers; it does not render webpages. Verify routing by clicking links in another app. The default-browser action requests webpage protocols, without requesting text-file associations.

## Verify downloads

Once 1.0.9 is published, place its DMG, ZIP and `.sha256` file together, then run:

```sh
shasum -a 256 -c Nivlet-1.0.9-build56-arm64.sha256
```

Both archives should report OK. If you downloaded only one, the missing archive reports a missing-file error; inspect the result for the archive you have. Checksums do not replace Apple signing or notarization.

## Update or restore

From 1.0.9 onward, new updates target Apple Silicon only; Intel stays on 1.0.8 Build 55. Save or discard drafts and export saved configuration in General. Use About → Check for Updates and confirm installation, or quit Nivlet and replace the app in Applications manually. Updates are not installed silently. Keep the previous package for recovery; do not remove the user data directory.

Configuration and persisted history stay local. Nonpersistent clipboard history is cleared on exit; persisted entries remain subject to retention limits. Migrating from an older ad-hoc build may require reauthorization once. Permission carryover depends on the tested release and system. Return to General or click Recheck; live cross-app checks handle stale system trust values. If an old permission entry genuinely no longer works, remove the old Nivlet entry from the permissions list, add `/Applications/Nivlet.app` again with the + button, enable it, and click Check Again in Nivlet. This removes only the old permission entry, not the app or user data. Configuration exports do not contain clipboard history, system permissions, login items or the system default browser.

The app lives in `/Applications/Nivlet.app`; user data lives in `~/Library/Application Support/dev.local.DesktopToolkit`, with preferences in the `dev.local.DesktopToolkit` domain. Personal Hammerspoon data is separate. Do not assume older versions support a future configuration format when downgrading.

## Remove

If Nivlet is your default browser, switch back to Safari or another browser first. Disable launch at login, save, quit Nivlet and move the app to Trash. Moving the app does not erase settings or history; export/backup your data before deciding whether to remove it separately.

## Validation and reporting

Report the version/Build, macOS, chip, steps and exact error through [GitHub Issues](https://github.com/wivnelo/Nivlet/issues). Do not share private clipboard contents, full personal configurations or credentials.
