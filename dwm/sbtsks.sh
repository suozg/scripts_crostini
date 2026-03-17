#!/bin/bash

# --- Налаштування ---
TMP_FILE="/tmp/ukraine_holidays.ics"
EVENTS_BIN="/home/alex320388/.local/bin/dwm/my_tasks"
TODAY=$(date +%Y%m%d)
FLAG="/tmp/holiday_notified_$TODAY"

# --- 1. Блок державних свят (Bash) ---
# Завантажуємо календар, якщо його немає
[[ ! -f "$TMP_FILE" ]] && curl -s "https://calendar.google.com/calendar/ical/uk.ukrainian%23holiday%40group.v.calendar.google.com/public/basic.ics" -o "$TMP_FILE"

# Шукаємо свято через ripgrep
HOLIDAY=$(rg -A 15 "DTSTART;VALUE=DATE:$TODAY" "$TMP_FILE" | rg "^SUMMARY:" | head -n 1 | sed 's/SUMMARY://' | tr -d '\r')

# Вивід іконки для панелі (якщо є свято)
ICON_HOLIDAY=""
if [ -n "$HOLIDAY" ]; then
    ICON_HOLIDAY="🔔 "
    # Сповіщення один раз на день
    if [ ! -f "$FLAG" ]; then
        notify-send "Сьогодні свято" "$HOLIDAY"
        touch "$FLAG"
    fi
fi

# --- 2. Блок локальних подій (C) ---
# Викликаємо скомпільовану програму і зберігаємо її вивід
LOCAL_EVENTS=$($EVENTS_BIN)

# --- 3. Фінальний вивід для панелі (dwmblocks/i3blocks) ---
# Об'єднуємо іконку свята та результат роботи C-скрипта
echo "${ICON_HOLIDAY}${LOCAL_EVENTS}"
