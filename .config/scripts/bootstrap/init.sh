#!/bin/bash
set -euo pipefail

CLONE_DIR="/tmp/arch-bootstrap"
REPO="https://github.com/ragu-manjegowda/config.git"
BOOTSTRAP="${CLONE_DIR}/.config/scripts/bootstrap/bootstrap.sh"

sudo pacman -S --needed --noconfirm git curl

rm -rf "$CLONE_DIR"
git clone --depth 1 "$REPO" "$CLONE_DIR"
chmod +x "$BOOTSTRAP"
"$BOOTSTRAP" "$@"
