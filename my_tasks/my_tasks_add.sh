#!/usr/bin/env bash

# Зберігаємо поточну розкладку клавіатури на початку 
initial_layout=$(xkb-switch -p 2>/dev/null || echo "us")

# если что-то пойдет не так восстанавливаем как било
trap '
    if [[ "$initial_layout" == "ua" ]]; then
        xkb-switch -s ua
        echo "🌻UA" > /tmp/dwm_layout
    else
        xkb-switch -s us
        echo "🗽US" > /tmp/dwm_layout
    fi
    pkill -RTMIN+1 dwmblocks
' EXIT

#  переключаем раскладку 
current_xkb="$initial_layout"
if [[ "$current_xkb" != "ua" ]]; then
    xkb-switch -s ua
    echo "🌻UA" > /tmp/dwm_layout
    pkill -RTMIN+1 dwmblocks
fi

# Шлях до основного файлу нотаток
ORG_FILE="$HOME/awards/org/diary.org"
mkdir -p "$(dirname "$ORG_FILE")"
FONT="monospace:size=12"

# --- Функція для розумного виклику dmenu ---
dmenu_cmd() {
    local prompt="$1"
    local opts=("-i" "-p" "$prompt" "-fn" "$FONT")
    if [[ -f "$HOME/.lightmode" ]]; then
        opts+=("-nb" "#eeeeee" "-nf" "#222222" "-sb" "#005577" "-sf" "#eeeeee")
    fi
    dmenu "${opts[@]}"
}

# 2. Отримуємо поточну дату за замовчуванням та підставляємо її в рядок введення dmenu
default_date=$(date +%Y-%m-%d)
date_input=$(echo "$default_date" | dmenu_cmd "📅 Дата (YYYY-MM-DD):")
[ -z "$date_input" ] && exit 0

time_input=$(printf "" | dmenu_cmd "🕒 Час (HH:MM):")
[ -z "$time_input" ] && exit 0

task_input=$(printf "" | dmenu_cmd "📝 Що зробити?:")
[ -z "$task_input" ] && exit 0

# Формуємо правильний Org-штамп
day_name=$(date -d "$date_input" "+%a")

cat <<EOF >> "$ORG_FILE"

* TODO $task_input
  SCHEDULED: <$date_input $day_name $time_input>
EOF

dunstify -r 556 "Org-mode" "Завдання додано"
pkill -RTMIN+10 dwmblocks || true
