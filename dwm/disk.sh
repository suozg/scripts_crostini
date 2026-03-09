#!/bin/sh
# Використання кореневого розділу (/)
usage1=$(df -h | awk '$NF == "/" {print "⛁ " $5}')

# Використання /tmp
usage2=$(df -h | awk '$NF == "/tmp" {print " ▒" $5}')

# Кількість файлів у корзині
trash_count=$(trash-list 2>/dev/null | wc -l)

if [ "$trash_count" -gt 0 ]; then
    trash_icon=" 🗑"
    echo "${usage1}${usage2}${trash_icon}"
else
    echo "${usage1}${usage2}"
fi
