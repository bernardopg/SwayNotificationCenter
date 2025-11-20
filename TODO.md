# TODO – GTK4 Control Center UX / configuration

Repository: local fork at `~/git-clones/SwayNotificationCenter`.
This file documents planned UX/config work only; it does not reflect implemented features.

## Status Summary

✅ **Task 1: COMPLETE** - Optional Control Center title with full configuration support
✅ **Task 2: COMPLETE** - Compact DND widget with icon-only mode and pill-shaped styling
🚧 **Tasks 3-6: PENDING** - Additional UX improvements planned

### Documentation

- 📖 [UX Customization Guide](docs/UX-CUSTOMIZATION.md) - Complete guide for all new features
- 📦 [Example Layouts](examples/compact-layouts/) - Ready-to-use configurations
  - Minimal Compact
  - Waybar Style
  - Traditional Full

## 1. Optional "Control Center" title

### Context

- The main "Control Center" header is provided by the `label` widget in the user config (`widgets: ["label", …]`), not hard-coded.
- The shipped default config (`src/config.json.in`) only enables `inhibitors`, `title`, `dnd`, `notifications`, but the `label` widget is available for themes that want an extra header.

### Tasks

- [x] Clarify in `man/swaync.5.scd` / docs that `label` is optional and can be removed from `widgets` to save vertical space.
- [x] Revisit `src/config.json.in` and ensure the default configuration does not add a redundant "Control Center" title.
- [x] (Optional) Add a top-level boolean such as `"control-center-show-main-label"` to `src/configSchema.json`:
  - Define schema, default, and description.
  - Make the control-center layout builder respect this flag when deciding whether to render a top header.
  - Keep existing configs working when the key is missing.
- [x] Add tests or manual QA notes covering configs with and without the header / new flag.

### Manual QA Notes for Task 1

#### Implementation Summary

- Added `control-center-show-main-label` boolean to [configSchema.json](src/configSchema.json#L93-L97) with default value `false`
- Property defined in [configModel.vala](src/configModel/configModel.vala#L742-L744)
- Control center implementation in [controlCenter.vala](src/controlCenter/controlCenter.vala#L201-L207) prepends `label#main` widget when flag is `true`
- Default config for `label#main` widget added to [config.json.in](src/config.json.in#L80-L83) with text "Control Center"

#### Test Cases

**Test 1: Default behavior (backward compatibility)**

- Config: Do not set `control-center-show-main-label` or set to `false`
- Expected: No main "Control Center" header appears at the top
- Steps:
  1. Build and run: `ninja -C build && ./build/src/swaync`
  2. Open control center: `./build/src/swaync-client -t`
  3. Verify no "Control Center" label appears above other widgets

**Test 2: Enable main label**

- Config: Set `"control-center-show-main-label": true` in config.json
- Expected: "Control Center" label appears at the top of control center
- Steps:
  1. Edit `~/.config/swaync/config.json` and add `"control-center-show-main-label": true`
  2. Reload config: `./build/src/swaync-client -R`
  3. Open control center: `./build/src/swaync-client -t`
  4. Verify "Control Center" label appears as first widget

**Test 3: Customize main label text**

- Config: Enable flag and customize `label#main` widget config
- Expected: Custom text appears in main header
- Steps:
  1. Set `"control-center-show-main-label": true`
  2. Add to `widget-config`: `"label#main": { "text": "Notifications Panel", "max-lines": 1 }`
  3. Reload config: `./build/src/swaync-client -R`
  4. Verify custom text "Notifications Panel" appears

**Test 4: CSS styling for main label**

- Config: Enable flag and add custom CSS
- Expected: Main label can be styled independently via `.widget-label.main` CSS class
- Steps:
  1. Enable `control-center-show-main-label`
  2. Add to `~/.config/swaync/style.css`:

     ```css
     .widget-label.main {
       font-size: 24px;
       font-weight: bold;
       padding: 20px;
       background-color: rgba(255, 255, 255, 0.1);
     }
     ```

  3. Reload CSS: `./build/src/swaync-client -rs`
  4. Verify styling applies to main label only

**Test 5: Widget ordering**

- Config: Enable flag with custom widget order
- Expected: Main label always appears first regardless of `widgets` array order
- Steps:
  1. Set `"control-center-show-main-label": true`
  2. Set `"widgets": ["dnd", "title", "notifications"]`
  3. Reload config
  4. Verify order is: "Control Center" label → DND → Title → Notifications

**Test 6: Compact layout (no main label)**

- Config: Disable flag for vertical space saving
- Expected: Control center more compact without redundant header
- Steps:
  1. Set `"control-center-show-main-label": false`
  2. Set compact widget config (e.g., `"title": { "show-header": false }`)
  3. Compare vertical space usage with/without main label
  4. Verify compact layout works as expected

## 2. DND pill switch with icon-only option

### Context: DND pill switch with icon-only option

- The DND widget is defined in `src/config.json.in` / `src/configSchema.json` and rendered as `label + Gtk.Switch`, styled by `data/style/widgets/dnd.scss`.
- Goal: compact, Waybar-like DND control: wide pill, icon-based, with text available via tooltip instead of inline label.

### Tasks

- [x] Redesign `.widget-dnd switch` in `data/style/widgets/dnd.scss`:
  - Pill-shaped background, clear on/off colors, small vertical footprint.
  - Hover/focus/active states consistent with the theme.
- [x] Add CSS hooks for a compact/icon-only mode, e.g. `.widget-dnd.compact label { display: none; }`, while keeping state obvious.
- [x] Extend the DND widget schema with something like `"show-label"` or `"style": "default" | "compact"` and document defaults.
- [x] Update the DND widget implementation to:
  - Apply the correct style class(es) based on config.
  - Use an icon (symbolic bell/DND) plus tooltip text when running in icon-only mode.
- [x] Verify accessibility:
  - Keyboard toggling works.
  - Screen readers get a sensible name/description and state.

### Manual QA Notes for Task 2

#### Implementation Summary

- Added `show-label` boolean property to DND widget schema in [configSchema.json](src/configSchema.json#L483-L487) with default `true`
- DND widget implementation in [dnd.vala](src/controlCenter/widgets/dnd/dnd.vala) supports icon-only mode
- Icon changes based on DND state: `notifications-symbolic` (off) / `notifications-disabled-symbolic` (on)
- Pill-shaped switch styling in [dnd.scss](data/style/widgets/dnd.scss) with smooth transitions
- Compact mode CSS class automatically applied when `show-label: false`
- Tooltip displays widget text in compact mode
- Full keyboard accessibility: switch is focusable and toggleable via Space/Enter
- Screen reader support: ARIA label and description properties set

#### Test Cases

**Test 1: Default behavior (full label)**

- Config: Do not set `show-label` or set to `true` in `widget-config.dnd`
- Expected: DND widget shows "Do Not Disturb" label + pill-shaped switch
- Steps:
  1. Build and run: `ninja -C build && ./build/src/swaync`
  2. Open control center: `./build/src/swaync-client -t`
  3. Verify label "Do Not Disturb" is visible next to switch
  4. Verify no icon is shown before the switch

**Test 2: Compact icon-only mode**

- Config: Set `"show-label": false` in `widget-config.dnd`
- Expected: Icon + switch only, no text label
- Steps:
  1. Edit `~/.config/swaync/config.json`: `"dnd": { "show-label": false }`
  2. Reload config: `./build/src/swaync-client -R`
  3. Open control center: `./build/src/swaync-client -t`
  4. Verify bell icon appears, label is hidden
  5. Hover over widget to see tooltip with "Do Not Disturb" text

**Test 3: Icon state changes with DND toggle**

- Config: Compact mode enabled
- Expected: Icon changes between normal bell and disabled bell
- Steps:
  1. Set `"show-label": false`
  2. Toggle DND off: `./build/src/swaync-client -d`
  3. Verify icon shows `notifications-symbolic` (bell)
  4. Toggle DND on: `./build/src/swaync-client -d`
  5. Verify icon changes to `notifications-disabled-symbolic` (bell with slash)

**Test 4: Pill-shaped switch styling**

- Config: Any mode
- Expected: Switch has rounded pill shape with smooth color transitions
- Steps:
  1. Open control center
  2. Verify switch has rounded corners (border-radius: 9999px)
  3. Toggle switch and observe smooth transition animation
  4. Check colors: unchecked (transparent bg), checked (accent color bg)
  5. Verify slider inside switch is circular and animates smoothly

**Test 5: Hover and focus states**

- Config: Any mode
- Expected: Clear visual feedback on hover and focus
- Steps:
  1. Open control center
  2. Hover over switch: verify background lightens
  3. Tab to focus switch: verify focus outline appears (2px solid)
  4. Press Space to toggle: verify active state (darker background)
  5. Verify all states have smooth 200ms transitions

**Test 6: Keyboard accessibility**

- Config: Any mode
- Expected: Full keyboard control without mouse
- Steps:
  1. Open control center with keyboard: `swaync-client -t`
  2. Press Tab repeatedly to navigate to DND switch
  3. Verify switch receives focus (visible focus ring)
  4. Press Space or Enter to toggle DND
  5. Verify state changes correctly
  6. Press D key shortcut: verify DND toggles (global shortcut)

**Test 7: Screen reader support**

- Config: Compact mode
- Expected: Screen reader announces widget name and state
- Steps:
  1. Enable screen reader (e.g., Orca)
  2. Set `"show-label": false`
  3. Navigate to DND widget with screen reader
  4. Verify screen reader announces: "Do Not Disturb" label
  5. Verify state is announced: "on" or "off"
  6. Toggle and verify state change is announced

**Test 8: Custom text and styling**

- Config: Custom text + CSS
- Expected: Custom text appears in tooltip and is stylable
- Steps:
  1. Set `"dnd": { "text": "Silenciar", "show-label": false }`
  2. Verify tooltip shows "Silenciar"
  3. Add custom CSS to `~/.config/swaync/style.css`:

     ```css
     .widget-dnd.compact {
       padding: 8px 16px;
       background: rgba(255, 255, 255, 0.05);
       border-radius: 12px;
     }
     .widget-dnd switch:checked {
       background-color: rgba(255, 100, 100, 0.9);
     }
     ```

  4. Reload CSS: `./build/src/swaync-client -rs`
  5. Verify custom styling applies correctly

## 3. Optional / removable widget section headers

### Context: Optional / removable widget section headers (Section 3)

- Section headers such as “Notifications” and “Inhibitors” come from the `title` and `inhibitors` widgets (`src/config.json.in`, `src/configSchema.json`), styled via `.widget-title` / `.widget-label`.
- On compact sidebars these headers can feel redundant and consume vertical space.

### Tasks

- [ ] Design configuration for hiding headers:
  - Per-widget flags like `widget-config.title.show-header` / `widget-config.inhibitors.show-header`, and/or
  - A global `"show-widget-headers"` default in `src/configSchema.json`.
- [ ] Adjust widget/factory code so headers are completely omitted when disabled, keeping layouts correct.
- [ ] Tune CSS so spacing between widgets looks balanced both with and without headers (no awkward gaps or double borders).
- [ ] Document header-visibility options in `man/swaync.5.scd` and sample configs.

## 4. Compact, configurable notification group headers

### Context: Compact, configurable notification group headers (Section 4)

- Per-app grouping is implemented in `src/notificationGroup/notificationGroup.vala` and styled in `data/style/style.scss` under `.notification-group`, `.notification-group-header`, `.notification-group-buttons`, etc.
- Current headers (app icon + name + collapse/close-all buttons) are relatively tall for a compact control center.

### Tasks

- [ ] Introduce CSS variables or explicit classes for a denser header, e.g.
  - `--notification-group-header-font-size`
  - `--notification-group-header-padding-y`
  - optional `.notification-group-header-compact` / `.notification-group-buttons-compact` classes.
- [ ] Reduce default padding and button sizing for collapse and close-all controls while keeping click targets large enough.
- [ ] Consider adding config under `widget-config.notifications` or a new `notification-group` section to control:
  - Use of compact header style.
  - Icon/text/tooltips for collapse/expand and close-all buttons.
- [ ] Optionally hide the collapse button when a group contains only a single notification (logic in `NotificationGroup`).
- [ ] Verify compact headers in both light/dark themes and with different font sizes.

## 5. Extended `buttons-grid` widget actions (icons, multi-click, tooltips, translations)

### Context: Extended `buttons-grid` widget actions (icons, multi-click, tooltips, translations) (Section 5)

- `buttons-grid` is implemented in `src/controlCenter/widgets/buttonsGrid/buttonsGrid.vala`.
- Generic action parsing lives in `src/controlCenter/widgets/baseWidget.vala` (`Action` + `parse_actions()`), and menubar has its own `Action` in `src/controlCenter/widgets/menubar/menubar.vala`.
- Current schema (`src/configSchema.json`) supports `label`, `command`, `type`, `update-command`, `active` only.

### Tasks

- [ ] Extend `widgets.buttons-grid.properties.actions` in `src/configSchema.json` with optional fields:
  - `icon`
  - `tooltip`
  - `secondary-text`
  - `command-primary` / `command-middle` / `command-secondary`
  - `translation-key` (or similar) for gettext-based localisation.
- [ ] Update the shared `Action` struct in `baseWidget.vala` and its parser:
  - Read the new fields with sensible defaults.
  - Treat legacy `command` as `command-primary` when extra commands are absent.
- [ ] Mirror additional fields in the menubar `Action` struct so semantics stay aligned.
- [ ] Refactor `ButtonsGrid` buttons to support icon + primary label + optional secondary text using a small internal box layout.
- [ ] Attach appropriate click handlers / gesture controllers:
  - Primary click / keyboard activation → `command-primary`.
  - Middle / right click → respective commands when present.
- [ ] Apply tooltips from the new `tooltip` field (fall back to label text).
- [ ] Extend `data/style/widgets/buttons.scss` for:
  - Icon+text layout.
  - Secondary-text typography.
  - Active / hover / toggle states in the new design.

## 6. Documentation and sample configuration updates

### Context: Documentation and sample configuration updates

- All of the above introduce new configuration keys and UX patterns that should be discoverable and easy to copy.

### Tasks

- [ ] After implementing each feature, update `man/swaync.5.scd` (and other relevant manpages) with:
  - New keys, allowed values, and defaults.
  - Short examples for compact control-center setups.
- [ ] Update `src/config.json.in` and/or add example configs showing:
  - No main “Control Center” title.
  - DND icon-only pill.
  - Headers disabled where appropriate.
  - Compact notification groups.
  - Rich `buttons-grid` usage (icon, tooltip, secondary text, multi-click).
- [ ] Add a short “UX customization” section to `README.md` (or a separate doc) pointing to these options and examples.
- [ ] Ensure any new user-facing strings (tooltips, labels) are wired into the translation workflow when `translation-key` is used.

---

Notes:

- Avoid committing editor backup files; only `TODO.md` should be added to version control when this document is first created.
