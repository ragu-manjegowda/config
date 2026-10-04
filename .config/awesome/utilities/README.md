# Awesome helpers

Keep executable helpers in a functional folder, rather than adding files to
this directory's root. Callers use explicit paths relative to the Awesome
configuration directory; these are not global commands on `PATH`.

| Folder | Helpers | Purpose |
| --- | --- | --- |
| `camera/` | `capture`, `intruder-capture` | Bounded webcam capture and external-first intruder photos |
| `desktop/` | `audio-control`, `ensure-darkman`, `profile-image`, `time`, `volctl` | Targeted audio endpoints, theme recovery, profile image, clock menu and volume applet launcher |
| `display/` | `blue-light`, `connect-external`, `disconnect-external`, `display-control`, `monitor-color`, `read-display-config`, `reset-primary-display`, `setup-monitors`, `snap` | Display topology, focused brightness, reversible monitor warmth and screenshots |
| `input/` | `kbd-bkl`, `read-kbd-battery`, `touchpad-toggle` | Keyboard backlight/battery and touchpad controls |
| `network/` | `outlook-calendar`, `prisma-vpn-diagnostics`, `prisma-vpn-health`, `prisma-vpn-status` | Calendar API and VPN status/health helpers |
| `power/` | `battery-power-consumers`, `power-profile`, `power-profile-monitor`, `suspend-hook.py` | Power policy, battery tooltip and resume events |

Helpers that work together stay together: `monitor-color` loads the adjacent
`display-control`, and `power-profile-monitor` uses the adjacent `power-profile`.
The display configuration reader resolves the configuration root from its own
location, including when the checkout is relocated for CI.

## State and dependencies

Do not place generated files here. Persistent state belongs under
`${XDG_STATE_HOME:-$HOME/.local/state}/awesome`; locks, readiness markers and
temporary process state belong under `XDG_RUNTIME_DIR`. Workspace persistence
uses `awesome/last-workspace` and automatically migrates the former
`utilities/awesome-last-ws` file when encountered.

Python bytecode directories are ignored. Native bindings and virtual
environments for Volctl remain under `library/volctl`, outside this helper tree.
`power-profile` and `battery-power-consumers` are invoked through `/bin/bash`;
the monitor runs through `/usr/bin/python3` in its user unit. Other helpers keep
their existing executable permissions and interpreters.

Before moving or removing a helper, update its callers in configuration,
widgets/modules, user units, scripts, tests and GitHub Actions. Preserve hardware
mocking in tests; do not run a real display or camera operation from CI.

`audio-control` selects the configured ALSA card for the focused display, then
operates on a fresh endpoint name. It excludes playback-monitor sources and
unavailable ports. Missing external audio is reported as unavailable rather than
redirecting a monitor control to the laptop. It does not change audio defaults.
