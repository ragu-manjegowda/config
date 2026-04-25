# Firejail profile for Prisma Access Browser (by Palo Alto Networks)
# Chromium-based enterprise browser installed from AUR (prisma-access-browser-bin)
# Binary: /usr/bin/prisma-access-browser-stable -> /opt/paloaltonetworks/pab/PrismaAccessBrowser
#
# This profile inherits the upstream firejail chromium-common.profile and adds
# the package-specific paths needed by Palo Alto's build.
#
# Persistent local customisations go in:
#   /etc/firejail/prisma-access-browser-stable.local
# Persistent global definitions:
#   /etc/firejail/globals.local
include prisma-access-browser-stable.local
include globals.local

# ---------------------------------------------------------------------------
# Application-specific paths
# ---------------------------------------------------------------------------
# Palo Alto Networks installs the browser under /opt/paloaltonetworks/pab and
# stores its Chromium profile (History, Tabs, Session, Preferences, Bookmarks,
# cookies, cache, etc.) under "Palo Alto Networks/PrismaAccessBrowser" with a
# SPACE in the vendor directory name. Without whitelisting these exact paths
# the sandbox exposes an empty browser profile each launch, so saved tab
# groups, pinned tabs, history, and logins do not persist across restarts.
noblacklist /opt/paloaltonetworks
noblacklist ${HOME}/.config/Palo Alto Networks
noblacklist ${HOME}/.cache/Palo Alto Networks
noblacklist ${HOME}/.local/share/Palo Alto Networks

mkdir ${HOME}/.config/Palo Alto Networks
mkdir ${HOME}/.cache/Palo Alto Networks
whitelist /opt/paloaltonetworks
whitelist ${HOME}/.config/Palo Alto Networks
whitelist ${HOME}/.cache/Palo Alto Networks
whitelist ${HOME}/.local/share/Palo Alto Networks

# ---------------------------------------------------------------------------
# Inherit the hardened Chromium profile from upstream firejail.
# chromium-common.profile handles: caps.drop all, seccomp, nonewprivs,
# nodvd, notv, machine-id, disable-common, disable-programs, disable-xdg,
# X11 abstract-socket isolation, noexec /tmp and /home, etc.
#
# NOTE: We deliberately do NOT set `private-bin` here. Chromium's zygote and
# renderer processes exec xdg-mime, xdg-open, sh, cat, and other helpers at
# runtime; restricting private-bin breaks file-download prompts, default-app
# lookups, and crashpad. The chromium-common profile's own defaults are safe.
# ---------------------------------------------------------------------------
include chromium-common.profile
