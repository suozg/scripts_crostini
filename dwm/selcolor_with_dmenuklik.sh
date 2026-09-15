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

# Сповіщення-підказка перед вибором
dunstify -u low -t 3000 "🎨 Піпетка" "Клацніть на екран, щоб вибрати колір"

COLOR=$(grabc)

if [ -n "${COLOR:-}" ]; then
    printf "%s" "$COLOR" | xclip -selection clipboard
    # Сповіщення про успішне копіювання
    dunstify -u normal -t 4000 "🎨 Колір скопійовано" "Значення: <b>$COLOR</b>"
fi
