# Arch Linux Bootstrap

Automated system setup for a fresh Arch Linux install.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/ragu-manjegowda/config/refs/heads/master/.config/scripts/bootstrap/init.sh | bash
```

## Usage

```bash
# Full setup
~/.config/scripts/bootstrap/bootstrap.sh

# Run a specific step
~/.config/scripts/bootstrap/bootstrap.sh --only 2

# Resume from a step
~/.config/scripts/bootstrap/bootstrap.sh --from 4

# Restore committed package manifests and remove packages outside them
~/.config/scripts/bootstrap/bootstrap.sh --only 1 --prune-packages
```

Package restoration always reads the manifests committed at Git `HEAD`. The
working copies under `~/.config/archiso-backup/` may be refreshed by pacman
hooks, but bootstrap never uses those generated changes as restore input.

Before installing the Homebrew bundle or restoring system packages, bootstrap
checks the configured `GNUPGHOME` for a secret key. You can import a key file,
or re-check after importing through another terminal or hardware token.
Continuing requires a usable secret key and successful `git-crypt unlock`;
otherwise bootstrap stops instead of deploying incomplete encrypted settings.

Application setup creates the shared and Volctl virtual environments with
`/usr/bin/python3` and system-site packages, preserving access to Arch's
GTK/GObject bindings. Volctl is installed from its maintained local source;
only its pure-Python PulseAudio dependency is installed with uv. GTK/Cairo
bindings remain package-managed to avoid linking them against Homebrew.

Initial submodule downloads use depth-one history and four parallel workers.
If a pinned revision cannot be obtained, bootstrap retries with full history.
Later rebases or work involving older commits may require running
`git fetch --unshallow origin` inside the affected submodule.

Official packages restore non-interactively. AUR packages restore one at a
time so provider and PKGBUILD prompts remain interactive. Package pruning is
opt-in and demotes extra explicit packages before removing only true orphans.

## System Configuration Safety

Bootstrap refuses to copy tracked files over package-owned paths. Package
defaults are extracted from the currently installed package and changed with
semantic renderers, or extended through native drop-ins. Generated files such
as mkinitcpio presets are rendered from the installed upstream template.

Administrator-owned package configs require a file-specific validator and
bootstrap stops when a `.pacnew` needs review. Rendered files are installed
atomically only after their expected settings or anchors are confirmed.

## Steps

| Step | Name |
|------|------|
| 0 | Dotfiles |
| 1 | Packages |
| 2 | Security |
| 3 | System |
| 4 | Hardware |
| 5 | Services |
| 6 | Desktop |
| 7 | Apps |
