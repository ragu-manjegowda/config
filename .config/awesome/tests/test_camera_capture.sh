#!/usr/bin/env bash

set -euo pipefail

repo_home="${HOME}"
capture="$repo_home/.config/awesome/utilities/capture"
override="$repo_home/.config/misc/etc/systemd/system/v4l2-relayd-ipu7.service.d/override.conf"
bootstrap="$repo_home/.config/scripts/bootstrap/04-hardware.sh"

grep -Fq 'width=1920,height=1080' "$override"
grep -Fq 'ae-enable=true awb-enable=true sharpness=1.5' "$override"
grep -Fq 'format=I420,width=1920,height=1080,framerate=30/1' "$override"
if grep -Fq 'videotestsrc is-live=true' "$override"; then
    printf 'camera relay keeps rendering live splash frames while idle\n' >&2
    exit 1
fi
grep -Fq "select=gte(n\\,15)" "$capture"
grep -Fq 'scale=in_range=tv:out_range=pc,format=yuvj420p' "$capture"
if grep -Fq 'scale=1280:720' "$capture"; then
    printf 'camera capture still distorts its native aspect ratio\n' >&2
    exit 1
fi
grep -Fq 'v4l2-relayd-ipu7.service.d/override.conf' "$bootstrap"

printf 'camera capture tests passed\n'
