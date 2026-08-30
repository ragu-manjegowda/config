# AwesomeWM Design System

## 1. Atmosphere & Identity

A focused Solarized command surface: operational, compact, and quiet. Full-screen tools isolate one task at a time over a translucent desktop, while rounded tonal groups and a single theme accent communicate hierarchy without ornamental motion.

## 2. Color

| Role | Theme token | Dark value | Usage |
|---|---|---|---|
| Overlay | `beautiful.background` | `#002b3666` | Full-screen tool background |
| Surface | `beautiful.groups_bg` | `#073642` | Buttons, fields, grouped controls |
| Text | `beautiful.fg_normal` | `#eee8d5` | Labels and values |
| Muted text | `beautiful.fg_normal` with reduced alpha | theme-derived | Secondary geometry details |
| Accent | `beautiful.accent` | `#859900` | Selected source, focus, active state |
| Error | `beautiful.bg_urgent` | `#cb4b16` | Invalid or unavailable actions |
| Transparent | `beautiful.transparent` | `#00000000` | Resting interaction layer |

Only theme tokens may define product colors. Light mode uses the corresponding Solarized light tokens.

## 3. Typography

- Primary: `beautiful.font_regular(size)` using Hack Nerd Regular.
- Emphasis: `beautiful.font_bold(size)` using Hack Nerd Bold.
- Labels and values: 16px equivalent through the existing theme helpers.
- Instructional hints and keyboard mappings: 12px caption text.
- Numeric geometry uses the mono-compatible Hack Nerd family and tabular alignment.

## 4. Spacing & Layout

- Base unit: 4 logical pixels, always passed through `dpi()` for spatial dimensions.
- Existing recorder controls use 8, 16, and 24 logical-pixel spacing steps.
- Recorder settings remain a centered vertical stack, expanding from 240 to 320 logical pixels only when needed for readable labels.
- Controls must remain usable on every Awesome screen geometry; the overlay owns the full screen and the settings group owns its intrinsic height.

## 5. Components

### Circular action button
- Structure: SVG image inside `clickable-container`, margin container, tonal circular background.
- States: default, hover, pressed, disabled.
- Usage: record, microphone, settings, and close actions.

### Capture source selector
- Structure: a 2x2 grid of Primary, External, Both, and Select area controls.
- States: default, selected, hover, pressed, unavailable.
- Selected state uses the theme accent border; unavailable targets remain visible but muted and non-actionable.
- Keyboard access uses the existing settings keygrabber without stealing the recorder's global controls.
- Keys `1`, `2`, `3`, and `4` choose Primary, External, Both, and Area; Escape returns to the recorder.
- Source, microphone mode, and last custom region persist under `XDG_STATE_HOME/awesome/screen-recorder/settings`.
- Choosing Area reuses the saved region; choosing Area again while active starts a redraw.

### Capture area summary
- Structure: read-only source label followed by `width x height` and `x,y` geometry.
- States: resolved, custom region, unavailable, selection cancelled.
- Raw resolution and offset are not directly editable; geometry is derived from a display or validated mouse selection.

### Area selection overlay
- Structure: recorder overlays hide before `slop` receives pointer input, then the originating settings panel returns.
- States: selecting, selected, cancelled, invalid.
- Selection motion is provided only by `slop`; the Awesome UI adds no decorative animation.

## 6. Motion & Interaction

- Existing hover, press, and release color feedback remains immediate and interruptible.
- Settings navigation remains an instant panel state change; no layout animation is introduced.
- Selecting an area is a modal pointer operation: hide recorder overlays, select or cancel, then restore the originating panel.
- Recording settings are frozen when countdown begins and cannot change while recording.

## 7. Depth & Surface

Use tonal shift only. The translucent full-screen background separates the tool from the desktop; `groups_bg` separates controls from the overlay. Rounded corners use `beautiful.groups_radius`; selected controls may add a one-pixel accent border.

## 8. Accessibility Constraints & Accepted Debt

### Constraints
- Every action has text or an existing recognizable SVG icon.
- Selected, disabled, and error states must not rely on color alone; labels and availability text remain explicit.
- Right-click or Escape cancels area selection without changing the saved preference.
- External and Both are disabled when the configured external output is unavailable.
- Selection dimensions are normalized to even values for H.264 and rejected below a practical minimum.

### Accepted Debt

| Item | Location | Why accepted | Exit |
|---|---|---|---|
| Pointer area selection is X11-only | Screen recorder | AwesomeWM currently runs on X11 and FFmpeg uses `x11grab` | Replace alongside any future Wayland recorder backend |
