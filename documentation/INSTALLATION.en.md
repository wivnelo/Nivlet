# Installation, updates and removal

Current release: **v1.0.2 / Build 43**, macOS 13.0+, Apple Silicon (arm64) or Intel (x86_64). [简体中文](INSTALLATION.md)

## Signing status

**Nivlet does not yet have an Apple Developer ID signature or Apple notarization.** The app uses ad-hoc signing. Signed update archives protect update integrity; they do not establish Apple developer identity or notarization. macOS may block first launch or require Accessibility permission again after an update.

## Install

1. Download either the DMG or ZIP from [this project's release](https://github.com/wivnelo/Nivlet/releases/tag/v1.0.2).
2. Open the DMG and drag `Nivlet.app` to Applications, or extract the ZIP and move the app to Applications. Eject the DMG; use only the installed copy.
3. Launch `/Applications/Nivlet.app`. If blocked because the developer cannot be verified or Apple cannot check it, and you trust the source, follow the steps below.
4. Open Settings from the N menu bar icon. Enable the tools you need, configure rules and click Save Settings. No separate Hammerspoon installation is needed.

### If first launch is blocked

After trying to open the app, go to **System Settings → Privacy & Security**, locate Nivlet's blocked-app notice and choose **Open Anyway**. Confirm Open and authenticate if prompted. This is an exception for the app; do not disable Gatekeeper globally. Managed Macs may restrict this option. See [Apple's guidance](https://support.apple.com/en-us/102445).

If macOS identifies malware, reports damage, or the download checksum does not match, stop and report the exact message. Do not assume every alert is caused by missing Developer ID signing.

### Permissions and browser routing

Window management, Option-click paste and opening browser clear-data dialogs need Accessibility. In General, click Open Accessibility Settings and allow `/Applications/Nivlet.app` under Privacy & Security → Accessibility. Return to Nivlet for automatic detection or click Check Again. Clipboard recording, app launching and system information do not need this permission.

For browser routing, save rules first, then choose Nivlet as the system default browser. Nivlet forwards links to the configured real browsers; it does not render webpages. Verify routing by clicking links in another app. The default-browser action requests webpage protocols, without requesting text-file associations.

## Verify downloads

Place the DMG, ZIP and `.sha256` file together, then run:

```sh
shasum -a 256 -c Nivlet-1.0.2-build43-arm64-local-release.sha256
```

Both archives should report OK. If you downloaded only one, the missing archive reports a missing-file error; inspect the result for the archive you have. Checksums do not replace Apple signing or notarization.

## Update or restore

Save or discard drafts and export saved configuration in General. Use About → Check for Updates and confirm installation, or quit Nivlet and replace the app in Applications manually. Updates are not installed silently. Keep the previous package for recovery; do not remove the user data directory.

Configuration and persisted history stay local. Nonpersistent clipboard history is cleared on exit; persisted entries remain subject to retention limits. Accessibility may need to be granted again for the new app. Configuration exports do not contain clipboard history, system permissions, login items or the system default browser.

The app lives in `/Applications/Nivlet.app`; user data lives in `~/Library/Application Support/dev.local.DesktopToolkit`, with preferences in the `dev.local.DesktopToolkit` domain. Personal Hammerspoon data is separate. Do not assume older versions support a future configuration format when downgrading.

## Remove

If Nivlet is your default browser, switch back to Safari or another browser first. Disable launch at login, save, quit Nivlet and move the app to Trash. Moving the app does not erase settings or history; export/backup your data before deciding whether to remove it separately.

## Validation and reporting

Report the version/Build, macOS, chip, steps and exact error through [GitHub Issues](https://github.com/wivnelo/Nivlet/issues). Do not share private clipboard contents, full personal configurations or credentials.
