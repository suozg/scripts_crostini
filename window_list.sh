#!/bin/bash

# для скрипта нужен jq, zenity, ps, awk

# Получение списка окон и их количества, исключая строки с i3bar
WINDOWS=$(i3-msg -t get_tree | jq -r '
    .. | select(.type?) | 
    select(.type == "con" and .window_properties.class != null) |
    select(.name | contains("i3bar") | not) |
    "\(.name) (\(.window_properties.class))"')
WINDOW_COUNT=$(echo "$WINDOWS" | grep -v '^$' | wc -l)

# Получение общего использования памяти и загрузки процессора
MEMORY_USAGE=$(ps --no-headers -eo pid,%mem | awk '{sum += $2} END {print sum "%"}')

# Получение количества ядер процессора
CPU_CORES=$(nproc)

# Рассчитываем среднюю загрузку процессора
CPU_LOAD=$(ps --no-headers -eo pid,%cpu | awk -v cores="$CPU_CORES" '{sum += $2} END {print (sum / cores) "%"}')

# Формирование сообщения и заголовка для zenity
TITLE="Відкриті вікна ($WINDOW_COUNT):"
MESSAGE="$WINDOWS\n\nПам'ять: $MEMORY_USAGE\nНавантаження: $CPU_LOAD"

# Отправка уведомления с использованием libnotify (notify-send)
notify-send "$TITLE" "$MESSAGE" -u normal -t 5000

# Отправка уведомления с использованием zenity
#zenity --info --title="$TITLE" --text="$MESSAGE" --width=400 --height=300
