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

# Restore the committed minimal laptop package list, including explicit runtimes
~/.config/scripts/bootstrap/bootstrap.sh --only 1 --package-profile minimal --prune-packages
```

Package restoration always reads the manifests committed at Git `HEAD`. The
working copies under `~/.config/archiso-backup/` may be refreshed by pacman
hooks, but bootstrap never uses those generated changes as restore input.

The default `full` package profile uses the official and foreign manifests and
validates their union against `pkglistAll.txt`. `--package-profile minimal`
instead selects exactly `pkglistMinimal.txt`. Entries in the committed foreign
manifest go to paru; the remaining minimal entries go to pacman, including
runtime dependencies explicitly named only in the minimal list. Pruning uses
the selected profile; packages required as dependencies are retained normally.
Neither profile automatically excludes hardware-specific packages.

Minimal-only additions are checked against pacman's configured sync repositories
before choosing the official or foreign installer. Dependency verification uses
`pacman -T`, so an installed provider can satisfy a selected name. Pruning retains
the actual provider package rather than demoting it because its name differs.
Custom packages still need an available PKGBUILD source or a preinstalled package;
listing a package does not publish its build recipe.

Arch package builds use system tools and system pkg-config directories even
after Homebrew has updated PATH. Awesome's supported `_BUILD_DOCS=0` switch
disables docs and manpages by default for AUR builds (set `_BUILD_DOCS=1` to
override). Already-installed AUR packages are retained rather than updated as
part of restoration. This does not pin package versions or repair upstream
PKGBUILDs; an unavailable or broken recipe is a restoration failure.

Official or AUR installation failures stop the package step before pruning.
The selected package set is checked against pacman's installed database before
pruning and again at completion, and the Brewfile is checked without requiring
upgrades. A failed restoration never reports bootstrap completion. An active
git-crypt key/filter is reused, so rerunning an unlocked setup preserves local
configuration edits instead of attempting another unlock on a dirty worktree.

The package step includes the configured npm prefix's `bin` directory only if
it is missing, and scopes the PATH change to the shared profile installer.
The installer's tool-command function also uses a local PATH and preserves
existing entries without duplication. Its commands run without another login
shell, so a newly installed
`@playwright/mcp` exposes `playwright-mcp` immediately. The browser installer
comes from npm and does not require a Python Playwright package.

Run package restoration regression checks with:

```bash
python3 ~/.config/scripts/bootstrap/tests/test_packages.py
```

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

* Generic laptop profiles pull normally. Lenovo uses `machine = 'laptop'` with
  `profile = 'lenovo'` to retain laptop widgets while managing `config_lenovo.lua`.
* `machine = 'imac'` uses tracked `configuration/config_imac.lua`;
  `machine = 'desktop'` requires a tracked `configuration/config_desktop.lua`.

On the Lenovo, apply the variant once with:

```bash
~/.config/awesome/utilities/desktop/config-pull --apply-profile lenovo
```

Use `cpulla` for subsequent upstream pulls. It cleans the generated `config.lua`
before pulling, reapplies the Lenovo variant afterward, and restores the previous
configuration on a failed pull. Direct Git pulls bypass this wrapper.
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
The firewall permits SSH and VNC from the IPv4 LAN `192.168.1.0/24`
(plus local loopback). On `tailscale0`, only the explicitly enrolled phone
addresses may initiate SSH/VNC connections; all other inbound tailnet
services and peers are blocked before the LAN/VPN allowances.

### Outside the LAN with Tailscale

Tailscale connects the Android phone to the existing OpenSSH and TLSPlain
VNC services. OpenSSH still authenticates the normal `ragu` account;
Tailscale SSH is disabled. VNC stays on demand, shares the logged-in X11
desktop, and uses the same system credentials as LAN VNC.

The Arch package lists install `tailscale`, and bootstrap step 5 enables
`tailscaled.service` for subsequent boots. On a fresh machine, start the
daemon and enroll it once from an interactive terminal:

```bash
sudo systemctl enable --now tailscaled.service
sudo tailscale up \
    --hostname="$(hostnamectl --static)" \
    --accept-dns=false \
    --accept-routes=false \
    --ssh=false \
    --shields-up=true
```

Open the authentication URL printed by the command and sign into the same
tailnet as the Android phone. Incoming connections remain blocked during
enrollment. Before allowing them, verify that the `tailscale_phone4` and
`tailscale_phone6` sets in both the installed/live firewall and the maintained
configuration contain only the intended phone's current Tailscale addresses.
Then enable incoming access and check the connection:

```bash
sudo tailscale set --shields-up=false
tailscale status
tailscale ip -4
systemctl is-enabled tailscaled.service
```

The daemon retains enrollment and connection preferences across boots.
Use `sudo tailscale down` to disconnect and `sudo tailscale up` without
flags to reconnect using the saved settings. Bootstrap does not perform
interactive authentication or import another machine's enrollment state.

Connect Tailscale on the phone and use the laptop's address from
`tailscale ip -4` as the SSH host (port 22) or VNC host (port 5900).
`vnc-server start` and `status` also print this remote address. From the
phone's SSH session, run `~/.local/bin/vnc-server start` before opening
the VNC client; stop it with `~/.local/bin/vnc-server stop` when finished.
Use a VNC client supporting TLSPlain/VeNCrypt, such as AVNC, with its SSH
tunnel option disabled. The server's SSH configuration disables TCP
forwarding; Tailscale supplies the private network path directly.

On the home LAN, continue using `<hostname>.local` or the LAN address.
Tailscale does not replace the normal internet/default route or accept
subnet routes, and laptop DNS integration is disabled to preserve existing
NetworkManager/Prisma DNS behavior. No subnet router, exit node, Funnel,
or public SSH/VNC port forwarding is configured. Android permits only one
active VPN per profile, so another phone VPN may need to be disconnected.

The persistent `tailscale_phone4` and `tailscale_phone6` sets in
`.config/misc/etc/nftables.conf` contain the enrolled phone's exact addresses.
If replacing/re-enrolling the phone changes those addresses, update both
the maintained and installed firewall configuration and the live sets.
Clearing both sets blocks new remote management connections. These rules
remain effective even if the tailnet's cloud policy permits other peers.

Keep `/var/lib/tailscale` private and outside dotfiles; it contains machine
credentials. Authentication is per machine. Monitor device key expiry in
the Tailscale app/admin console and revoke a lost phone there. Normal
sleep, lid-close, and power-off behavior is retained: remote access works
only while the laptop is awake, booted, and connected to the network.

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
