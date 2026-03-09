#!/usr/bin/env bash
set -euo pipefail

OPTIONS="lv3:ralt_switch"
current=$(setxkbmap -query | awk '/layout/{print $2}')

# 1. Якщо початкова розкладка була US, встановлюємо пастку (trap)
#    для її відновлення при будь-якому виході зі скрипта (EXIT).
if [ "$current" = "us" ]; then
    setxkbmap -layout ua -option "$OPTIONS"
    trap 'setxkbmap -layout us' EXIT
fi

FILE="$HOME/awards/events.txt"
mkdir -p "$(dirname "$FILE")"
touch "$FILE"

use_dmenu() { command -v dmenu >/dev/null 2>&1; }

prompt() {
   local prompt="$1"
   printf "" | dmenu -p "$prompt" -fn "monospace:size=12"
}

# --- Збір та Валідація Дати ---
date=$(prompt "Дата (YYYY-MM-DD):" || exit 0)
[ -z "$date" ] && exit 0

if ! [[ $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
   notify-send -u critical "Помилка в форматі дати:" "($date) проти (YYYY-MM-DD)"
   exit 1
fi

# --- Збір та Валідація Часу ---
time=$(prompt "Час (HH:MM):")
[ -z "$time" ] && exit 0

if ! [[ $time =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
   notify-send -u critical "Помилка в форматі часу:" "($time) проти (HH:MM)"
   exit 1
fi

# --- Збір Завдання ---
text=$(prompt "Задача:")
[ -z "$text" ] && exit 0

# --- Запис та Очищення ---
echo "$date $time $text" >> "$FILE"
sed -i '/^$/d' "$FILE"

# --- Завершення ---
pkill -RTMIN+10 dwmblocks 2>/dev/null || true
notify-send "Нова задача:" "$date $time $text"
