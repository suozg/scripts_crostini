#!/bin/bash
choice=$(printf "Створити\nВидалити\nРедагувати" | dmenu -p "Завдання:" -fn "monospace:size=12")

case "$choice" in
    Створити)
        ~/awards/scripts/dwm/my_tasks_add.sh
        ;;
    Видалити)
        ~/awards/scripts/dwm/my_tasks_del.sh
        ;;
    "Редагувати")
        ~/awards/scripts/st -e sh -c 'printf "\033]0;Редагування Завдань\007"; vim ~/awards/events.txt'
        pkill -RTMIN+10 dwmblocks
        ;;
esac

