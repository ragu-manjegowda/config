# mpv

Install or update uosc from the latest stable upstream release:

```bash
~/.config/mpv/install-uosc.sh
```

Requires Bash, Python 3, and curl. The official release includes native helpers
for x86_64 Linux and macOS; no Go compiler or submodule is needed. The script
installs into the mpv directory containing it, regardless of the current working
directory or `XDG_CONFIG_HOME`.

Each invocation checks GitHub's latest release. If that version is already
installed and its required files exist, no release assets are downloaded.
Missing files trigger a repair. SHA-256 checksums are verified when GitHub
provides them. Downloads and archive validation finish before replacing an
installation; replacement failures roll back the affected files.

Only uosc's script directory and two fonts are managed. Existing
`script-opts/uosc.conf`, other fonts, scripts, `mpv.conf`, and `input.conf` are
preserved. Default uosc settings are installed only when its configuration is
absent. The installed release is recorded in `scripts/uosc/.release-version`.
The scripts, fonts, and local settings remain ignored by the dotfiles repo;
only this installer and its documentation/tests are tracked.

Restart mpv after installation. Existing bindings include Tab to toggle the UI,
`o` to browse files, `c` for chapters, and right-click for the menu. Updates run
only when this script is invoked; bootstrap and submodule updates are unchanged.

Run installer regression tests without network access:

```bash
python3 ~/.config/mpv/tests/test_install_uosc.py
```

The `mpv Configuration Tests` GitHub Actions workflow runs installer syntax
checks and discovers all `tests/test_*.py` unit tests in an Arch Linux container.
It runs on pushes and pull requests affecting `.config/mpv/` or the workflow
itself, and supports manual runs. The tests use local release fixtures and a
fake curl; they do not download uosc or require mpv, a display, or credentials.

## Interactive GUI tests

The separate `mpv Interactive GUI Tests` workflow runs only when mpv files or
that workflow change (or when manually dispatched). It builds an Arch Linux
image and runs `tests/gui_mpv.py` on a private Xvfb display. GUI files deliberately
do not match the unit-test discovery pattern.

Run the same environment locally, without installing test packages on the host:

```bash
docker build -f ~/.config/mpv/tests/gui.Dockerfile -t dotfiles-mpv-gui ~/.config/mpv/tests
mkdir -p /tmp/mpv-gui-artifacts
docker run --rm --network none \
  -v "$HOME/.config/mpv:/workspace/.config/mpv:ro" \
  -v /tmp/mpv-gui-artifacts:/artifacts dotfiles-mpv-gui
```

The image pins uosc 5.13.0; changing that version also requires reviewing the
test probe and service fixtures. Each test copies the actual `mpv.conf` and
`input.conf` into a temporary configuration, creates local video/chapters, and
drives the real window with X11 key and mouse events. Audio output and hardware
decoding are disabled, and the virtual display uses an explicit 60 Hz refresh
rate. Existing mpv sessions and settings are not touched.

Coverage includes duplicate/live uosc keymaps, editable subtitle searches,
result selection and loading, service errors/empty results/recovery, closing a
pending search, menu navigation and resizing, right-click menus, volume,
subtitle visibility, seeking, and chapter changes. Subtitle requests use a
stateful local helper, never OpenSubtitles credentials or the network.

An observation-only Lua probe is appended to the temporary uosc copy to expose
menu state and geometry; it does not implement actions or replace UI widgets.
Tests wait for observed results rather than assuming subprocess completion.
Logs, screenshots, helper requests, and final state are saved under `/artifacts`
and uploaded by CI, including when assertions fail. These are behavioral and
geometry checks, not pixel-perfect screenshot baselines or hardware playback
certification. Missing GUI dependencies fail rather than skip the suite.
