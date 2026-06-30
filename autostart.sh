#!/bin/sh

LOCK="/tmp/dwm-autostart.lock"

if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then
    exit 0
fi

echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT INT TERM

[ -f ~/.profile ] && . ~/.profile

# встановлення розкладки
setxkbmap -layout "us,ua" -option "lv3:ralt_switch"
xset r rate 250 40

# Встановлення теми
/home/alex320388/.local/bin/set-theme-based-on-time.sh dark  # dark OR start 
# Композитний менеджер
picom &

