#!/bin/bash

DIARY_PATH="$HOME/awards/vimwiki/diary"
TODAY_FILE="$DIARY_PATH/$(date +%Y-%m-%d).md"

choice=$(printf "Створити\nСьогодні\nВсі записи" | dmenu -p "Завдання:" -fn "monospace:size=12")

case "$choice" in
    "Створити")
        ~/awards/scripts/dwm/my_tasks_add.sh
        ;;

    "Сьогодні")
        # Відкриваємо саме сьогоднішній файл. Якщо його немає — створюємо з заголовком.
        [ -f "$TODAY_FILE" ] || echo "# $(date +%Y-%m-%d)" > "$TODAY_FILE"
        ~/awards/scripts/st -e nvim "$TODAY_FILE"
        pkill -RTMIN+10 dwmblocks
        ;;

    "Всі записи")
        # Відкриваємо головний індекс Vimwiki, щоб бачити календар та інші нотатки
        ~/awards/scripts/st -e nvim -c "VimwikiDiaryIndex"
        pkill -RTMIN+10 dwmblocks
        ;;

esac
