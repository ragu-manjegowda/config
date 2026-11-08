# Codex launcher and Solarized themes

`~/.local/bin/cx` provides the session picker and Git-root Firejail workflow used
by `oc`, with Codex's CLI, state, and custom themes.

```sh
cx                         # normal Codex, normal approval settings
cx --session               # fzf picker; Enter resumes, Ctrl-D twice deletes
cx --session UUID          # resume a specific session
cx --sandbox               # run from the root of a Git checkout
cx --sandbox --session     # pick a session and resume inside Firejail
cx --search -m MODEL       # ordinary Codex options are forwarded
cx -- exec --help          # -- stops interpreting launcher options
```

The picker reads only thread metadata from Codex's SQLite state. It excludes
archived and subagent threads; deletion uses `codex delete --force`. Cancelling
the picker does not start Codex. `--session=UUID` also works.

## Sandbox

`--sandbox` requires Firejail and a Git checkout root. It makes the host home
read-only, then permits writes to the checkout and the developer config, package,
cache, data, and state locations listed in the launcher. Git config remains
read-only. This is the `oc` developer sandbox workflow, with persistent Codex
configuration, authentication, and sessions, rather than a disposable account.

Codex runs with `--no-daemon` so execution remains inside Firejail, and
`--dangerously-bypass-approvals-and-sandbox` so Firejail supplies the isolation
boundary. Remote app-server connections are rejected in this mode. Without the
wrapper flag, `-s MODE` or `--sandbox=MODE` selects Codex's native sandbox.

The temporary HOME is `$XDG_STATE_HOME/codex/sandbox-home` (default
`~/.local/state/codex/sandbox-home`). Setup and cleanup are locked; its contents
are removed after the last sandbox exits. Persistent Codex and developer state
are retained. Like `oc`, a working Docker daemon is exposed automatically;
Docker access permits operations beyond the filesystem sandbox. Set
`CX_SANDBOX_DOCKER=0` to omit this access.

## Themes and darkman

`themes/solarized-opencode-{dark,light}.tmTheme` uses the palette and syntax/diff
colors from `~/.config/opencode/themes/solarized-{dark,light}.json`. Distinct names
avoid colliding with Codex's built-in Solarized themes. Codex uses terminal
defaults for the editable prompt and popup surfaces. In tmux, `cx` temporarily
sets its own pane's default foreground/background to the selected Solarized
colors, including when tmux has cached an old light palette. Previous pane
overrides (or inheritance) are restored on exit. Outside tmux, these surfaces
follow the terminal theme; Alacritty already switches Solarized through darkman.
Codex derives its own panel shading from that background.

The darkman hooks update `[tui].theme` in `config.toml`, and `cx` synchronizes it
with `darkman get` before launch. A running Codex session needs `/theme` or a
restart to select the new custom theme; the hooks do not provide live reload.
Themes selected outside this managed pair are preserved. Updates retain
unrelated settings, comments, and file permissions, and reject invalid TOML.

`CODEX_HOME` defaults to `$XDG_CONFIG_HOME/codex` (normally `~/.config/codex`),
matching the installed `codex` wrapper. A custom `CODEX_HOME` receives missing
theme files. Runtime data and credentials are ignored by this directory's
allowlist `.gitignore`.

Dependencies: installed Codex, Bash, the shared
`~/.local/share/venv/bin/python` (Python 3.11+), fzf for the picker, and
Firejail/Git/flock for the sandbox. `CX_PYTHON` overrides the helper interpreter.

## Checks

```sh
~/.local/share/venv/bin/python -m unittest discover -s ~/.config/codex/tests -v
ruff check ~/.config/codex
bash -n ~/.local/bin/cx
```

The regression suite isolates HOME and mocks interactive tools; native Codex and
real Firejail checks additionally verify CLI compatibility and filesystem writes.
