#!/bin/bash

# --- Налаштування ---
TMP_FILE="/tmp/ukraine_holidays.ics"
EVENTS_BIN="$HOME/.local/bin/dwm/my_tasks"
TODAY=$(date +%Y%m%d)
FLAG="/tmp/holiday_notified_$TODAY"
URL="https://calendar.google.com/calendar/ical/uk.ukrainian%23holiday%40group.v.calendar.google.com/public/basic.ics"

# --- 1. Асинхронне завантаження календаря ---
# Якщо файлу немає в /tmp (перший старт після увімкнення ПК)
if [ ! -f "$TMP_FILE" ]; then
    touch "$TMP_FILE"
    curl -s "$URL" -o "$TMP_FILE" &
fi

# --- 2. Блок державних свят ---
ICON_HOLIDAY=""
HOLIDAY=""

# Перевіряємо, чи файл не порожній (якщо завантаження ще триває)
if [ -s "$TMP_FILE" ]; then
    HOLIDAY=$(rg -A 15 "DTSTART;VALUE=DATE:$TODAY" "$TMP_FILE" | rg "^SUMMARY:" | head -n 1 | sed 's/SUMMARY://' | tr -d '\r')

    if [ -n "$HOLIDAY" ]; then
        ICON_HOLIDAY="🔔 "
        if [ ! -f "$FLAG" ]; then
            dunstify "Сьогодні свято" "$HOLIDAY"
            touch "$FLAG"
        fi
    fi
fi

# --- 3. Блок локальних подій (C) ---
LOCAL_EVENTS=$($EVENTS_BIN 2>/dev/null)

# --- 4. Фінальний вивід для панелі ---
echo "${ICON_HOLIDAY}${LOCAL_EVENTS}"
