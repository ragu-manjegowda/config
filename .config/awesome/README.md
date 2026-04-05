
# Awesome Window Manager

<!--toc:start-->
- [Awesome Window Manager](#awesome-window-manager)
  - [Credits](#credits)
  - [Directory Structure](#directory-structure)
  - [Panels and Layouts](#panels-and-layouts)
  - [Widgets](#widgets)
    - [Top Panel](#top-panel)
    - [Control Center](#control-center)
    - [Info Center](#info-center)
    - [Calendar Center](#calendar-center)
    - [Playerctl Center](#playerctl-center)
  - [Modules](#modules)
  - [Outlook Calendar via Microsoft Graph API](#outlook-calendar-via-microsoft-graph-api)
  - [Theme](#theme)
  - [Configuration](#configuration)
    - [Display](#display)
    - [Weather](#weather)
    - [Stocks](#stocks)
    - [Calendar Events](#calendar-events)
    - [Dynamic Wallpaper](#dynamic-wallpaper)
    - [Lockscreen](#lockscreen)
    - [Screen Recorder](#screen-recorder)
  - [Key Bindings](#key-bindings)
  - [Startup Applications](#startup-applications)
  - [Utilities](#utilities)
  - [CI/CD](#cicd)
<!--toc:end-->


## Credits

Borrowed `surreal` theme of [the-glorious-dotfiles](https://github.com/manilarome/the-glorious-dotfiles) as reference and built my own 
version on top of it with extensive modifications for a production desktop environment on Arch Linux.


## Directory Structure

```sh
~/.config/awesome/
├── rc.lua                        # Main entry point
├── README.md                     # This file
│
├── configuration/                # All configuration
│   ├── config.lua                # Central config (display, widgets, modules)
│   ├── apps.lua                  # Default apps, startup list, utility paths
│   ├── client/                   # Client rules and titlebars
│   ├── keys/                     # Keybindings (global.lua, mod.lua)
│   ├── tags/                     # Tag definitions (9 icon-based tags)
│   ├── picom.conf                # Compositor configuration
│   ├── rofi/                     # Rofi themes (runmenu, appmenu, emoji, calc, time)
│   └── user-profile/             # User profile picture
│
├── layout/                       # Panel layouts
│   ├── init.lua                  # Panel creation per screen
│   ├── top-panel.lua             # Top bar
│   ├── control-center/           # System controls popup
│   ├── info-center/              # Notifications + email + stocks + calendar + weather
│   ├── calendar-center/          # Month calendar popup with clock
│   └── playerctl-center/         # Media player controls popup
│
├── widget/                       # 40 custom widgets
│   ├── battery/                  # Battery indicator with UPower
│   ├── calendar/                 # Month calendar with navigation
│   ├── calendar-events/          # Outlook calendar events list
│   ├── clock/                    # Clock widget
│   ├── email/                    # Email count (Outlook via OAuth2)
│   ├── notif-center/             # Notification center with history
│   ├── playerctl/                # Media player controls (via bling)
│   ├── screen-recorder/          # Screen recording toggle
│   ├── stocks/                   # Stock price ticker
│   ├── tag-list/                 # Workspace tag indicators
│   ├── task-list/                # Active window list
│   ├── weather/                  # Multi-provider weather
│   ├── brightness-slider/        # Display brightness control
│   ├── volume-slider/            # Volume control
│   ├── cpu-meter/                # CPU usage meter
│   ├── ram-meter/                # RAM usage meter
│   ├── harddrive-meter/          # Disk usage meter
│   ├── temperature-meter/        # Temperature monitor
│   ├── blue-light/               # Blue light filter toggle (redshift)
│   ├── bluetooth-toggle/         # Bluetooth on/off
│   ├── airplane-mode/            # Airplane mode toggle
│   ├── vpn/                      # VPN status/toggle
│   ├── kbd-battery/              # Keyboard battery level
│   ├── kbd-brightness-slider/    # Keyboard backlight slider
│   └── ...                       # Additional UI widgets
│
├── module/                       # System modules
│   ├── auto-start.lua            # Startup application launcher
│   ├── brightness-osd.lua        # Display brightness OSD
│   ├── kbd-brightness-osd.lua    # Keyboard brightness OSD
│   ├── volume-osd.lua            # Volume OSD
│   ├── mic-osd.lua               # Microphone mute/unmute OSD
│   ├── dynamic-wallpaper.lua     # Time-of-day wallpaper scheduler
│   ├── lockscreen.lua            # Lock screen with PAM auth
│   ├── exit-screen.lua           # Shutdown/reboot/suspend menu
│   ├── notifications.lua         # Notification handling
│   └── screen-manager.lua        # Multi-monitor connect/disconnect
│
├── utilities/                    # Shell/Python helper scripts
│   ├── outlook-calendar          # Fetch Outlook events via Graph API
│   ├── setup-monitors            # Configure display arrangement
│   ├── connect-external          # Handle external monitor connection
│   ├── disconnect-external       # Handle external monitor disconnection
│   ├── read-display-config       # Read display config from config.lua
│   ├── snap                      # Screenshot (full/area)
│   ├── capture                   # Webcam capture (lockscreen intruder)
│   ├── kbd-bkl                   # Keyboard backlight control
│   ├── suspend-hook.py           # Wallpaper update on resume from sleep
│   ├── volctl                    # Volume control tray applet
│   ├── touchpad-toggle           # Toggle touchpad on/off
│   ├── profile-image             # Update user profile picture
│   ├── time                      # Show time via rofi
│   ├── location                  # Geolocation utility
│   └── icc-matcher               # ICC color profile matcher
│
├── theme/                        # Theme configuration
│   ├── init.lua                  # Theme loader (selects active theme)
│   ├── default-theme.lua         # Base theme defaults
│   ├── solarized-dark-theme/     # Solarized dark color scheme
│   ├── solarized-light-theme/    # Solarized light color scheme
│   ├── icons/                    # Widget and tag icons
│   └── wallpapers/               # Time-of-day wallpaper images
│
├── library/                      # Third-party libraries
│   ├── bling/                    # Bling (layouts, playerctl, signals)
│   ├── battery/                  # Battery widget library
│   ├── revelation/               # macOS Expose-like view
│   ├── stocks/                   # Stock price fetcher (Python/uv)
│   ├── volctl/                   # Per-app volume control
│   ├── tween/                    # Animation tweening
│   └── json.lua                  # JSON parser
│
└── tests/                        # Test suite
```

## Panels and Layouts

Five panels are created per screen:

| Panel | Key | Position | Content |
|-------|-----|----------|---------|
| Top Panel | (always visible) | Top edge | Tag list, task list, clock, systray, battery, toggles |
| Control Center | `Mod+c` | Top-right | User profile, brightness, volume, CPU/RAM/disk/temp meters, blur, blue-light, bluetooth, airplane, VPN |
| Info Center | `Mod+i` | Top-right | Notifications, email count, stock prices, calendar events, weather |
| Calendar Center | `Mod+Shift+c` | Top-center | Clock with dots, date, month calendar with navigation |
| Playerctl Center | `Mod+Shift+v` | Top-left | Media player controls (album art, play/pause, next/prev) |

Panels auto-hide when a client enters fullscreen and restore when exiting.

## Widgets

### Top Panel

- **Tag List** -- 9 workspace indicators with icon-based tags
- **Task List** -- Active window list for current tag
- **Clock** -- Time display (12h/24h configurable)
- **System Tray** -- Shown on external monitor when available
- **Screen Recorder** -- Toggle recording indicator
- **Playerctl Toggle** -- Media player center toggle
- **Keyboard Battery** -- External keyboard battery level
- **Battery** -- Laptop battery with UPower integration
- **Control Center Toggle** -- Opens system controls
- **Info Center Toggle** -- Opens info panel

### Control Center

- User profile with hostname
- Display brightness slider
- Volume slider
- Keyboard brightness slider
- CPU, RAM, hard drive, and temperature meters
- Blur toggle, blue-light filter (redshift), bluetooth, airplane mode, VPN, do-not-disturb, microphone toggle

### Info Center

- Notification center with history and clear-all
- Email unread count (fetched via OAuth2 IMAP)
- Stock price ticker (configurable symbols, auto-refresh)
- **Calendar events** (Outlook via Microsoft Graph API)
- Weather (multi-provider, multi-location)

### Calendar Center

- Analog-style clock display with dot separators
- Full date display
- Interactive month calendar with left/right navigation arrows
- Highlights current day and weekends

### Playerctl Center

- Media player controls via bling/playerctl integration

## Modules

| Module | Description |
|--------|-------------|
| `auto-start` | Runs startup applications listed in `apps.lua` |
| `brightness-osd` | On-screen display for brightness changes |
| `kbd-brightness-osd` | On-screen display for keyboard backlight changes |
| `volume-osd` | On-screen display for volume changes |
| `mic-osd` | On-screen display for microphone mute/unmute |
| `dynamic-wallpaper` | Schedules wallpaper changes based on time of day (25+ time slots) |
| `lockscreen` | Lock screen with PAM authentication, webcam intruder capture, blurred background |
| `exit-screen` | Shutdown, reboot, suspend, and log-out menu |
| `notifications` | Custom notification handling and display |
| `screen-manager` | Graceful handling of monitor connect/disconnect events |

## Outlook Calendar via Microsoft Graph API

The calendar events widget fetches events from Outlook via the Microsoft Graph
API. The `utilities/outlook-calendar` script:

- Reuses the neomutt OAuth2 infrastructure (`~/.config/neomutt/accounts/work/oauth2.py`)
- Uses a dedicated Graph API token (`~/.config/neomutt/credentials/token_outlook_graph`)
- Queries `graph.microsoft.com/v1.0/me/calendarview` for events
- Returns JSON with subject, start/end times, location, organizer, response status
- Supports `--date`, `--days`, `--oauth-script`, `--token-file` arguments

The Lua widget (`widget/calendar-events/init.lua`) renders events as a
scrollable list with:
- Event count badge and refresh button
- Concurrent event grouping with expand/collapse
- Auto-scroll to current or next upcoming event
- Today/Tomorrow/day-of-week labels
- Missed event indicators

See the [Neomutt README](../neomutt/README.md#graph-api-token-outlook-calendar)
for Graph API token setup.

## Theme

Solarized color scheme with light and dark variants, switchable via
[darkman](https://darkman.whynothugo.nl/):

- `theme/solarized-dark-theme/` -- Default dark theme
- `theme/solarized-light-theme/` -- Light theme
- Theme selection in `theme/init.lua`
- Darkman integration auto-switches theme based on time/location

Fonts: Hack Nerd Font throughout (configurable via theme).

## Configuration

All settings are centralized in `configuration/config.lua`:

### Display

```lua
display = {
    dpi = 192,
    primary = { name = 'eDP-1', mode = '3840x2400' },
    external = { name = 'DP-4', mode = '3440x1440', scale_from = '3840x2400' },
}
```

The `utilities/read-display-config` script reads this Lua config for use by
shell scripts (`setup-monitors`, `connect-external`, `disconnect-external`).

### Weather

Multi-provider with automatic fallback: Open-Meteo, wttr.in, OpenWeather.
Supports multiple locations with per-location coordinates and timezone.

### Stocks

```lua
stocks = {
    symbols = { "NVDA", "TQQQ", "TECL" },
    update_interval = 300,
}
```

### Calendar Events

```lua
calendar_events = {
    script = config_dir .. 'utilities/outlook-calendar',
    window_days = 2,
    max_items = 0,        -- 0 = show all
    show_cancelled = false,
}
```

### Dynamic Wallpaper

Time-scheduled wallpaper rotation with 25+ time slots across 24 hours.
Wallpapers stored in `theme/wallpapers/`. The `suspend-hook.py` utility
updates wallpaper when resuming from sleep.

### Lockscreen

- PAM authentication (fallback password available)
- Optional webcam capture on failed unlock attempts
- Blurred background option

### Screen Recorder

```lua
screen_recorder = {
    display_target = 'external',
    audio = false,
    save_directory = '$HOME/Videos/Recordings/',
    fps = '60',
}
```

## Key Bindings

Mod key is `Super` (Windows key).

| Key | Action |
|-----|--------|
| `Mod+Return` | Open terminal (Alacritty) |
| `Mod+a` | Application drawer (rofi drun) |
| `Mod+e` | Run menu (rofi) |
| `Mod+Ctrl+e` | Emoji picker |
| `Mod+Ctrl+c` | Calculator (rofi-calc) |
| `Mod+g` | Web browser (Firefox) |
| `Mod+s` | Show keybinding help |
| `Mod+c` | Control center |
| `Mod+i` | Info center |
| `Mod+Shift+c` | Calendar center |
| `Mod+r` | Revelation (Expose view) |
| `Mod+p` | Toggle previous tag |
| `Mod+Ctrl+h` | Previous tag with clients |
| `Mod+Ctrl+l` | Next tag with clients |
| `Mod+Space` | Next layout |
| `Mod+Shift+Space` | Previous layout |
| `Mod+Ctrl+Space` | Toggle floating |
| `Mod+b` | Toggle blue-light filter |
| `Mod+t` | Show time (rofi) |
| `Mod+Ctrl+t` | Toggle blur effects |
| `Mod+Shift+t` | Toggle touchpad |
| `Mod+d` | Destroy all notifications |
| `Mod+Ctrl+n` | Clear notification center |
| `Mod+Ctrl+m` | Refresh stock prices |
| `Mod+Shift+m` | Find cursor location |
| `Mod+Ctrl+p` / `Print` | Fullscreen screenshot |
| `Mod+Shift+p` / `Shift+Print` | Area screenshot |
| `Mod+Shift+l` | Lock screen |
| `Mod+Ctrl+q` | Exit screen (shutdown/reboot/suspend) |
| `Mod+Ctrl+r` | Reload AwesomeWM |
| `Mod+Ctrl+d` | Memory statistics |

Tag navigation: `Mod+[1-9]` to switch, `Mod+Shift+[1-9]` to move client.

## Startup Applications

Configured in `configuration/apps.lua`, launched via `module/auto-start.lua`:

- **picom** -- Compositor with blur and transparency
- **xiccd** -- ICC color profile daemon
- **nm-applet** -- NetworkManager tray applet
- **blueman-applet** -- Bluetooth tray applet
- **lxqt-policykit-agent** -- Authentication agent
- **setup-monitors** -- Display arrangement
- **redshift** -- Blue-light filter
- **xidlehook** -- Auto screen lock on idle
- **darkman** -- Dark/light theme switching
- **watch-email.sh** -- IMAP email notifications (goimapnotify)
- **suspend-hook.py** -- Wallpaper update on sleep/wake
- **volctl** -- Per-app volume control
- **playerctld** -- Media player daemon

## Utilities

| Script | Description |
|--------|-------------|
| `outlook-calendar` | Fetch Outlook calendar events via Microsoft Graph API |
| `setup-monitors` | Configure primary and external display arrangement |
| `connect-external` | Handle external monitor connection |
| `disconnect-external` | Handle external monitor disconnection |
| `read-display-config` | Read display settings from `config.lua` for shell scripts |
| `snap` | Take screenshots (full or area selection) |
| `capture` | Webcam capture for lockscreen intruder detection |
| `kbd-bkl` | Control keyboard backlight brightness |
| `read-kbd-battery` | Read external keyboard battery level |
| `suspend-hook.py` | Update wallpaper and services when resuming from suspend |
| `volctl` | Start per-application volume control tray |
| `touchpad-toggle` | Toggle touchpad on/off |
| `profile-image` | Update user profile picture |
| `time` | Display current time via rofi |
| `location` | Geolocation utility |
| `icc-matcher` | Match ICC color profiles to displays |

## CI/CD

GitHub Actions workflow (`.github/workflows/awesome-wm-tests.yml`) runs on Arch
Linux containers with 8 test jobs:

1. **Lua Syntax Validation** -- luacheck + luac on all Lua files
2. **Config Load Test (Lua 5.4)** -- awesome-git from AUR, `awesome --check`, awmtt runtime test
3. **Config Load Test (LuaJIT)** -- awesome-luajit-git from AUR, awmtt runtime test
4. **Bash Scripts Validation** -- shellcheck + executability checks on all utilities
5. **Display Configuration Tests** -- Validates `config.lua` display section and `read-display-config`
6. **Module Import Tests** -- Tests standalone module imports (config, apps, keys.mod)
7. **Integration Tests** -- Verifies monitor scripts use `read-display-config`
8. **Security Scan** -- Checks for hardcoded secrets, API keys, file permissions
