#!/usr/bin/env bash
set -euo pipefail

FILE="$HOME/awards/events.txt"
[ -f "$FILE" ] || { exit 1; }

mapfile -t lines < "$FILE"
if [ "${#lines[@]}" -eq 0 ]; then
  exit 0
fi

menu=""
for i in "${!lines[@]}"; do
  n=$((i+1))
  menu+="$n) ${lines[i]}"$'\n'
done

if command -v dmenu >/dev/null 2>&1; then
  choice=$(printf "%s" "$menu" | dmenu -l 20 -p "Видалити запис:" -fn "monospace:size=12")
  [ -z "$choice" ] && exit 0
else
  printf "%s" "$menu"
  read -rp "Введіть номер: " choice
fi

# извлечь номер (до ')')
num=$(printf "%s" "$choice" | sed -E 's/^([0-9]+).*/\1/')
if ! [[ $num =~ ^[0-9]+$ ]]; then
  exit 1
fi

idx=$((num-1))
if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#lines[@]}" ]; then
  exit 1
fi

deleted="${lines[idx]}"
{
  for i in "${!lines[@]}"; do
    [ "$i" -eq "$idx" ] && continue
    printf "%s\n" "${lines[i]}"
  done
} > "$FILE".tmp && mv "$FILE".tmp "$FILE"

pkill -RTMIN+10 dwmblocks 2>/dev/null || true
notify-send "Видалено запис" "$deleted"

