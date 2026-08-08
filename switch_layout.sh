#!/bin/bash
# переключение раскладки клавиатуры

# Дивимось, яка розкладка зараз записана у файлі dwm
if [ -f /tmp/dwm_layout ] && grep -q "UA" /tmp/dwm_layout; then
    xkb-switch -s us
    echo "🗽US" > /tmp/dwm_layout
else
    xkb-switch -s ua
    echo "🌻UA" > /tmp/dwm_layout
fi

pkill -RTMIN+1 dwmblocks
