# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Build System & Commands

### Building

```bash
# Initial setup
meson setup build --prefix=/usr

# Compile
ninja -C build

# Install system-wide (requires sudo)
sudo meson install -C build

# Clean rebuild
meson setup build --prefix=/usr --wipe
ninja -C build
```

### Build Options

Available Meson options (from `meson_options.txt`):

- `systemd-service` (default: true) - Install systemd user service
- `scripting` (default: true) - Enable notification scripting
- `pulse-audio` (default: true) - Provide PulseAudio widget
- `man-pages` (default: true) - Install man pages
- `zsh-completions`, `bash-completions`, `fish-completions` (default: true)

Example: Build without scripting support

```bash
meson setup build --prefix=/usr -Dscripting=false
ninja -C build
```

### Development Workflow

```bash
# Run daemon from build directory (kill any running instance first)
killall swaync
./build/src/swaync

# Run client from build directory
./build/src/swaync-client -t              # Toggle control center
./build/src/swaync-client -R              # Reload config
./build/src/swaync-client -rs             # Reload CSS
./build/src/swaync-client -t -sw          # Toggle with window switch

# Quick restart sequence
killall swaync && swaync &
```

### Debugging

```bash
# Enable all debug messages
G_MESSAGES_DEBUG=all swaync

# Open GTK Inspector
GTK_DEBUG=interactive swaync

# Enable GObject diagnostics (deprecation warnings)
G_ENABLE_DIAGNOSTIC=1 swaync

# Break on warnings/criticals
G_DEBUG=fatal_warnings swaync
G_DEBUG=fatal_criticals swaync
```

### Linting & Formatting

```bash
# Vala linting (uses .vala-lint.conf)
vala-lint src/

# C code formatting (uses .uncrustify.cfg)
uncrustify -c ./.uncrustify.cfg -l vala $(find . -name "*.vala" -type f) --check

# Apply formatting
uncrustify -c ./.uncrustify.cfg -l vala $(find . -name "*.vala" -type f) --replace --no-backup
```

## Architecture Overview

### Core Components

**Entry Point:** `src/main.vala`

- Initializes GTK4 and Libadwaita
- Loads config via `ConfigModel.init()`
- Registers custom widget types for Blueprint templates
- Creates and runs the `Swaync` GTK application

**DBus Services:**

1. `SwayncDaemon` (`src/swayncDaemon/swayncDaemon.vala`)
   - Bus name: `org.erikreider.swaync.cc`
   - Manages control center visibility, DND state, inhibitors
   - Handles monitor configuration and blank window overlays
   - Provides client API (`swaync-client` calls this)

2. `NotiDaemon` (`src/notiDaemon/notiDaemon.vala`)
   - Bus name: `org.freedesktop.Notifications`
   - Implements freedesktop.org notification spec
   - Routes notifications to `NotificationWindow` (popups) and `ControlCenter` (persistent list)
   - Handles scripting, visibility rules, DND filtering

**UI Windows:**

- `ControlCenter` (`src/controlCenter/controlCenter.vala`) - Sidebar panel with widgets and notification history
- `NotificationWindow` (`src/notificationWindow/notificationWindow.vala`) - Popup notification overlays
- `BlankWindow` (`src/blankWindow/blankWindow.vala`) - Covers non-active monitors when control center is open

### Widget System

Widgets are loaded dynamically via `src/controlCenter/widgets/factory.vala`:

**Available widgets:**

- `title` - Header with text/button
- `dnd` - Do Not Disturb toggle
- `notifications` - Notification list (special: always rendered, not instantiated via factory)
- `label` - Static/dynamic text label
- `mpris` - Media player controls (album art, playback buttons)
- `menubar` - Dropdown menus with actions
- `buttons-grid` - Grid of action buttons
- `slider` - Generic slider widget
- `volume` - PulseAudio volume control (requires `-Dpulse-audio=true`)
- `backlight` - Brightness control
- `inhibitors` - Shows active notification inhibitors

**Multiple instances:** Widgets support suffix notation for multiple instances:

```json
{
  "widgets": ["mpris#player1", "mpris#player2", "label#status"]
}
```

**Base class:** All widgets extend `BaseWidget` (`src/controlCenter/widgets/baseWidget.vala`)

### Data Flow

1. Application sends notification via D-Bus to `org.freedesktop.Notifications.Notify()`
2. `NotiDaemon` receives notification, creates `NotifyParams` object
3. Notification visibility rules evaluated (from `configSchema.json` → `notification-visibility`)
4. Based on state (`ENABLED`/`TRANSIENT`/`IGNORED`) and DND/inhibitor status:
   - Popup added to `NotificationWindow` (if not hidden)
   - Entry added to `ControlCenter` notification list (if not transient)
5. Scripting hooks run if enabled (compile-time flag `-DWANT_SCRIPTING`)
6. DBus signals emitted to update `swaync-client` and status bar widgets

## Configuration & Styling

### Config Files

**System defaults:**

- `/etc/xdg/swaync/config.json` - Default config
- `/etc/xdg/swaync/configSchema.json` - JSON schema
- `/etc/xdg/swaync/style.css` - Default styles

**User overrides:**

- `~/.config/swaync/config.json` - User config (takes precedence)
- `~/.config/swaync/style.css` - User styles (takes precedence)

### Config Model

The `ConfigModel` singleton (`src/configModel/configModel.vala`) parses JSON config with these key sections:

- `widgets` - Array of widget names to display in control center
- `widget-config` - Per-widget configuration objects
- `notification-visibility` - Rules to show/hide/modify notifications (regex matching on app-name, summary, body, etc.)
- `scripts` - Commands to run when notifications match criteria
- `categories` - Map notification categories to sounds/icons

### Reloading

```bash
# Reload config (hot-reload, no restart needed)
swaync-client --reload-config

# Reload CSS (hot-reload)
swaync-client --reload-css
# or shorthand:
swaync-client -rs
```

**When restart IS needed:**

- Changing compile-time options (`-Dscripting=false`, `-Dpulse-audio=false`)
- Modifying `.blp` Blueprint UI templates (requires `meson compile -C build`)
- Changing `layer_shell` or compositor-specific settings

## Wayland / Layer Shell

**Compositor requirement:** Requires `wlr_layer_shell_unstable_v1` support (Sway, Hyprland, River, etc.)

**Layer shell usage:**

- Control center uses namespace `swaync-control-center`
- Notification window uses namespace `swaync-notification-window`
- Layer, anchors, and margins set via `gtk4-layer-shell-0` library
- Layer shell properties must be configured before window is mapped (see `controlCenter.vala` constructor)

**Monitor handling:**

- Preferred output configurable via `control_center_preferred_output` and `notification_window_preferred_output` in config
- Blank windows automatically cover inactive monitors when control center opens (if `layer_shell_cover_screen: true`)

## Notification Handling & Scripting

### Visibility States

Notifications can have three states (defined in `notification-visibility` config):

- `ENABLED` - Show popup and add to control center
- `TRANSIENT` - Show popup but don't persist in control center
- `IGNORED` - Don't show popup or persist

### DND and Inhibitors

- **DND (Do Not Disturb):** Blocks all non-critical notifications
- **Inhibitors:** External processes can request notification suppression via DBus

  ```bash
  swaync-client --inhibitor-add "my-app"
  swaync-client --inhibitor-remove "my-app"
  ```

- **Bypass:** Notifications with urgency `CRITICAL` or hint `swaync-bypass-dnd` always show

### Synchronous Notifications

Progress/volume notifications use `synchronous` or `x-canonical-private-synchronous` hints to replace previous notification with same tag (avoids notification spam)

### Scripting

Conditional script execution based on notification properties (regex matching):

```json
{
  "scripts": {
    "spotify-notify": {
      "exec": "/path/to/script.sh",
      "app-name": "Spotify",
      "urgency": "Normal",
      "run-on": "receive"
    }
  }
}
```

**Disable at compile time:**

```bash
meson setup build -Dscripting=false
```

## Repository Layout

- `src/main.vala` - Application entry point
- `src/swayncDaemon/` - DBus service for control center management
- `src/notiDaemon/` - DBus service implementing freedesktop notification spec
- `src/controlCenter/` - Control center window and widget system
  - `widgets/` - All widget implementations + factory
- `src/notificationWindow/` - Popup notification window
- `src/notification/` - Individual notification rendering
- `src/notificationGroup/` - Grouped notification UI
- `src/configModel/` - JSON config parsing and validation
- `src/notiModel/` - Notification data model
- `src/configSchema.json` - JSON schema for config validation
- `data/ui/*.blp` - Blueprint GTK4 UI templates
- `protocols/` - Wayland protocol definitions
- `man/` - Man page sources (scdoc format)
- `completions/` - Shell completion scripts

## Adding a New Widget

1. Create widget directory: `src/controlCenter/widgets/mywidget/`
2. Implement widget class extending `BaseWidget` with constructor signature:

   ```vala
   public MyWidget(string suffix, SwayncDaemon swaync_daemon, NotiDaemon noti_daemon)
   ```

3. Add case to `src/controlCenter/widgets/factory.vala`:

   ```vala
   case "mywidget":
       widget = new MyWidget(suffix, swaync_daemon, noti_daemon);
       break;
   ```

4. Add source to `widget_sources` in `src/meson.build`
5. Add schema to `configSchema.json` under `widget-config/mywidget`
6. (Optional) Create Blueprint template in `data/ui/mywidget.blp`

## Common Gotchas

- **GTK theme conflicts:** If third-party GTK themes break styling, set `"ignore-gtk-theme": true` in config to force Adwaita
- **Layer shell properties:** Must be set before window is mapped; cannot change dynamically after first show
- **Compile-time feature flags:** Features like PulseAudio widget and scripting are compile-time options (`-DHAVE_PULSE_AUDIO`, `-DWANT_SCRIPTING`)
- **Blueprint changes:** Modifying `.blp` files requires recompiling (`ninja -C build`) not just config reload
- **Config vs restart:** Most config changes hot-reload, but layer shell settings and compile-time features require full restart
- **Notification ID handling:** IDs are per-session; don't assume IDs persist across restarts
- **Synchronous hints:** Use `x-canonical-private-synchronous` or `synchronous` hint for progress bars that should replace each other
