#!/bin/sh

LOCK="/tmp/dwm-autostart.lock"

if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then
    exit 0
fi

echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT INT TERM

[ -f ~/.profile ] && . ~/.profile

xsettingsd &
/home/alex320388/.local/bin/dwm/watch_caps &

# встановлення розкладки
setxkbmap -layout "us,ua" -option "lv3:ralt_switch"
xset r rate 250 40
sleep 0.3

# Встановлення теми
/home/alex320388/.local/bin/set-theme-based-on-time.sh start  # dark OR start 

# Композитний менеджер
picom &

st -t "Розклад справ та завдань" -e nvim -c 'autocmd VimEnter * ++once lua require("orgmode").agenda:todos()' &
