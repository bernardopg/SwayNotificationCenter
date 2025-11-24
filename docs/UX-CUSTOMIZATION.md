# UX Customization Guide

This guide covers advanced UX customization options for SwayNotificationCenter, allowing you to create compact, minimal control center layouts similar to Waybar or other modern notification interfaces.

## Table of Contents

- [Optional Control Center Title](#optional-control-center-title)
- [Compact DND Widget](#compact-dnd-widget)
- [Removable Widget Headers](#removable-widget-headers)
- [Multi-Click Button Support](#multi-click-button-support)
- [Complete Examples](#complete-examples)
- [CSS Customization](#css-customization)

---

## Optional Control Center Title

### Overview

By default, SwayNotificationCenter does not show a main "Control Center" title at the top. You can optionally enable it for a more traditional layout.

### Configuration

Add to your `~/.config/swaync/config.json`:

```json
{
  "control-center-show-main-label": true
}
```

**Default:** `false` (no main title shown)

### Customizing the Title Text

When enabled, you can customize the title text and appearance:

```json
{
  "control-center-show-main-label": true,
  "widget-config": {
    "label#main": {
      "text": "Notifications Panel",
      "max-lines": 1
    }
  }
}
```

### CSS Styling

Style the main label independently using the `.widget-label.main` CSS class:

```css
/* ~/.config/swaync/style.css */
.widget-label.main {
  font-size: 24px;
  font-weight: bold;
  padding: 20px 16px;
  color: rgba(255, 255, 255, 0.9);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}
```

### When to Use

- **Enable (`true`)**: When you want a clear title header, similar to traditional notification centers
- **Disable (`false`)**: For compact layouts where every pixel of vertical space matters

---

## Compact DND Widget

### Overview

The Do Not Disturb widget can be displayed in two modes:

1. **Default**: Label + Switch
2. **Compact**: Icon + Switch (icon-only mode)

### Configuration

#### Default Mode (with label)

```json
{
  "widget-config": {
    "dnd": {
      "text": "Do Not Disturb",
      "show-label": true
    }
  }
}
```

#### Compact Mode (icon-only)

```json
{
  "widget-config": {
    "dnd": {
      "text": "Do Not Disturb",
      "show-label": false
    }
  }
}
```

### Icon Behavior

In compact mode, the icon automatically changes based on DND state:

- **DND Off**: `notifications-symbolic` (bell icon)
- **DND On**: `notifications-disabled-symbolic` (bell with slash)

### Tooltip

The tooltip always displays the configured text, making compact mode fully accessible.

### CSS Styling

The widget automatically gets the `.compact` CSS class when `show-label: false`:

```css
/* Default styling - pill-shaped switch */
.widget-dnd switch {
  border-radius: 9999px;
  min-height: 32px;
  min-width: 52px;
  background-color: rgba(255, 255, 255, 0.1);
  transition: all 200ms ease-in-out;
}

.widget-dnd switch:checked {
  background-color: rgba(53, 132, 228, 0.9);
}

/* Compact mode styling */
.widget-dnd.compact {
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 12px;
}

.widget-dnd.compact image {
  margin-right: 8px;
  color: rgba(255, 255, 255, 0.8);
}
```

### Advanced: Custom Colors by State

```css
/* Red DND indicator when active */
.widget-dnd switch:checked {
  background-color: rgba(220, 70, 70, 0.9);
}

/* Change icon color when DND is active */
.widget-dnd.compact:has(switch:checked) image {
  color: rgba(220, 70, 70, 1);
}
```

---

## Removable Widget Headers

### Overview

Widget headers like "Notifications" and "Inhibitors" can be hidden to save vertical space while keeping functionality intact.

### Available Widgets with Headers

- **Title Widget**: Shows "Notifications" header with "Clear All" button
- **Inhibitors Widget**: Shows "Inhibitors" header with "Clear All" button

### Configuration

#### Hide Header, Keep Clear Button

```json
{
  "widget-config": {
    "title": {
      "text": "Notifications",
      "show-header": false,
      "clear-all-button": true,
      "button-text": "Clear"
    }
  }
}
```

Result: Only the "Clear" button is shown, no "Notifications" text.

#### Hide Everything

```json
{
  "widget-config": {
    "title": {
      "show-header": false,
      "clear-all-button": false
    }
  }
}
```

Result: No header or button. The notifications widget itself remains visible.

#### Same for Inhibitors

```json
{
  "widget-config": {
    "inhibitors": {
      "text": "Inhibitors",
      "show-header": false,
      "clear-all-button": true,
      "button-text": "Clear"
    }
  }
}
```

### CSS for Compact Headers

```css
/* Smaller, inline clear button */
.widget-title .notification-row-clear-all {
  font-size: 0.9rem;
  padding: 4px 12px;
  min-height: 24px;
}

/* Remove extra spacing when header is hidden */
.widget-title:not(:has(.header-label)) {
  padding-top: 0;
}
```

---

## Multi-Click Button Support

### Overview

Buttons in `buttons-grid` and `menubar` widgets support different actions for left, middle (scroll wheel), and right mouse clicks. This feature enables more functionality per button without cluttering your interface with extra widgets.

### Basic Configuration

The new `on-click` property allows you to define different commands for each mouse button:

```json
{
  "label": "Power",
  "on-click": {
    "left": "systemctl poweroff",
    "middle": "systemctl reboot",
    "right": "systemctl suspend"
  }
}
```

### Features

- **Left Click**: Primary action (for toggle buttons, maintains toggle state)
- **Middle Click**: Secondary action (scroll wheel click)
- **Right Click**: Tertiary action (context menu alternative)
- **Backward Compatible**: Old single-command format still works

### Toggle Buttons with Multi-Click

For toggle buttons, only the left-click maintains the toggle state. Middle and right clicks execute commands without affecting the toggle:

```json
{
  "label": "WiFi",
  "type": "toggle",
  "on-click": {
    "left": {
      "command": "sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && nmcli radio wifi on || nmcli radio wifi off'",
      "update-command": "sh -c '[[ $(nmcli radio wifi) == \"enabled\" ]] && echo true || echo false'",
      "active": true
    },
    "middle": "nm-connection-editor",
    "right": "notify-send 'WiFi Info' \"$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)\""
  }
}
```

### Practical Use Cases

#### 1. Volume Control Button

```json
{
  "label": "󰕾",
  "on-click": {
    "left": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
    "middle": "pavucontrol",
    "right": "pactl set-sink-volume @DEFAULT_SINK@ 100%"
  }
}
```

- Left: Mute/unmute
- Middle: Open volume control GUI
- Right: Set volume to 100%

#### 2. Screenshot Button

```json
{
  "label": "📸",
  "on-click": {
    "left": "grimblast copy screen",
    "middle": "grimblast copy area",
    "right": "grimblast save screen ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
  }
}
```

- Left: Screenshot to clipboard
- Middle: Select area to clipboard
- Right: Save full screenshot to file

#### 3. Bluetooth Toggle with Management

```json
{
  "label": "Bluetooth",
  "type": "toggle",
  "on-click": {
    "left": {
      "command": "bluetooth toggle",
      "update-command": "sh -c '[[ $(bluetooth) == \"on\" ]] && echo true || echo false'",
      "active": false
    },
    "middle": "blueman-manager",
    "right": "bluetoothctl devices"
  }
}
```

- Left: Toggle Bluetooth on/off
- Middle: Open Bluetooth manager
- Right: List connected devices

### CSS Styling

Multi-click buttons use the same CSS classes as regular buttons, but you can add custom styling for visual feedback:

```css
/* Add hover effect showing multi-click capability */
.widget-buttons-grid button,
.widget-menubar button {
  position: relative;
  transition: all 200ms ease;
}

/* Subtle indicator that button has multiple actions */
.widget-buttons-grid button::after {
  content: "⋮";
  position: absolute;
  top: 2px;
  right: 4px;
  font-size: 0.7rem;
  opacity: 0.3;
  transition: opacity 200ms ease;
}

.widget-buttons-grid button:hover::after {
  opacity: 0.6;
}

/* Different cursor on hover to indicate interactivity */
.widget-buttons-grid button:hover {
  cursor: pointer;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}
```

### Tips for Better UX

1. **Left Click = Primary Action**: Always put the most common action on left-click
2. **Middle Click = Settings/Config**: Use middle-click for opening settings or configuration
3. **Right Click = Info/Alternative**: Use right-click for showing info or alternative actions
4. **Use Icons**: Icon labels work well with multi-click (saves space, looks clean)
5. **Document Actions**: Consider tooltips or documentation for your custom actions

### Complete Widget Example

Here's a complete `buttons-grid` configuration using multi-click:

```json
{
  "buttons-grid": {
    "buttons-per-row": 4,
    "actions": [
      {
        "label": "󰕾",
        "on-click": {
          "left": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
          "middle": "pavucontrol",
          "right": "pactl set-sink-volume @DEFAULT_SINK@ 100%"
        }
      },
      {
        "label": "WiFi",
        "type": "toggle",
        "on-click": {
          "left": {
            "command": "sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && nmcli radio wifi on || nmcli radio wifi off'",
            "update-command": "sh -c '[[ $(nmcli radio wifi) == \"enabled\" ]] && echo true || echo false'",
            "active": true
          },
          "middle": "nm-connection-editor",
          "right": "notify-send 'Network' \"$(ip -br a)\""
        }
      },
      {
        "label": "󰌌",
        "on-click": {
          "left": "brightnessctl set 10%-",
          "middle": "brightnessctl set 50%",
          "right": "brightnessctl set 10%+"
        }
      },
      {
        "label": "⏻",
        "on-click": {
          "left": "systemctl suspend",
          "middle": "systemctl reboot",
          "right": "systemctl poweroff"
        }
      }
    ]
  }
}
```

### Backward Compatibility

The old configuration format still works perfectly:

```json
{
  "label": "Legacy Button",
  "command": "notify-send 'Hello'",
  "type": "normal"
}
```

You can mix old and new formats in the same widget:

```json
{
  "actions": [
    {
      "label": "New Style",
      "on-click": {
        "left": "command1",
        "right": "command2"
      }
    },
    {
      "label": "Old Style",
      "command": "single-command",
      "type": "normal"
    }
  ]
}
```

---

## Complete Examples

### Example 1: Minimal Compact Layout

Maximum space efficiency with no redundant headers.

**config.json:**

```json
{
  "$schema": "/etc/xdg/swaync/configSchema.json",
  "control-center-show-main-label": false,
  "control-center-width": 380,
  "control-center-height": 500,
  "widgets": [
    "dnd",
    "title",
    "notifications"
  ],
  "widget-config": {
    "dnd": {
      "text": "Silent Mode",
      "show-label": false
    },
    "title": {
      "text": "Notifications",
      "show-header": false,
      "clear-all-button": true,
      "button-text": "✕ Clear"
    },
    "notifications": {
      "vexpand": true
    }
  }
}
```

**style.css:**

```css
/* Minimal compact control center */
.control-center {
  background: rgba(30, 30, 46, 0.95);
  border-radius: 12px;
  padding: 8px;
}

/* Compact DND row */
.widget-dnd.compact {
  padding: 6px 12px;
  margin-bottom: 8px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 8px;
}

.widget-dnd.compact image {
  margin-right: 8px;
}

/* Small clear button */
.widget-title {
  padding: 4px 8px;
  margin-bottom: 8px;
}

.widget-title button {
  font-size: 0.85rem;
  padding: 4px 12px;
  min-height: 28px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.05);
}

.widget-title button:hover {
  background: rgba(255, 255, 255, 0.1);
}

/* Compact notifications */
.notification {
  padding: 8px;
  margin: 4px 0;
  border-radius: 8px;
}
```

### Example 2: Traditional Layout with Headers

Clear sections with visible headers.

**config.json:**

```json
{
  "$schema": "/etc/xdg/swaync/configSchema.json",
  "control-center-show-main-label": true,
  "control-center-width": 500,
  "widgets": [
    "inhibitors",
    "dnd",
    "title",
    "notifications"
  ],
  "widget-config": {
    "label#main": {
      "text": "Control Center",
      "max-lines": 1
    },
    "inhibitors": {
      "text": "Inhibitors",
      "show-header": true,
      "clear-all-button": true,
      "button-text": "Clear All"
    },
    "dnd": {
      "text": "Do Not Disturb",
      "show-label": true
    },
    "title": {
      "text": "Notifications",
      "show-header": true,
      "clear-all-button": true,
      "button-text": "Clear All"
    }
  }
}
```

**style.css:**

```css
/* Traditional control center with clear sections */
.widget-label.main {
  font-size: 1.4rem;
  font-weight: bold;
  padding: 16px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.1);
}

.widget-inhibitors,
.widget-title {
  padding: 12px 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.widget-dnd {
  padding: 12px 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.widget-dnd label {
  font-size: 1.1rem;
  font-weight: 500;
}
```

### Example 3: Waybar-Style Compact

Mimics Waybar's minimal aesthetic.

**config.json:**

```json
{
  "$schema": "/etc/xdg/swaync/configSchema.json",
  "control-center-show-main-label": false,
  "control-center-width": 360,
  "control-center-height": 600,
  "positionX": "right",
  "positionY": "top",
  "control-center-margin-top": 8,
  "control-center-margin-right": 8,
  "widgets": [
    "dnd",
    "title",
    "notifications"
  ],
  "widget-config": {
    "dnd": {
      "text": "DND",
      "show-label": false
    },
    "title": {
      "show-header": false,
      "clear-all-button": true,
      "button-text": ""
    },
    "notifications": {
      "vexpand": true
    }
  }
}
```

**style.css:**

```css
/* Waybar-inspired styling */
.control-center {
  background: #1e1e2e;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  padding: 6px;
}

/* Icon-only DND with hover effect */
.widget-dnd.compact {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 10px;
  margin: 4px 0;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 6px;
  transition: background 150ms ease;
}

.widget-dnd.compact:hover {
  background: rgba(255, 255, 255, 0.05);
}

.widget-dnd switch {
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.widget-dnd switch:checked {
  background: #89b4fa;
  border-color: #89b4fa;
}

/* Icon-only clear button */
.widget-title button {
  padding: 6px;
  min-width: 32px;
  min-height: 32px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.03);
}

.widget-title button::before {
  content: "×";
  font-size: 1.4rem;
  line-height: 1;
}

/* Compact notification cards */
.notification {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 10px;
  margin: 4px 0;
}

.notification:hover {
  background: rgba(255, 255, 255, 0.05);
  border-color: rgba(255, 255, 255, 0.1);
}
```

---

## CSS Customization

### Available CSS Classes

#### Control Center Main Label

- `.widget-label.main` - Main control center title (when enabled)

#### DND Widget

- `.widget-dnd` - DND widget container
- `.widget-dnd.compact` - DND in compact/icon-only mode
- `.widget-dnd label` - Text label (hidden in compact mode)
- `.widget-dnd image` - Icon (visible in compact mode)
- `.widget-dnd switch` - The toggle switch
- `.widget-dnd switch:checked` - Switch when DND is active

#### Title Widget

- `.widget-title` - Title widget container
- `.widget-title .header-label` - Header text
- `.widget-title button` - Clear all button

#### Inhibitors Widget

- `.widget-inhibitors` - Inhibitors widget container
- `.widget-inhibitors .header-label` - Header text
- `.widget-inhibitors button` - Clear all button

### CSS Variables

You can use CSS variables for consistent theming:

```css
:root {
  --cc-bg: rgba(30, 30, 46, 0.95);
  --cc-border: rgba(255, 255, 255, 0.1);
  --cc-border-radius: 12px;

  --widget-bg: rgba(255, 255, 255, 0.03);
  --widget-bg-hover: rgba(255, 255, 255, 0.06);

  --accent-color: rgba(137, 180, 250, 0.9);
  --accent-color-hover: rgba(137, 180, 250, 1);

  --text-color: rgba(255, 255, 255, 0.9);
  --text-secondary: rgba(255, 255, 255, 0.6);
}

.control-center {
  background: var(--cc-bg);
  border: 1px solid var(--cc-border);
  border-radius: var(--cc-border-radius);
}

.widget-dnd.compact {
  background: var(--widget-bg);
}

.widget-dnd.compact:hover {
  background: var(--widget-bg-hover);
}

.widget-dnd switch:checked {
  background-color: var(--accent-color);
}
```

### Animation Examples

#### Smooth Transitions

```css
.widget-dnd,
.widget-title button,
.notification {
  transition: all 200ms cubic-bezier(0.4, 0, 0.2, 1);
}
```

#### Slide-in Animations

```css
@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.notification {
  animation: slideIn 250ms ease-out;
}
```

#### Pulse on DND Toggle

```css
@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

.widget-dnd switch:checked {
  animation: pulse 300ms ease;
}
```

---

## Accessibility

All compact modes maintain full accessibility:

- **Keyboard Navigation**: Tab through widgets, Space/Enter to activate
- **Screen Readers**: ARIA labels provide context even without visible text
- **Tooltips**: Hover tooltips show full text in compact modes
- **Focus Indicators**: Clear focus rings on all interactive elements

### Testing Accessibility

1. **Keyboard Only**: Navigate using only Tab, Shift+Tab, Space, Enter
2. **Screen Reader**: Test with Orca or other screen readers
3. **High Contrast**: Verify visibility with high contrast themes
4. **Font Scaling**: Test with larger system fonts

---

## Troubleshooting

### Changes Not Applying

1. Reload config: `swaync-client -R`
2. Reload CSS: `swaync-client -rs`
3. Restart daemon if needed: `killall swaync && swaync`

### Widget Not Showing

- Check widget is in `"widgets"` array
- Verify widget name spelling (case-sensitive)
- Check for JSON syntax errors

### CSS Not Working

- Ensure file is at `~/.config/swaync/style.css`
- Check CSS syntax (missing semicolons, brackets)
- Use GTK Inspector: `GTK_DEBUG=interactive swaync`

### Compact Mode Issues

- Verify `"show-label": false` in widget-config
- Check icon names are correct (symbolic icons)
- Clear CSS cache and reload

---

## Further Reading

- [Main Configuration Guide](../man/swaync.5.scd)
- [Widget Reference](../CLAUDE.md#widget-system)
- [CSS Styling Guide](../data/style/README.md)
- [Notification Specification](https://specifications.freedesktop.org/notification-spec/)

---

**Happy Customizing!** 🎨

For questions or issues, visit: [GitHub Issues](https://github.com/ErikReider/SwayNotificationCenter/issues)
