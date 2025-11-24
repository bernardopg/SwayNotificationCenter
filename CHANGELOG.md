# Changelog

All notable changes to SwayNotificationCenter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Multi-Click Button Support**: Buttons in `buttons-grid` and `menubar` widgets now support different actions for left, middle (scroll wheel), and right mouse clicks
  - New `on-click` configuration property with `left`, `middle`, and `right` actions
  - For toggle buttons, only left-click maintains toggle state; middle and right clicks execute commands without toggling
  - Fully backward compatible with existing single-command button configuration
  - See [example-multi-click-config.json](example-multi-click-config.json) for examples
  - Documentation added to README.md, man page (swaync.5), UX-CUSTOMIZATION.md, and CLAUDE.md

- **Tooltip Support for Buttons**: Buttons in `buttons-grid` now support tooltips
  - New `tooltip` property in button action configuration
  - Displays helpful text when hovering over buttons
  - Works with all button types (normal, toggle, multi-click)

### Changed

- Button command parsing now checks for `on-click` property first, falling back to legacy `command` property

### Technical

- New `ClickableButton` class in `src/controlCenter/widgets/shared/clickableButton.vala`
- New `parse_on_click()` and `parse_click_action()` helper methods in `BaseWidget`
- Updated `buttonsGrid.vala` and `menubar.vala` to support multi-click buttons
- Enhanced JSON schema in `configSchema.json` with multi-click definitions

## [0.12.3] - Previous Release

See Git history for previous changes.

[Unreleased]: https://github.com/ErikReider/SwayNotificationCenter/compare/v0.12.3...HEAD
[0.12.3]: https://github.com/ErikReider/SwayNotificationCenter/releases/tag/v0.12.3
