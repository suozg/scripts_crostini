#!/bin/bash

# 1. Режим для dwmblocks (читаємо те, що підготував dwm)
if [ "$1" = "status" ]; then
    if [ -f /tmp/dwm_layout ]; then
        cat /tmp/dwm_layout
    else
        echo "🗽US"
    fi
    exit 0
fi

# 2. Логіка перемикання розкладки
current=$(xkb-switch -p)
if [[ "$current" == "us" ]]; then
    target="ua"
    display_text="🌻UA"
else
    target="us"
    display_text="🗽US"
fi

# Пробуємо перемкнути
if xkb-switch -s "$target"; then
    # 3. Якщо перемкнувся, оновлюємо файл і сповіщаємо dwmblocks
    echo "$display_text" > /tmp/dwm_layout
    pkill -RTMIN+1 dwmblocks
fi
