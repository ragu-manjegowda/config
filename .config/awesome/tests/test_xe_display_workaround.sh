#!/usr/bin/env bash
set -euo pipefail

REPO_HOME="${REPO_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
XE_CONFIG="$REPO_HOME/.config/misc/etc/modprobe.d/xe.conf"
BOOTSTRAP="$REPO_HOME/.config/scripts/bootstrap/03-system.sh"

grep -Fxq \
    'options xe enable_psr=0 enable_panel_replay=0 enable_psr2_sel_fetch=0' \
    "$XE_CONFIG"
grep -Fq 'etc/modprobe.d/xe.conf' "$BOOTSTRAP"
grep -Fq '/etc/modprobe.d/xe.conf' "$BOOTSTRAP"

printf '%s\n' 'xe display workaround tests passed'
