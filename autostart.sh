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
$HOME/.local/bin/set-theme-based-on-time.sh dark  # dark OR start 

# Композитний менеджер
picom &

# btop 
#st -n btop -e btop 2>/dev/null &

# internet trafik
#st -n nethogs -e sudo nethogs -a &

# Перевіряємо, чи скрипт pererva.sh уже запущений, і вбиваємо стару копію перед новим стартом
pkill -f "pererva.sh"

# Запускаємо скрипт перерви у фоні
$HOME/.local/bin/dwm/pererva.sh &
