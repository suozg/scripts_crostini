#!/bin/bash
set -euo pipefail

STATUS=/tmp/pipette.status

cleanup() {
    rm -f "$STATUS"
    pkill -RTMIN+14 dwmblocks 2>/dev/null || true
}

echo "🎨 Піпетка" > "$STATUS"
pkill -RTMIN+14 dwmblocks 2>/dev/null || true

trap cleanup EXIT

COLOR=$(maim -s -u | convert - -format '%[hex:p{0,0}]' info:)

[ -n "${COLOR:-}" ] && printf "%s" "$COLOR" | xclip -selection clipboard
