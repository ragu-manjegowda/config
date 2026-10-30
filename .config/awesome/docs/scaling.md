# Shared display and text sizing

Font descriptions retain point sizes. Pango applies the rendering DPI, so font
sizes must not be passed through `apply_dpi` a second time. Fallback families
precede the final point size, for example `Hack Nerd Font Mono, Noto Color Emoji 12`.

`library.text-metrics` measures line heights with Pango at the selected DPI.
Email and calendar rows reserve measured text heights plus their padding and
spacing. Primary calendar titles retain two lines; compact concurrent-event
rows retain one. Each calendar viewport also exposes the height of a complete
card to the shared Info Center allocator. Existing list scrolling is preserved.

Screen geometry and workarea sizes are already pixels. Scale design dimensions
once, then constrain the popup to the available workarea. The shared Run menu
uses font-relative dimensions with screen-relative caps rather than a percentage
width coupled to fixed-pixel icons. It remains bounded on small high-DPI screens.

An optional `display.cursor_size` in any machine profile controls GTK 2, GTK 3,
Xsettings and Awesome's X resources consistently. The toolkit renderer preserves
theme names and existing font preferences; profiles without that override keep
their existing toolkit cursor settings. Darkman reapplies the selected size
after a theme change. Restart Awesome after changing its configured DPI.

## Regression checks

```sh
HOME="$PWD" luajit .config/awesome/tests/test_text_sizing.lua
HOME="$PWD" lua .config/awesome/tests/test_card_scrolling.lua
HOME="$PWD" lua .config/awesome/tests/test_center_geometry.lua
python3 .config/awesome/tests/test_rofi_sizing.py
python3 .config/awesome/tests/test_toolkit_cursor.py
```

The font test renders real Pango fonts at 96, 120, 144 and 192 DPI while feeding
synthetic email/calendar data into the widgets. No personal messages or OAuth
sessions are read. The Rofi test creates private Xvfb displays, including
1920×1200 and 1920×1080 at 96 DPI, 2880×1800 and 3440×1440 at 144 DPI, and
800×600 at 192 DPI. It checks both screen containment and stable readable width.
