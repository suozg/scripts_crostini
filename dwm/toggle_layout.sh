#!/bin/bash

# 1. Режим для dwmblocks (просто читаємо те, що підготував dwm)
if [ "$1" = "status" ]; then
    if [ -f /tmp/dwm_layout ]; then
        cat /tmp/dwm_layout
    else
        echo "🗽US"
    fi
    exit 0
fi

# 2. Логіка перемикання розкладки за допомогою xkb-switch
# (оскільки це робиться вручну користувачем за гарячою клавішею)
current=$(xkb-switch -p)
if [[ "$current" == "us" ]]; then
    xkb-switch -s ua
else
    xkb-switch -s us
fi

# 3. Примусово оновлюємо файл і сповіщаємо dwmblocks про зміни
if [[ "$current" == "us" ]]; then
    echo "🌻UA" > /tmp/dwm_layout
else
    echo "🗽US" > /tmp/dwm_layout
fi

pkill -RTMIN+1 dwmblocks
