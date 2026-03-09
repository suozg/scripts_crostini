#!/bin/bash

TMP_FILE="/tmp/ukraine_holidays.ics"
TODAY=$(date +%Y%m%d)
[[ ! -f "$TMP_FILE" ]] && curl -s "https://calendar.google.com/calendar/ical/uk.ukrainian%23holiday%40group.v.calendar.google.com/public/basic.ics" -o "$TMP_FILE"

# Шукаємо свято
HOLIDAY=$(rg -A 15 "DTSTART;VALUE=DATE:$TODAY" "$TMP_FILE" | rg "^SUMMARY:" | head -n 1 | sed 's/SUMMARY://' | tr -d '\r')

if [ ! -z "$HOLIDAY" ]; then
    # Виводимо в панель (з іконкою)
    echo "🔔"
    # Створюємо "мітку", щоб не спамити notify-send
    # Якщо сповіщення сьогодні ще не було — надсилаємо
    FLAG="/tmp/holiday_notified_$TODAY"
    if [ ! -f "$FLAG" ]; then
        notify-send "Сьогодні свято" "$HOLIDAY"
        touch "$FLAG"
    fi
else
    echo ""
fi
