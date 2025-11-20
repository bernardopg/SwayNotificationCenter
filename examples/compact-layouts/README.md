# Compact Layouts Examples

This directory contains ready-to-use configuration examples showcasing different UX styles for SwayNotificationCenter.

## Available Layouts

### 1. Minimal Compact

**Files:** `minimal-compact.json` + `minimal-compact.css`

**Description:** Ultra-minimal design with maximum space efficiency. Perfect for small displays or users who prioritize content over chrome.

**Features:**
- No main title header
- Icon-only DND widget
- Hidden notification header (only clear button visible)
- Compact notification cards
- 380px width

**Best for:** Small screens, minimal aesthetics, space-conscious users

**Preview:**
```
┌─────────────────┐
│ 🔔 [====]      │  ← Icon-only DND
│          ✕ Clear│  ← Clear button only
│ ┌─────────────┐│
│ │ Notification││
│ │ Content     ││
│ └─────────────┘│
│ ┌─────────────┐│
│ │ Notification││
│ └─────────────┘│
└─────────────────┘
```

### 2. Waybar Style

**Files:** `waybar-style.json` + `waybar-style.css`

**Description:** Mimics Waybar's clean and minimal aesthetic with Catppuccin Mocha color scheme.

**Features:**
- No headers
- Icon-only DND widget
- Icon-only clear button (× symbol)
- Minimal borders and spacing
- 360px width
- Catppuccin Mocha colors

**Best for:** Waybar users, Catppuccin fans, ultra-minimal setups

**Preview:**
```
┌───────────────┐
│ 🔔 [====]    │  ← Icon-only DND
│           ×   │  ← Icon-only clear
│ ┌───────────┐│
│ │ Notif...  ││  ← Very compact
│ └───────────┘│
└───────────────┘
```

### 3. Traditional Full

**Files:** `traditional-full.json` + `traditional-full.css`

**Description:** Classic notification center with all headers visible and clear section separation.

**Features:**
- Main "Control Center" title at top
- Inhibitors section with header
- Full DND widget with label
- Notification section with header
- All clear buttons visible
- Generous spacing and borders
- 480px width

**Best for:** Users who prefer traditional layouts, clarity over compactness

**Preview:**
```
┌─────────────────────┐
│   Control Center    │  ← Main title
├─────────────────────┤
│ Inhibitors  Clear All│
├─────────────────────┤
│ Do Not Disturb [==] │
├─────────────────────┤
│ Notifications Clear │
├─────────────────────┤
│ ┌─────────────────┐│
│ │ Notification    ││
│ │ Full content... ││
│ └─────────────────┘│
└─────────────────────┘
```

## Installation

### Quick Install

Choose one layout and copy both files:

```bash
# Example: Install Minimal Compact layout
cp minimal-compact.json ~/.config/swaync/config.json
cp minimal-compact.css ~/.config/swaync/style.css

# Reload configuration
swaync-client -R  # Reload config
swaync-client -rs # Reload CSS
```

### Manual Install

1. **Backup your current config:**
   ```bash
   cp ~/.config/swaync/config.json ~/.config/swaync/config.json.backup
   cp ~/.config/swaync/style.css ~/.config/swaync/style.css.backup
   ```

2. **Copy desired layout:**
   ```bash
   cp <layout-name>.json ~/.config/swaync/config.json
   cp <layout-name>.css ~/.config/swaync/style.css
   ```

3. **Reload SwayNotificationCenter:**
   ```bash
   swaync-client -R
   swaync-client -rs
   ```

4. **Test the layout:**
   ```bash
   swaync-client -t  # Toggle control center
   ```

### Testing Without Installing

You can test a layout without overwriting your config:

```bash
# Kill current daemon
killall swaync

# Run with test config
swaync --config /path/to/example.json --style /path/to/example.css
```

## Customization

All layouts are fully customizable. Here are common tweaks:

### Change Width

Edit the JSON file:
```json
{
  "control-center-width": 400  // Change to desired width
}
```

### Change Position

```json
{
  "positionX": "left",  // "left", "center", or "right"
  "positionY": "bottom" // "top", "center", or "bottom"
}
```

### Adjust Margins

```json
{
  "control-center-margin-top": 10,
  "control-center-margin-right": 10,
  "control-center-margin-bottom": 0,
  "control-center-margin-left": 0
}
```

### Change Colors

Edit the CSS file. Most layouts use CSS variables:

```css
/* Add to the top of the CSS file */
:root {
  --cc-bg: rgba(20, 20, 30, 0.95);  /* Control center background */
  --accent-color: rgba(100, 150, 255, 0.9); /* Accent color */
  --text-color: rgba(255, 255, 255, 0.9);   /* Text color */
}
```

### Mix and Match

You can combine elements from different layouts:

1. Start with one layout's JSON
2. Take CSS snippets from other layouts
3. Adjust to your preference

Example: Minimal Compact config + Waybar Style colors:
```bash
cp minimal-compact.json ~/.config/swaync/config.json
cp waybar-style.css ~/.config/swaync/style.css
```

## Feature Comparison

| Feature                    | Minimal | Waybar | Traditional |
|----------------------------|---------|--------|-------------|
| Main Title                 | ✗       | ✗      | ✓           |
| Inhibitors Widget          | ✗       | ✗      | ✓           |
| DND Label                  | ✗       | ✗      | ✓           |
| DND Icon                   | ✓       | ✓      | ✗           |
| Section Headers            | ✗       | ✗      | ✓           |
| Clear Button Text          | ✓       | ✗      | ✓           |
| Width                      | 380px   | 360px  | 480px       |
| Spacing                    | Compact | Minimal| Generous    |
| Best for                   | Efficiency | Style | Clarity   |

## Configuration Anatomy

### Key Config Options

```json
{
  // Enable/disable main title
  "control-center-show-main-label": true,

  // Widget order and selection
  "widgets": [
    "inhibitors",  // Optional: notification inhibitors
    "dnd",         // Required: Do Not Disturb toggle
    "title",       // Optional: section header with clear button
    "notifications" // Required: must be present
  ],

  // Per-widget configuration
  "widget-config": {
    // Main title (when enabled)
    "label#main": {
      "text": "Control Center",
      "max-lines": 1
    },

    // DND widget
    "dnd": {
      "text": "Do Not Disturb",
      "show-label": false  // false = icon-only mode
    },

    // Title/header widget
    "title": {
      "text": "Notifications",
      "show-header": false,      // Hide "Notifications" text
      "clear-all-button": true,   // Show clear button
      "button-text": "✕ Clear"   // Button text
    },

    // Inhibitors widget (optional)
    "inhibitors": {
      "text": "Inhibitors",
      "show-header": true,
      "clear-all-button": true,
      "button-text": "Clear All"
    }
  }
}
```

### Key CSS Classes

```css
/* Main title (when enabled) */
.widget-label.main { }

/* DND widget */
.widget-dnd { }
.widget-dnd.compact { }  /* When show-label: false */
.widget-dnd switch { }
.widget-dnd switch:checked { }

/* Title widget */
.widget-title { }
.widget-title .header-label { }  /* Header text */
.widget-title button { }         /* Clear button */

/* Inhibitors widget */
.widget-inhibitors { }

/* Notifications */
.notification { }
.notification:hover { }
.notification-content .summary { }
.notification-content .body { }
.notification-content .time { }

/* Notification groups */
.notification-group-header { }
```

## Troubleshooting

### Layout not applying

```bash
# Verify config syntax
cat ~/.config/swaync/config.json | jq .

# Check for CSS errors
# Look for typos in CSS file

# Force reload
killall swaync
swaync &
```

### Colors look wrong

- Check if `"ignore-gtk-theme": true` is set in config
- Verify CSS file location: `~/.config/swaync/style.css`
- Use GTK Inspector: `GTK_DEBUG=interactive swaync`

### Widget not showing

- Ensure widget is in `"widgets"` array
- Check spelling (case-sensitive)
- Verify JSON syntax with `jq`

### CSS not working

- Verify file path: `~/.config/swaync/style.css`
- Check for syntax errors (missing `;` or `}`)
- Reload CSS: `swaync-client -rs`

## Further Resources

- [UX Customization Guide](../../docs/UX-CUSTOMIZATION.md) - Complete guide
- [Configuration Schema](../../src/configSchema.json) - All options
- [Man Page](../../man/swaync.5.scd) - Official documentation
- [GitHub Issues](https://github.com/ErikReider/SwayNotificationCenter/issues) - Support

## Contributing

Have a cool layout to share? Submit a pull request with:

1. `your-layout.json` - Configuration file
2. `your-layout.css` - Stylesheet
3. Update this README with description and preview

## License

These examples are provided under the same license as SwayNotificationCenter (GPL-3.0).

---

**Enjoy your customized notification center!** 🎨
