> This guide covers the current release (version recorded in [BASELINE](../BASELINE.md)), macOS 13+, Apple Silicon (arm64). Version 1.0.8 Build 55 remains the final Intel release.

# Nivlet User Guide

See the [release notes index](README.md) for each version's changes and verification boundaries. Signing and notarization do not grant Accessibility access. See the [installation guide](INSTALLATION.en.md).

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
| Pin to desktop | With Screenshot enabled, click Pin to Desktop on an image in the settings history |

Text history defaults to 50 entries, with choices from 10 to 100. Retention defaults to 30 minutes; choose 30 minutes, 1/2/4/8/12/24 hours or forever. Forever still respects the count limit. Image history holds up to 10 images, approximately 10 MiB each. Copied files are not recorded; image paste requires target-app support.

History is discarded on exit by default. Persistence across restarts is optional and uses a local plaintext cache. Duplicate content moves to the newest position; content copied before enabling or while recording is off is not backfilled. Turn recording off and save before copying sensitive information: app exclusions and filters cannot identify every sensitive item.

The menu shortcut has an enable switch, displays **⌘⇧ + V** and binds **Command-Shift-V**. It is enabled for a fresh installation or when shortcut configuration is missing; an explicit off setting persists across restarts. Existing custom shortcuts remain unchanged on startup and when saving unrelated settings. Changing this switch and saving binds Command-Shift-V when enabled or removes the binding when disabled. This shortcut is independent of recording, so existing history remains accessible when recording is off.

There is no separate Pause/Resume action. Enable Clipboard History is the only recording control; turning it off does not clear history, change retention limits or backfill content when enabled again.

Image previews open directly from thumbnails, with no separate open or close button. Clicking outside the image element’s bounds within the Nivlet window closes the preview; transparent pixels inside those bounds do not. Escape, focus restoration after asynchronous history refresh and prevention of click-through remain in place, without a global mouse permission.

### Screenshot

Enable and save it in Settings → Screenshot; it is off by default. The first time, grant **Screen Recording** in General (the permissions area lists the features that use it). If macOS asks, quit and reopen Nivlet after granting it.

Press the screenshot shortcut (F1 by default — add fn on a built-in keyboard — or a function key or a ⌃/⌥/⌘ combination) to freeze the screen, then drag to select an area. With "Detect windows automatically" on, hovering selects a whole window. With "Show magnifier and color picker" on, a magnifier and the color under the pointer appear while selecting. A keyboard's own screenshot key usually sends ⌘⇧4: to use it, turn that item off in System Settings → Keyboard → Keyboard Shortcuts → Screenshots, then set ⌘⇧4 in Nivlet.

| Action | How |
| --- | --- |
| Annotate | Pick rectangle, arrow, pen, text or mosaic in the toolbar; undo and redo are available |
| Copy | Click Copy, press Return or double-click the selection; copies go into clipboard history per the Clipboard settings, marked as screenshots |
| Save | Click Save or press ⌘S to save to the chosen folder (default `~/Pictures/Nivlet`) as PNG or JPEG |
| Recognize text or QR | Click the button (O / Q); results appear in a panel and can be copied. Recognition runs on device |
| Pin to desktop | Click Pin (P); the image stays on top of the desktop and can be moved, faded or closed |
| Translate | With System Translation on, a Translate button (L) appears |
| Exit | Press Escape or right-click |

The first text recognition may take tens of seconds while macOS prepares its model; later ones usually take under a second. With Screenshot enabled, images in the settings history can also be pinned to the desktop.

### System translation

Enable and save it in Settings → Translation; it is off by default and needs macOS 15 or later. It uses only macOS's built-in on-device translation. Some languages ask to download a language pack the first time.

- **Selection translation**: select text and press the chosen modifier key twice within 0.4 seconds (⌥ by default). The card appears below the selection. Reading the selection needs Accessibility; when it cannot be read, Nivlet copies the selection briefly and then restores the clipboard.
- **Screenshot translation**: press the other modifier key twice (⌃ by default), select an area, and the text is recognized and translated when you release. Needs Screen Recording.
- Left and right ⌃, ⌥ and ⌘ can be set separately; the two triggers cannot share a key. Pressing another key in between or holding the key does not trigger. Turn off the same double-tap trigger in other tools to avoid two windows.
- **Direction**: automatic by default (Chinese to English, other languages to Simplified Chinese), or always Simplified Chinese, Traditional Chinese, English, Japanese or Korean. With "Remember my last choice" on, a direction you change in the card is reused for that language; Clear resets it.
- The card can copy the translation or replace the selected text (editable text only), and can show the original and copy the translation automatically.

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

Choose network speed, CPU, memory, disk, IPv4, IPv6, calendar date/weekday and lunar date in System Information, then save. Settings show current values; an information entry remains when network speed is hidden. Click addresses or dates in the menu to copy them.

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

Unsaved pages have an orange dot in the sidebar. Saving or discarding clears the corresponding marker. General retains Check Again even when Accessibility is off and refreshes permission status when its window regains focus. Default-browser setup no longer requests unrelated document associations. Manual acceptance on one setup does not establish compatibility with every Mac or macOS version. See the [installation guide](INSTALLATION.en.md) for the current Developer ID/notarization limitations.

## Interface consistency

Disclosure arrows share the same size, spacing and expanded direction. The excluded-app Add button stays right aligned; sidebar selection, icons and unsaved markers use a consistent layout. The save footer maintains a stable height in its normal state, keeping feedback and buttons in consistent positions.

### Clear browsing data and reopen settings

Click Clear Browsing Data… at the top right of Browser. After the Accessibility check, choose installed Safari, Chrome or Brave and confirm the scope in the browser. Nivlet does not confirm deletion. Reopening an existing settings window through an app shortcut or the Dock preserves its page; first open goes to General.

### Keep awake and Keep display on

Both General switches are off by default and take effect through Save All Settings. Keep display on requires Keep awake; disabling the parent also disables the child. Keep awake alone allows normal display sleep. Keep display on additionally prevents idle display sleep and may delay locks that depend on the display turning off. Disabling the parent or quitting releases only Nivlet’s own assertions. It does not adjust brightness, change persistent power/security settings or bypass a password.

All three native browser selectors show the selected browser’s real icon. Shared installed-browser information supplies names, icons and clear-data capabilities; focus/page refresh preserves drafts. Version 2.0.1 removes the MAC address and its display switch while keeping other network information and interface selection unchanged.
