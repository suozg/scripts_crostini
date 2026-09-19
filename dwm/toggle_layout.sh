#!/bin/bash

# Функція для отримання індикатора Caps Lock
get_caps() {
    if xset q 2>/dev/null | grep -q "Caps Lock:\s*on"; then
        echo "🔒" # Текст/іконка при включеному Caps Lock
    fi
}

# 1. Режим для dwmblocks (читаємо те, що підготував dwm + Caps Lock)
if [ "$1" = "status" ]; then
    caps=$(get_caps)
    if [ -f /tmp/dwm_layout ]; then
        echo "$(cat /tmp/dwm_layout)$caps"
    else
        echo "🗽US$caps"
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
