> Current release: 1.0.5 / Build 47.

# Nivlet User Guide

[Back to README](../README.md) · [简体中文](USAGE.md)

## Usage

### Clipboard

Enable and save recording in Settings → Clipboard, then copy new content. Open the menu bar clipboard icon: images appear above text, with thumbnails and hover previews; text entries have a T tile. Settings history remains in chronological order.

| Action | How |
| --- | --- |
| Copy an entry | Click it in the menu, then paste into the target app |
| Paste directly | Hold Option and click an entry to paste into the app active before opening the menu; requires Accessibility |
| Search | Use Search History… in the menu or the settings search field; text search only, no image OCR |
| Enlarge an image | Use the preview button on its settings history card |
| Pause | Pause Recording in the menu; resuming captures only new copies |
| Clear | Clear History… in the menu or settings; confirmation deletes history and cache **and clears the current system clipboard. This cannot be undone** |

Text history defaults to 50 entries, with choices from 10 to 100. Retention defaults to 30 minutes; choose 30 minutes, 1/2/4/8/12/24 hours or forever. Forever still respects the count limit. Image history holds up to 10 images, approximately 10 MiB each. Copied files are not recorded; image paste requires target-app support.

History is discarded on exit by default. Persistence across restarts is optional and uses a local plaintext cache. Duplicate content moves to the newest position; content copied before enabling or while paused is not backfilled. Pause before copying sensitive information: app exclusions and filters cannot identify every sensitive item.

### Window management and app launching

Enable the feature, configure key combinations and save. Supported keys include letters, numbers, arrows, Return, `=` and `-`. Letters display in uppercase; Backspace or Delete clears a binding. No shortcuts are assigned by default.

Window actions include halves, quarters, centering, thirds, a 3×3 grid, resizing by 40 points and moving to adjacent displays. Restore returns a window to its position before its first adjustment in the current run. Full-screen windows are unsupported; app minimum sizes may limit small layouts. Display moves do not wrap when no adjacent display exists.

Launcher rules open an app or bring it forward. Adding the same app again highlights the existing entry instead of creating a duplicate; input-source and browser source-app rules also check duplicates. Conflicting shortcuts within Nivlet block saving, but not every third-party shortcut can be detected.

### Browser routing

1. In Settings → Browser, choose a fallback browser and add domain or source-app rules.
2. Enable and save. Use the match check and open-by-rule actions to test; a simulated source can check app rules.
3. Click “Set as Default Browser…” and complete the macOS confirmation, then check again. If no prompt appears, use “Open Default Browser Settings…” and select Nivlet. Switch back to your previous browser to stop routing.

Priority is **domain → source app → fallback**. Domain rules match from top to bottom, support subdomains and can be reordered with ↑ / ↓. Installed Safari, Chrome, Firefox, Edge and Brave are supported. Only HTTP/HTTPS links are handled. Some apps do not expose an identifiable source; domain rules or the fallback apply in that case.

### System information and input sources

Choose network speed, CPU, memory, disk, IPv4, IPv6, MAC address, calendar date/weekday and lunar date in System Information, then save. Settings show current values; an information entry remains when network speed is hidden. Click addresses or dates in the menu to copy them. macOS may hide the MAC address; “Hidden by system” is unrelated to Accessibility permission.

In Input Sources, add an app and choose one of the system's enabled input sources, then enable and save. The rule applies when you next activate that app; unconfigured apps keep the current input source.

### Appearance, navigation and configuration

- Language: follow system, Simplified Chinese or English. Appearance: follow system, light or dark. Both follow the system by default.
- Hide or show the main N icon independently of clipboard and system information. The intended order is network speed → clipboard → N; positions also depend on macOS's saved state.
- Drag tabs to reorder them. General stays first and About stays last. Tab order saves automatically; other editable settings use the bottom-right save button.
- Launch at login takes effect after saving. Optional Command + L sleep is off by default; enabling it overrides the same shortcut in apps such as browsers.
- Export JSON or a default example from General → Configuration Backup & Migration. Review the replacement scope before importing. Omitted modules stay unchanged; failures restore the previous configuration. History, caches, permissions, login items and the system default browser are excluded. See the [configuration guide](CONFIGURATION.md) (Chinese).


## Saving changes and updating

An orange dot marks tabs with unsaved changes. Save and Cancel apply only to the current page and are disabled on unchanged pages; switching tabs keeps drafts. Drag the handles to reorder app-launch and input-source rules, then save.

Use About → Software update to check manually, then confirm download, installation and restart. Resolve unsaved changes first. Background checks and silent installation are off by default. Checking and downloading use the network; configuration and clipboard history are not uploaded. Development signatures may require Accessibility permission again. Older builds without the updater can be replaced using the latest GitHub download.

## Interface and interaction

Settings use compact rows and aligned shortcut fields. Drag the leading app icon to reorder app shortcut, input-source, browser source-app and clipboard-exclusion rules, then save. Filtering disables reordering. Newly added apps appear first; duplicate apps locate the existing rule without changing its order. Names use the macOS display name; unavailable apps keep their saved name or Bundle ID.

Browser app and domain rules are separate sections. Save rules, then test links from another app; the internal test panel has been removed. Select clipboard exclusions using Add App. Menu history clicks copy; Option-click pastes into the focused input and requires Accessibility. Tab/Shift-Tab navigate controls, Escape leaves shortcut capture or dismisses supported dialogs, and Command-S saves the current page. Command-W/Q inside shortcut capture record the shortcut instead of closing or quitting.

## Interface and interaction

Unsaved pages have a small soft orange dot centered below their tabs; text stays centered and keeps its original color. Saving or discarding clears the marker. General retains Check Again even when Accessibility is off and refreshes permission status when its window regains focus. Default-browser setup no longer requests unrelated document associations. Manual acceptance, including multiple displays, is complete on the maintainer's setup. See the [installation guide](INSTALLATION.en.md) for the current Developer ID/notarization limitations.

## Interface consistency

Disclosure arrows share the same size, spacing and expanded direction. The excluded-app Add button stays right aligned; centered unsaved dots and tab text are retained.

### Clear browsing data and reopen settings

Click Clear Browsing Data… at the top right of Browser. After the Accessibility check, choose Safari or Chrome and confirm the scope in the browser. Nivlet does not confirm deletion. Reopening an existing settings window through an app shortcut or the Dock preserves its page; first open goes to General.
