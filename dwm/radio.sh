#!/usr/bin/env bash
#
set -euo pipefail
FONT="monospace:size=12"

STATIONS_FILE="${HOME}/.config/dm-radio/stations.txt"
mkdir -p "$(dirname "$STATIONS_FILE")"
touch "$STATIONS_FILE"

# Иконки
ICON_PLAY="📻"
ICON_ADD="➕"
ICON_DEL="❌"
ICON_EXIT="🚪"

if ! pgrep -x "mpvdwm" > /dev/null; then
    $HOME/.local/bin/dwm/mpvdwm &
fi

# --- Функція для розумного виклику dmenu ---
#
dmenu_cmd() {
    local prompt="$1"
    shift
    # Базові налаштування
    local opts=("-i" "-p" "$prompt" "-fn" "$FONT")
    
    # Додаємо кольори, якщо файл світлої теми існує
    #
    if [[ -f "$HOME/.lightmode" ]]; then
        opts+=("-nb" "#eeeeee" "-nf" "#222222" "-sb" "#005577" "-sf" "#eeeeee")
    fi
    
    # Викликаємо dmenu з усіма переданими аргументами
    dmenu "${opts[@]}" "$@"
}

# Функция уведомлений
notify() {
    dunstify "dm-radio" "$1"
}

# Функция меню
#
menu() {
    echo -e "$1" | dmenu_cmd "$2"
}

main() {
    while true; do
        # Основное меню с иконками
        choice=$(menu "$ICON_PLAY Вибрати [1]\n$ICON_ADD Додати [2]\n$ICON_DEL Видалити [3]\n$ICON_EXIT Вихід [0]" "📡 Радіо:") || exit 0
        case "$choice" in
        "$ICON_PLAY Вибрати [1]")
            stations=()
            declare -A map
            index=1
            while IFS= read -r line; do
                name="${line%%|*}"
                label="[$index] $ICON_PLAY $name"
                stations+=("$label")
                map["$index"]="$line"
                ((index++))
            done < "$STATIONS_FILE"

            [ ${#stations[@]} -eq 0 ] && notify "Станції не налаштовані." && continue

            # Меню выбора станции
            #
            station_choice=$(printf '%s\n' "${stations[@]}" | dmenu_cmd "🎧 Виберіть станцію:" -l 10) || continue

            if [[ "$station_choice" =~ ^\[([0-9]+)\] ]]; then
                num="${BASH_REMATCH[1]}"
                line="${map[$num]}"
            else
                line=$(grep -E "\Q${station_choice##* }" "$STATIONS_FILE") || { notify "Станція не знайдена"; continue; }
            fi

            url="${line#*|}"
            name="${line%%|*}"

            echo "📻Завантаження..." > /tmp/dwm-radio-status
            pkill -RTMIN+15 dwmblocks

            pkill -f "dm-radio-mpv" || true
            mpv --no-video --quiet --input-ipc-server=/tmp/mpv-radio-socket --input-terminal=no --title="dm-radio-mpv" "$url" &
            break
            ;;
        "$ICON_ADD Додати [2]")
            name=$(menu "" "Назва станції:") || continue

            if command -v xclip &>/dev/null; then
                clipboard=$(xclip -selection clipboard -o 2>/dev/null || true)
            elif command -v wl-paste &>/dev/null; then
                clipboard=$(wl-paste 2>/dev/null || true)
            else
                clipboard=""
            fi

            #
            url=$(echo "$clipboard" | dmenu_cmd "URL-адреса:") || continue

            [ -z "$name" ] || [ -z "$url" ] && notify "Введіть назву та URL." && continue
            echo "${name}|${url}" >> "$STATIONS_FILE"
            notify "Станцію додано: $name"
            ;;  
        "$ICON_DEL Видалити [3]")
            stations=()
            declare -A map
            index=1
            while IFS= read -r line; do
                name="${line%%|*}"
                label="[$index] $ICON_PLAY $name"
                stations+=("$label")
                map["$index"]="$line"
                ((index++))
            done < "$STATIONS_FILE"

            [ ${#stations[@]} -eq 0 ] && notify "Немає чого видаляти." && continue

            #
            del_choice=$(printf '%s\n' "${stations[@]}" | dmenu_cmd "🗑 Видалити станцію:" -l 10) || continue

            if [[ "$del_choice" =~ ^\[([0-9]+)\] ]]; then
                num="${BASH_REMATCH[1]}"
                line="${map[$num]}"
            else
                line=$(grep -E "\Q${del_choice##* }" "$STATIONS_FILE") || { notify "Станція не знайдена"; continue; }
            fi

            grep -v "^${line}$" "$STATIONS_FILE" > "${STATIONS_FILE}.tmp"
            mv "${STATIONS_FILE}.tmp" "$STATIONS_FILE"
            notify "Видалена станція: ${line%%|*}"
            ;;
        "$ICON_EXIT Вихід [0]")
            pkill -f mpv || true
            echo "📻Radio" > /tmp/dwm-radio-status
            pkill -RTMIN+15 dwmblocks 
            exit 0
            ;;
        *)
            exit 0
            ;;
        esac
    done
}

main
