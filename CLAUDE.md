# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwayNotificationCenter (swaync) is a notification daemon with a GTK4 GUI for notifications and a control center, designed for Wayland compositors that support wlr_layer_shell_unstable_v1 (Sway, Hyprland, etc.). Written in Vala using GTK4, gtk4-layer-shell, and libadwaita.

## Build System

This project uses Meson build system:

```bash
# Initial setup
meson setup build --prefix=/usr

# Build
ninja -C build

# Install
meson install -C build

# Build with specific options (disable features)
meson setup build -Dpulse-audio=false -Dscripting=false
```

### Available Build Options (meson_options.txt)

- `systemd-service`: Install systemd user service unit (default: true)
- `scripting`: Enable notification scripting (default: true)
- `pulse-audio`: Provide PulseAudio Widget (default: true)
- `man-pages`: Install all man pages (default: true)
- `zsh-completions`: Install zsh shell completions (default: true)
- `bash-completions`: Install bash shell completions (default: true)
- `fish-completions`: Install fish shell completions (default: true)

### Running from Build Directory

```bash
# Run the daemon (kill other notification daemons first)
./build/src/swaync

# Run the client
./build/src/swaync-client -t              # Toggle panel
./build/src/swaync-client -R              # Reload config
./build/src/swaync-client -rs             # Reload CSS
./build/src/swaync-client -d              # Toggle DND
./build/src/swaync-client -C              # Close all notifications
```

## Code Quality and Linting

```bash
# Vala linting (uses .vala-lint.conf)
# Configured to check max line length of 100, naming conventions, spacing, etc.
# Run via elementary/actions/vala-lint in CI

# Code formatting with uncrustify (uses .uncrustify.cfg)
uncrustify -c ./.uncrustify.cfg -l vala $(find . -name "*.vala" -type f) --check

# Apply formatting
uncrustify -c ./.uncrustify.cfg -l vala --replace $(find . -name "*.vala" -type f)
```

## Architecture Overview

### Core Components

### Main Application (main.vala)

- Entry point: `Swaync` class extends `Gtk.Application`
- Application ID: `org.erikreider.swaync`
- Ensures single instance via DBus registration
- Initializes monitors, loads CSS, creates daemon

**SwayncDaemon (swayncDaemon/swayncDaemon.vala)**

- DBus interface: `org.erikreider.swaync.cc`
- Manages notification inhibitors and blank windows
- Controls layer shell usage and layer-on-demand support
- Owns the NotiDaemon instance

**NotiDaemon (notiDaemon/notiDaemon.vala)**

- DBus interface: `org.freedesktop.Notifications` (freedesktop.org spec)
- Implements the freedesktop notification specification
- Manages Do Not Disturb state (persisted to GSettings)
- Owns the ControlCenter instance
- Handles notification creation, closing, and actions

**Client (client.vala)**

- Command-line tool for controlling the daemon via DBus
- Implements all user-facing commands (toggle, reload, DND, etc.)
- See `swaync-client --help` for full command list

### Window Components

**ControlCenter (controlCenter/controlCenter.vala)**

- Main notification panel window
- Uses gtk4-layer-shell for Wayland layer shell positioning
- Contains customizable widgets (loaded from config)
- Handles keyboard shortcuts and visibility management

**NotificationWindow (notificationWindow/notificationWindow.vala)**

- Singleton window for popup notifications
- Uses gtk4-layer-shell for positioning
- Contains AnimatedList of notification widgets
- Auto-hides based on config and user interaction

**Notification (notification/notification.vala)**

- Individual notification widget (used in both popup and control center)
- Supports inline replies, actions, images, MPRIS controls
- Implements swipe-to-dismiss gesture
- Handles notification body markup and 2FA code detection

### Widget System

**BaseWidget (controlCenter/widgets/baseWidget.vala)**

- Abstract base class for all control center widgets
- Provides config parsing utilities (`get_prop`, `get_prop_array`, `parse_actions`)
- Handles CSS classes and widget lifecycle
- All widgets have a `widget_name` and optional `suffix` for multiple instances

**Widget Factory (controlCenter/widgets/factory.vala)**

- `get_widget_from_key()`: Creates widgets from config keys
- Supported widgets: title, dnd, notifications, label, mpris, menubar, buttons-grid, slider, volume (if HAVE_PULSE_AUDIO), backlight, inhibitors
- Widget keys can include suffix: `"mpris#1"` creates widget with key "mpris" and suffix "1"

**Available Widgets:**

- **Notifications**: Always visible, displays notification list
- **Title**: Shows title text
- **Dnd**: Do Not Disturb toggle
- **Label**: Custom text label
- **Mpris**: Media player controls (uses org.mpris.MediaPlayer2 DBus interface)
- **Menubar**: Dropdown menus with buttons
- **ButtonsGrid**: Grid of custom action buttons
- **Slider**: Generic slider widget
- **Volume**: PulseAudio volume controls (conditional on pulse-audio build option)
- **Backlight**: Screen backlight slider
- **Inhibitors**: Display and manage notification inhibitors

**Button Click Support:**

Buttons in menubar and buttons-grid widgets support multiple input types:

**Legacy Format (still supported):**

- `command`: Command to run on click
- `type`: "normal" or "toggle"
- `update-command`: For toggle buttons, command to check state (should echo "true" or "false")
- `active`: Initial toggle state

**Multi-Click Format (new):**

- `on-click`: Object defining actions for different mouse buttons
  - `left`: Command or object for left click (primary action)
  - `middle`: Command or object for middle click (scroll wheel click)
  - `right`: Command or object for right click

For toggle buttons, only left click maintains toggle state. Middle and right clicks execute commands without toggling.

Example configurations:

```json
{
  "label": "Simple",
  "on-click": {
    "left": "notify-send 'Left click'",
    "middle": "notify-send 'Middle click'",
    "right": "notify-send 'Right click'"
  }
}
```

```json
{
  "label": "Toggle",
  "type": "toggle",
  "on-click": {
    "left": {
      "command": "toggle-script.sh",
      "update-command": "check-state.sh",
      "active": false
    },
    "middle": "quick-action.sh",
    "right": "settings.sh"
  }
}
```

Toggle buttons receive `$SWAYNC_TOGGLE_STATE` environment variable (left click only).

### Configuration

**ConfigModel (configModel/configModel.vala)**

- Singleton: `ConfigModel.instance`
- Loads from: `~/.config/swaync/config.json` or `/etc/xdg/swaync/config.json`
- Schema validation against `configSchema.json`
- Hot-reloadable via `swaync-client -R`
- Contains widget configuration, notification settings, positioning, scripting rules, etc.

**CSS Styling:**

- Main file: `~/.config/swaync/style.css` or `/etc/xdg/swaync/style.css`
- Source SCSS files in `data/style/` (use `sassc` to compile)
- Reload CSS without restart: `swaync-client -rs`
- Debug CSS: `GTK_DEBUG=interactive swaync` opens GTK Inspector

### Helper Structures

**OrderedHashTable (orderedHashTable/orderedHashTable.vala)**

- Hash table that maintains insertion order
- Used for widget configuration storage

**AnimatedList (animatedList/animatedList.vala)**

- Animated Gtk.ListBox with smooth add/remove transitions
- Used in NotificationWindow for notification animations

**NotificationGroup (notificationGroup/notificationGroup.vala)**

- Groups notifications by app name
- Supports expandable/collapsible groups
- Performance optimizations for large notification groups (lazy rendering)

## UI Files

UI layouts defined in Blueprint (.blp) format in `data/ui/`:

- `control_center.blp`: Control center layout
- `notification_window.blp`: Popup notification window layout
- `notification.blp`: Individual notification widget layout
- `mpris_player.blp`: MPRIS player widget layout
- `notifications_widget.blp`: Notifications widget for control center

Blueprint files are compiled to GTK .ui files during build via blueprint-compiler.

## Scripting System

When enabled (default), notifications can trigger shell scripts based on:

- `app-name`: Notification app name (regex)
- `summary`: Notification summary (regex)
- `body`: Notification body (regex)
- `urgency`: Low, Normal, or Critical
- `category`: Notification category (regex)
- `run-on`: When to run (`receive` or `action`)

Scripts receive notification details via environment variables.
Disable scripting: `meson setup build -Dscripting=false`

## DBus Interfaces

**Notification Daemon: org.freedesktop.Notifications**

- Standard freedesktop notification spec implementation
- Methods: Notify, CloseNotification, GetCapabilities, GetServerInformation

**Control Center: org.erikreider.swaync.cc**

- Custom swaync control interface
- Methods: reload_config, reload_css, toggle_visibility, toggle_dnd, close_all_notifications, etc.
- Signals: subscribe_v2 (notification count, dnd state, visibility, inhibited status)
- Use `swaync-client` for command-line access

## Conditional Compilation

Uses Vala preprocessor directives:

- `#if HAVE_PULSE_AUDIO`: Volume widget and PulseAudio support
- `#if WANT_SCRIPTING`: Notification scripting support

Set via meson build options which add `-D HAVE_PULSE_AUDIO` or `-D WANT_SCRIPTING` to Vala compiler args.

## Internationalization (i18n)

Swaync uses GNU gettext for translations:

- **Text domain**: `swaync`
- **Locale directory**: `/usr/share/locale`
- **POT template**: `po/swaync.pot`
- **Translations**: `po/<lang>.po` (e.g., `po/pt_BR.po`)

### Translatable Strings

User-visible strings are wrapped with `_()` macro:

```vala
string title = _("Notifications");
string tooltip = ngettext("%u Notification", "%u Notifications", count).printf(count);
```

### Adding Translations

1. Add language code to `po/LINGUAS`
2. Generate `.po` file: `msginit --locale=<lang> --input=po/swaync.pot --output=po/<lang>.po`
3. Translate strings in the `.po` file
4. Rebuild and install

### Testing Translations

```bash
LANG=pt_BR.UTF-8 swaync-client --help
```

## Debugging

```bash
# Enable debug messages
G_MESSAGES_DEBUG=all swaync

# Enable GTK Inspector
GTK_DEBUG=interactive swaync

# Enable deprecation warnings
G_ENABLE_DIAGNOSTIC=1 swaync

# Abort on warnings/criticals
G_DEBUG=fatal_criticals swaync
G_DEBUG=fatal_warnings swaync
```

## Version Management

Version is set in `meson.build` (currently 0.12.3).
Git info appended to version string if available: `swaync 0.12.3 (git-abc1234, branch 'main')`
Version string compiled into `constants.vala` from `constants.vala.in` template.

## Common Patterns

### Adding a New Widget

1. Create widget class in `src/controlCenter/widgets/yourwidget/yourwidget.vala`
2. Extend `BaseWidget`, implement `widget_name` property
3. Add to `widget_sources` in `src/meson.build`
4. Add case in `factory.vala` `get_widget_from_key()` switch
5. Create SCSS file in `data/style/widgets/yourwidget.scss`
6. Import in `data/style/style.scss`
7. Add configuration schema to `configSchema.json`
8. Document in man page `man/swaync.5.scd`

### Accessing Configuration

```vala
// In a widget class extending BaseWidget
Json.Object? config = get_config(this);
if (config == null) return; // Use defaults

// Get typed properties
bool found;
string label = get_prop<string>(config, "label", out found);
int timeout = get_prop<int>(config, "timeout", out found);
Json.Array actions = get_prop_array(config, "actions");
```

### Widget CSS Classes

Widgets automatically get CSS classes:

- `.widget`: All widgets
- `.widget-{widget_name}`: Widget-specific class (e.g. `.widget-mpris`)
- `.{suffix}`: If widget has suffix (e.g. `mpris#spotify` gets `.spotify` class)

## Important Notes

- Only works on Wayland compositors with wlr_layer_shell_unstable_v1 support
- Only tested with default GTK Adwaita theme; third-party themes may need CSS tweaks
- Uses gtk4-layer-shell version >= 1.0.4 for layer shell protocol v4 features
- Layer-on-demand requires layer shell protocol v4+
- Notification window is a singleton due to GTK hover state bug workaround
- Config and CSS files hot-reload without daemon restart
- GSettings schema: `org.erikreider.swaync` (stores DND state)
