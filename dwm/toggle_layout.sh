#!/bin/bash

# 1. Отримуємо поточну розкладку миттєво через xkb-switch
current=$(xkb-switch -p)

# 2. Режим для dwmblocks (відображення статусу)
if [ "$1" = "status" ]; then
    [[ "$current" == "us" ]] && echo "🗽US" || echo "🌻UA"
    exit 0
fi

# 3. Логіка миттєвого перемикання
if [[ "$current" == "us" ]]; then
    xkb-switch -s ua
else
    xkb-switch -s us
fi

# 4. Сповіщаємо dwmblocks, щоб емодзі в панелі змінився миттєво
pkill -RTMIN+1 dwmblocks
