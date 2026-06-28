#!/bin/bash

# 1. Отримуємо вивід setxkbmap у змінну один раз
output=$(setxkbmap -query)

# 2. Використовуємо вбудовану заміну рядків Bash для пошуку розкладки
# Шукаємо частину після "layout:"
current="${output##*layout: }"
# Відрізаємо все, що йде після назви розкладки (наступні рядки)
current="${current%%$'\n'*}"
# Прибираємо зайві пробіли, якщо вони є
current="${current//[[:space:]]/}"

OPTIONS="lv3:ralt_switch"

if [ "$1" = "status" ]; then
    [[ "$current" == "us" ]] && echo "🗽US" || echo "🌻UA"
    exit 0
fi

# 3. Логіка перемикання
if [[ "$current" == "us" ]]; then
    setxkbmap -layout ua -option "$OPTIONS"
else
    setxkbmap -layout us -option "$OPTIONS"
fi

pkill -RTMIN+1 dwmblocks

