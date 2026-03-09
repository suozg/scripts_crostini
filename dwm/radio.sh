#!/usr/bin/env bash

set -euo pipefail
FONT="monospace:size=12"

# Файл со списком радиостанций (каждая строка: "Название|URL")
STATIONS_FILE="${HOME}/.config/dm-radio/stations.txt"
mkdir -p "$(dirname "$STATIONS_FILE")"
touch "$STATIONS_FILE"

# Функция уведомлений
notify() {
    notify-send "dm-radio" "$1"
}

# Функция выбора меню через dmenu
menu() {
    echo -e "$1" | dmenu -i -p "$2" -fn "$FONT"
}

# Основное меню управления радиостанциями
main() {
    while true; do
        choice=$(menu "Вибрати станцію\nДодати станцію\nВидалити станцію\nВихід" "Інтернет-радіо:") || exit 0
        case "$choice" in
        "Вибрати станцію")
            stations=()
            while IFS= read -r line; do
                stations+=("${line%%|*}")
            done < "$STATIONS_FILE"
            [ ${#stations[@]} -eq 0 ] && notify "Станції не налаштовані." && continue
            station_choice=$(printf '%s\n' "${stations[@]}" | dmenu -i -p "Виберіть станцію:" -fn "$FONT") || continue
            url=$(grep "^${station_choice}|" "$STATIONS_FILE" | cut -d'|' -f2)
            [ -z "$url" ] && notify "Станція не знайдена." && continue
            #notify "Обрано станцію: $station_choice"
            pkill -f "dm-radio-mpv" || true 
            mpv --no-video --quiet --input-terminal=no --title="dm-radio-mpv" "$url" &
            ;;
        "Додати станцію")
            name=$(menu "" "Назва станції:") || continue
            url=$(menu "" "URL-адреса:") || continue
            [ -z "$name" ] || [ -z "$url" ] && notify "Введіть назву та URL." && continue
            echo "${name}|${url}" >> "$STATIONS_FILE"
            notify "Станцію додано: $name"
            ;;
        "Видалити станцію")
            stations=()
            while IFS= read -r line; do
                stations+=("${line%%|*}")
            done < "$STATIONS_FILE"
            [ ${#stations[@]} -eq 0 ] && notify "Немає чого видаляти." && continue
            del_choice=$(printf '%s\n' "${stations[@]}" | dmenu -i -p "Виберіть станцію для видалення:" -fn "$FONT") || continue
            grep -v "^${del_choice}|" "$STATIONS_FILE" > "${STATIONS_FILE}.tmp"
            mv "${STATIONS_FILE}.tmp" "$STATIONS_FILE"
            notify "Видалена станція: $del_choice"
            ;;
        "Вихід")
            pkill -f mpv || true
            exit 0
            ;;
        *)
            exit 0
            ;;
        esac
    done
}

main

