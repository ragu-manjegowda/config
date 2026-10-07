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

## Hostname and Local Discovery

Avahi advertises the current system hostname. NetworkManager and resolved use
client-only mDNS so they do not compete to publish the same name. SSH aliases
can target `<hostname>.local` rather than a changing DHCP address.

Step 3 deploys the resolved and NetworkManager mDNS-client drop-ins. Step 5
enables `systemd-resolved.service` for future boots and restarts it after the
DNS-privacy and mDNS configuration has been deployed. This applies to both
laptop and iMac profiles. The stock `resolve` NSS entry uses this service;
`nss-mdns` and an additional `mdns` entry in `/etc/nsswitch.conf` are not required
for this lookup path. A failed resolved restart stops bootstrap rather than
silently leaving hostname lookup unavailable.

An already-running NetworkManager needs its configuration changes applied using
the network-restart reminder from step 2. For partial bootstrap runs, deploy
step 3 before running step 5 to activate the mDNS configuration. Verify with:

```bash
systemctl is-enabled systemd-resolved.service
systemctl is-active systemd-resolved.service
resolvectl status
getent -s resolve ahostsv4 arch-imac.local
```

Use `arch-dell14.local` for the lookup check from the iMac. The active LAN link
should show `mDNS=resolve`, and the lookup should return the peer's LAN address.

Changing a hostname during an existing X11 session also changes the name used
to look up local Xauthority cookies. Those cookies are generated session data,
not hardcoded application configuration. Prefer changing the hostname before
graphical login, or preserve the existing cookie under the new local hostname
before switching names. Never print or regenerate the cookie just to rename a
running session. A new graphical login generates credentials for the new name.

## Desktop/iMac configuration pulls

Git has no native `pre-pull` hook. The `cpulla` shell function uses
`~/.config/awesome/utilities/desktop/config-pull`, preserving
`config pull --rebase --autostash` while managing desktop variants:

* Laptop profiles pull normally.
* `machine = 'imac'` uses tracked `configuration/config_imac.lua`;
  `machine = 'desktop'` requires a tracked `configuration/config_desktop.lua`.
* Before a desktop pull, the helper saves a private recovery copy, clears only
  `config.lua`'s local index flags, and restores its tracked `HEAD` contents.
* After a successful pull it copies the updated variant over `config.lua` and
  marks it assume-unchanged. Other changes follow Git's normal autostash behavior.
* Failed pulls restore the previous local configuration and flags. Conflicts in
  either managed configuration are left intact for Git resolution, with the
  original local configuration retained privately under XDG_STATE_HOME.

Edit the variant rather than the generated `config.lua`. Staged `config.lua`
changes are rejected instead of being discarded. If branch tracking is absent,
a no-argument pull explicitly uses `origin` and the current branch. Use `cpulla
origin master` when a different upstream is intended. Ordinary `config pull`
bypasses this wrapper.

When installing the wrapper before its upstream commit exists, put its temporary
copy in `.config.git/local-tools/config-pull`. `cpulla` falls back to that copy
until the tracked utility arrives, avoiding an untracked-file collision on the
first upstream pull.
If neither copy is executable, `cpulla` falls back to the original
`config pull --rebase --autostash` command with all arguments preserved. Desktop
variant cleanup/reapplication is available only when a helper is present; a
helper failure is returned directly instead of retrying an unprotected pull.

Desktop bootstrap step 6 applies this configuration only when the active profile
is `imac` or `desktop`, or `AWESOME_MACHINE_PROFILE` explicitly selects it. After
resolving a managed-config conflict, reapply with `config-pull --apply-profile imac`.
This profile selection does not replace the hardware/package exclusions needed
when adapting the full laptop bootstrap to a desktop.

## On-demand VNC

After logging into the X11 desktop, run `~/.local/bin/vnc-server start` to share
the current session, and `~/.local/bin/vnc-server stop` when finished. `status`
reports whether it is running. The helper uses transient user units, so nothing
is enabled at login or boot. Connect to `<hostname>.local:5900` using TLSPlain
with your normal system username and password; no separate VNC password file is
used. `<hostname>:5900` also works when the client can resolve the bare hostname.
The firewall permits SSH and VNC only from the IPv4 LAN `192.168.1.0/24`
(plus local loopback), before the broader VPN-interface allowance.

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
