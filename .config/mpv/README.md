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
