> This guide describes the 2.0.0 / Build 57 candidate, not yet published. Requires macOS 13+ and Apple Silicon (arm64); 1.0.8 Build 55 remains the final Intel release.

# Nivlet User Guide

See [BASELINE](../BASELINE.md) for the final build, signing, notarization and acceptance status of the 2.0.0 candidate; results from earlier packages do not apply to it. Signing and notarization do not grant Accessibility access. See the [installation guide](INSTALLATION.en.md).

[Back to README](../README.md) · [简体中文](USAGE.md)

## Usage

### Clipboard

Enable and save recording in Settings → Clipboard, then copy new content. Open the menu bar clipboard icon: images appear above text, with thumbnails and hover previews; text entries have a T tile. Settings history remains in chronological order.

| Action | How |
| --- | --- |
| Copy an entry | Click it in the menu, then paste into the target app |
| Paste directly | Hold Option and click an entry to paste into the app active before opening the menu; requires Accessibility |
| Search | Use Search History… in the menu or the settings search field; text search only, no image OCR |
| Enlarge an image | Click its settings thumbnail, or focus it and press Enter or Space; press Escape or click outside the image bounds within the Nivlet window to close |
| Stop recording | Turn off Enable Clipboard History and save; enabling it again captures only new copies |
| Clear | Clear History… in the menu or settings; confirmation deletes history and cache **and clears the current system clipboard. This cannot be undone** |

Text history defaults to 50 entries, with choices from 10 to 100. Retention defaults to 30 minutes; choose 30 minutes, 1/2/4/8/12/24 hours or forever. Forever still respects the count limit. Image history holds up to 10 images, approximately 10 MiB each. Copied files are not recorded; image paste requires target-app support.

History is discarded on exit by default. Persistence across restarts is optional and uses a local plaintext cache. Duplicate content moves to the newest position; content copied before enabling or while recording is off is not backfilled. Turn recording off and save before copying sensitive information: app exclusions and filters cannot identify every sensitive item.

The menu shortcut has an enable switch, displays **⌘⇧ + V** and binds **Command-Shift-V**. It is enabled for a fresh installation or when shortcut configuration is missing; an explicit off setting persists across restarts. Existing custom shortcuts remain unchanged on startup and when saving unrelated settings. Changing this switch and saving binds Command-Shift-V when enabled or removes the binding when disabled. This shortcut is independent of recording, so existing history remains accessible when recording is off.

There is no separate Pause/Resume action. Enable Clipboard History is the only recording control; turning it off does not clear history, change retention limits or backfill content when enabled again.

Image previews open directly from thumbnails, with no separate open or close button. Clicking outside the image element’s bounds within the Nivlet window closes the preview; transparent pixels inside those bounds do not. Escape, focus restoration after asynchronous history refresh and prevention of click-through remain in place, without a global mouse permission.

### Window management and app launching

Enable the feature, configure key combinations and save. Supported keys include letters, numbers, arrows, Return, `=` and `-`. Letters display in uppercase; Backspace or Delete clears a binding. No shortcuts are assigned by default.

Window actions include halves, quarters, centering, thirds, a 3×3 grid, resizing by 40 points and moving to adjacent displays. Restore returns a window to its position before its first adjustment in the current run. Full-screen windows are unsupported; app minimum sizes may limit small layouts. Display moves do not wrap when no adjacent display exists.

Launcher rules open an app or bring it forward. Adding the same app again highlights the existing entry instead of creating a duplicate; input-source and browser source-app rules also check duplicates. Conflicting shortcuts within Nivlet block saving, but not every third-party shortcut can be detected.

### Browser routing

1. In Settings → Browser, choose a fallback browser and add domain or source-app rules.
2. Enable and save, then test links from another app. Settings no longer include the internal rule-test panel.
3. Click “Set as Default Browser…” and complete the macOS confirmation, then check again. If no prompt appears, use “Open Default Browser Settings…” and select Nivlet. Switch back to your previous browser to stop routing.

Priority is **domain → source app → fallback**. Domain rules match from top to bottom, support subdomains and can be reordered with ↑ / ↓. Installed Safari, Chrome, Firefox, Edge and Brave are supported. Web routing handles HTTP/HTTPS. Version 2.0.0 also forwards local `.html`/`.htm` files to the configured fallback browser, without applying domain or source-app rules. It does not add local PDF, TXT, image, XHTML or `.url`/`.webloc` parsing support; `mailto:`, `tel:` and application-specific protocols remain with their system handlers. Some apps do not expose an identifiable source; domain rules or the fallback apply in that case.

### System information and input sources

Choose network speed, CPU, memory, disk, IPv4, IPv6, MAC address, calendar date/weekday and lunar date in System Information, then save. Settings show current values; an information entry remains when network speed is hidden. Click addresses or dates in the menu to copy them. macOS may hide the MAC address; “Hidden by system” is unrelated to Accessibility permission.

In Input Sources, add an app and choose one of the system's enabled input sources, then enable and save. The rule applies when you next activate that app; unconfigured apps keep the current input source.

### Appearance, navigation and configuration

- Language: follow system, Simplified Chinese, English, Traditional Chinese or Japanese. Traditional Chinese uses Taiwan terminology; Hong Kong locales use that fallback rather than a separate Hong Kong localization. Appearance: follow system, light or dark. Both follow the system by default. Native menu resources follow the language macOS selects at launch; the in-app language preference does not force immediate language changes in AppKit menus or Sparkle dialogs.
- Hide or show the main N icon independently of clipboard and system information. The intended order is network speed → clipboard → N; positions also depend on macOS's saved state.
- Choose among eight pages in the left sidebar, with content on the right. Drag navigation items to reorder them; General stays first and About last. Navigation order saves automatically; other editable settings use Save All Settings.
- Launch at login takes effect after saving. Optional Command + L sleep is off by default; enabling it overrides the same shortcut in apps such as browsers.
- Export JSON or a default example from General → Configuration Backup & Migration. Review the replacement scope before importing. Omitted modules stay unchanged; failures restore the previous configuration. History, caches, permissions, login items and the system default browser are excluded. See the [configuration guide](CONFIGURATION.md) (Chinese).


## Saving changes and updating

An orange dot marks changed pages in the sidebar. Save All Settings and Command-S submit every changed page, including when the current page is unchanged or is About. Validation runs first; unchanged pages are not overwritten. Errors keep the relevant drafts and identify the failing page. Partial runtime failure is not reported as complete success. Cancel Page Changes affects only the current page; switching pages keeps all drafts. Reordered rules take effect after saving.

Use About → Software update to check manually, then confirm download, installation and restart. Resolve unsaved changes first. Background checks and silent installation are off by default. Checking and downloading use the network; configuration and clipboard history are not uploaded. Development signatures may require Accessibility permission again. Older builds without the updater can be replaced using the latest GitHub download.

## Interface and interaction

Settings use compact rows and aligned window/launcher shortcut fields. The clipboard menu shortcut now has only its enable switch. The “How to use the clipboard menu” disclosure and the description below General’s main-icon switch are removed; the main-icon switch, copying, Option-paste and privacy/exclusion controls remain functional. Drag the leading app icon to reorder app shortcut, input-source, browser source-app and clipboard-exclusion rules, then save. Filtering disables reordering. Newly added apps appear first; duplicate apps locate the existing rule without changing its order. Names use the macOS display name; unavailable apps keep their saved name or Bundle ID.

Browser app and domain rules are separate sections. Save rules, then test links from another app; the internal test panel has been removed. Select clipboard exclusions using Add App. Menu history clicks copy; Option-click pastes into the focused input and requires Accessibility. Tab/Shift-Tab navigate controls, Escape leaves shortcut capture or dismisses supported dialogs, and Command-S saves every changed page. Command-W/Q inside shortcut capture record the shortcut instead of closing or quitting.

## Permissions and validation

Unsaved pages have an orange dot in the sidebar. Saving or discarding clears the corresponding marker. General retains Check Again even when Accessibility is off and refreshes permission status when its window regains focus. Default-browser setup no longer requests unrelated document associations. Historical manual acceptance on the maintainer's setup does not establish the final 2.0.0 candidate's results. See the [installation guide](INSTALLATION.en.md) for the current Developer ID/notarization limitations.

## Interface consistency

Disclosure arrows share the same size, spacing and expanded direction. The excluded-app Add button stays right aligned; sidebar selection, icons and unsaved markers use a consistent layout. The save footer maintains a stable height in its normal state, keeping feedback and buttons in consistent positions.

### Clear browsing data and reopen settings

Click Clear Browsing Data… at the top right of Browser. After the Accessibility check, choose Safari or Chrome and confirm the scope in the browser. Nivlet does not confirm deletion. Reopening an existing settings window through an app shortcut or the Dock preserves its page; first open goes to General.
