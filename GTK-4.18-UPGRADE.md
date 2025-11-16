# GTK 4.18+ Upgrade

## Overview

This branch has been upgraded to require GTK 4.18+ and libadwaita 1.8+ for improved performance and access to modern APIs.

## Changes

### Dependency Requirements

**Updated versions:**

- GTK4: `>= 4.18.0` (previously 4.16.13)
- GTK4-Wayland: `>= 4.18.0` (previously 4.16.5)
- libadwaita: `>= 1.8.0` (previously 1.6.1)

### Code Modernization

1. **Widget visibility**: Replaced deprecated `hide()` with `set_visible(false)`
   - File: `src/controlCenter/widgets/backlight/backlight.vala`

2. **Width queries**: Replaced deprecated `get_allocated_width()` with `get_width()`
   - File: `src/iterHelpers/responsiveGrid.vala`

3. **CSS loading**: Added comments for `StyleContext` usage (no replacement available)
   - File: `src/functions.vala`
   - Note: `StyleContext.add_provider_for_display()` is deprecated but still needed for global CSS

### Benefits

✅ **Fewer deprecation warnings** during compilation
✅ **Access to GTK 4.18+ features** (improved layouts, better CSS support)
✅ **libadwaita 1.8 features** (new adaptive widgets, improved transitions)
✅ **Better performance** with newer GTK optimizations

### Compatibility

⚠️ **Breaking Change**: This upgrade may prevent compilation on older distributions:

- Debian 12 (bookworm): Has GTK 4.8 - **won't work**
- Ubuntu 24.04 LTS: Has GTK 4.14 - **won't work**
- Fedora 40+: Has GTK 4.18+ - ✅ **compatible**
- Arch Linux: Rolling release - ✅ **compatible**

## Remaining Deprecation Warnings

Some deprecation warnings remain but cannot be eliminated without breaking functionality:

- `Gtk.StyleContext`: Used for global CSS loading, no direct replacement
- PulseAudio warnings: From upstream libpulse, not our code

## Testing

After building with these changes, test:

1. Control center responsiveness
2. Widget tooltips
3. Volume/backlight sliders with percentage labels
4. Button grid responsive layout
5. MPRIS widget customization

## Reverting

To revert to older GTK requirements, restore these values in `src/meson.build`:

```meson
dependency('gtk4', version: '>= 4.16.13'),
dependency('gtk4-wayland', version: '>= 4.16.5'),
dependency('libadwaita-1', version: '>= 1.6.1'),
```

And change back the deprecated API calls.
