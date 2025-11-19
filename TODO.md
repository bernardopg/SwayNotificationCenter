# TODO – GTK4 Control Center UX / configuration

Repository: local fork at `~/git-clones/SwayNotificationCenter`.
This file documents planned UX/config work only; it does **not** reflect implemented features.

## 1. Optional “Control Center” title

**Context**

- The main “Control Center” header is provided by the `label` widget in the user config (`widgets: ["label", …]`), not hard-coded.
- The shipped default config (`src/config.json.in`) only enables `inhibitors`, `title`, `dnd`, `notifications`, but the `label` widget is available for themes that want an extra header.

**Tasks**

- [ ] Clarify in `man/swaync.5.scd` / docs that `label` is optional and can be removed from `widgets` to save vertical space.
- [ ] Revisit `src/config.json.in` and ensure the default configuration does not add a redundant “Control Center” title.
- [ ] (Optional) Add a top-level boolean such as `"control-center-show-main-label"` to `src/configSchema.json`:
  - Define schema, default, and description.
  - Make the control-center layout builder respect this flag when deciding whether to render a top header.
  - Keep existing configs working when the key is missing.
- [ ] Add tests or manual QA notes covering configs with and without the header / new flag.

## 2. DND pill switch with icon-only option

**Context**

- The DND widget is defined in `src/config.json.in` / `src/configSchema.json` and rendered as `label + Gtk.Switch`, styled by `data/style/widgets/dnd.scss`.
- Goal: compact, Waybar-like DND control: wide pill, icon-based, with text available via tooltip instead of inline label.

**Tasks**

- [ ] Redesign `.widget-dnd switch` in `data/style/widgets/dnd.scss`:
  - Pill-shaped background, clear on/off colors, small vertical footprint.
  - Hover/focus/active states consistent with the theme.
- [ ] Add CSS hooks for a compact/icon-only mode, e.g. `.widget-dnd.compact label { display: none; }`, while keeping state obvious.
- [ ] Extend the DND widget schema with something like `"show-label"` or `"style": "default" | "compact"` and document defaults.
- [ ] Update the DND widget implementation to:
  - Apply the correct style class(es) based on config.
  - Use an icon (symbolic bell/DND) plus tooltip text when running in icon-only mode.
- [ ] Verify accessibility:
  - Keyboard toggling works.
  - Screen readers get a sensible name/description and state.

## 3. Optional / removable widget section headers

**Context**

- Section headers such as “Notifications” and “Inhibitors” come from the `title` and `inhibitors` widgets (`src/config.json.in`, `src/configSchema.json`), styled via `.widget-title` / `.widget-label`.
- On compact sidebars these headers can feel redundant and consume vertical space.

**Tasks**

- [ ] Design configuration for hiding headers:
  - Per-widget flags like `widget-config.title.show-header` / `widget-config.inhibitors.show-header`, and/or
  - A global `"show-widget-headers"` default in `src/configSchema.json`.
- [ ] Adjust widget/factory code so headers are completely omitted when disabled, keeping layouts correct.
- [ ] Tune CSS so spacing between widgets looks balanced both with and without headers (no awkward gaps or double borders).
- [ ] Document header-visibility options in `man/swaync.5.scd` and sample configs.

## 4. Compact, configurable notification group headers

**Context**

- Per-app grouping is implemented in `src/notificationGroup/notificationGroup.vala` and styled in `data/style/style.scss` under `.notification-group`, `.notification-group-header`, `.notification-group-buttons`, etc.
- Current headers (app icon + name + collapse/close-all buttons) are relatively tall for a compact control center.

**Tasks**

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

**Context**

- `buttons-grid` is implemented in `src/controlCenter/widgets/buttonsGrid/buttonsGrid.vala`.
- Generic action parsing lives in `src/controlCenter/widgets/baseWidget.vala` (`Action` + `parse_actions()`), and menubar has its own `Action` in `src/controlCenter/widgets/menubar/menubar.vala`.
- Current schema (`src/configSchema.json`) supports `label`, `command`, `type`, `update-command`, `active` only.

**Tasks**

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

**Context**

- All of the above introduce new configuration keys and UX patterns that should be discoverable and easy to copy.

**Tasks**

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
