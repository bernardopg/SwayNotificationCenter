# Responsive Control Center for SwayNC

## Overview

This feature adds flexible grid layout and responsive design capabilities to the SwayNotificationCenter control center, allowing widgets to be displayed in multiple columns for better space utilization.

## New Configuration Options

### `control-center-columns`
- **Type**: integer
- **Default**: `1`
- **Range**: `1-4`
- **Description**: Number of columns for widget layout in the control center
  - `1`: Traditional vertical layout (default)
  - `2+`: Grid layout with specified number of columns

### `control-center-responsive`
- **Type**: boolean  
- **Default**: `false`
- **Description**: Enable responsive layout that automatically adjusts columns based on control center width
  - **Breakpoints**:
    - `< 400px`: 1 column
    - `400-799px`: 2 columns
    - `800-1199px`: 3 columns
    - `≥ 1200px`: 4 columns

## Configuration Examples

### Fixed 2-Column Layout
```json
{
  "control-center-width": 800,
  "control-center-columns": 2,
  "control-center-responsive": false,
  "widgets": [
    "mpris",
    "title",
    "dnd",
    "inhibitors",
    "notifications"
  ]
}
```

### Responsive Layout
```json
{
  "control-center-width": 1000,
  "control-center-responsive": true,
  "widgets": [
    "mpris",
    "title",
    "dnd",
    "volume",
    "backlight",
    "notifications"
  ]
}
```

### Compact 3-Column Dashboard
```json
{
  "control-center-width": 900,
  "control-center-columns": 3,
  "widgets": [
    "title",
    "dnd",
    "inhibitors",
    "mpris",
    "volume",
    "backlight",
    "notifications"
  ]
}
```

## Use Cases

### Wide Screen Setup
Perfect for ultra-wide monitors or when you want to maximize horizontal space:
```json
{
  "control-center-width": 1200,
  "control-center-columns": 4,
  "control-center-height": 600
}
```

### Tablet/Foldable Devices
Use responsive mode to adapt automatically:
```json
{
  "control-center-responsive": true,
  "fit-to-screen": true
}
```

### Compact Mode
Reduce vertical space by spreading widgets horizontally:
```json
{
  "control-center-width": 600,
  "control-center-height": 400,
  "control-center-columns": 2
}
```

## Widget Behavior

- Widgets are placed left-to-right, top-to-bottom
- Each widget expands horizontally to fill its column
- The `notifications` widget typically works best spanning full width at the bottom
- Consider widget natural sizes when choosing column count

## Implementation Details

### Technical Changes
- New `ResponsiveGrid` class extends `Gtk.Grid`
- Dynamic container switching between `IterBox` (vertical) and `ResponsiveGrid` (columns)
- Config reload triggers container recreation and widget re-layout
- CSS class `widgets` applied to both containers for consistent styling

### Files Modified
- `src/iterHelpers/responsiveGrid.vala`: New responsive grid widget
- `src/controlCenter/controlCenter.vala`: Dynamic container management
- `src/configModel/configModel.vala`: Added config properties
- `src/configSchema.json`: Schema definitions
- `src/meson.build`: Added responsiveGrid.vala to build

## Compatibility

- Fully backward compatible - defaults to 1 column (traditional layout)
- Works with all existing widgets
- Compatible with layer-shell positioning
- Respects existing width/height settings

## Testing

Test different configurations:
```bash
# 2-column layout
jq '.["control-center-columns"] = 2 | .["control-center-width"] = 800' \
   ~/.config/hypr/swaync/config.json > /tmp/config.json
mv /tmp/config.json ~/.config/hypr/swaync/config.json
swaync-client --reload-config

# Responsive mode
jq '.["control-center-responsive"] = true | .["control-center-width"] = 1000' \
   ~/.config/hypr/swaync/config.json > /tmp/config.json
mv /tmp/config.json ~/.config/hypr/swaync/config.json  
swaync-client --reload-config
```

## Future Enhancements

Potential improvements:
- Per-widget column span control (e.g., `"notifications": { "column-span": 2 }`)
- Row-based layouts
- Custom breakpoints for responsive mode
- Widget-specific responsive behavior
