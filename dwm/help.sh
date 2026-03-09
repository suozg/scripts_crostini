#!/usr/bin/env bash
set -euo pipefail

# Папка с Vimwiki
WIKI_PATH="$HOME/awards/vimwiki"

# Все файлы кроме index
pages=$(ls "$WIKI_PATH"/*.md | xargs -n1 basename | sed 's/\.md//' | grep -v '^index$')

# Формируем список для dmenu: сначала страницы, потом edit, потом color
choices=""
for p in $pages; do
    choices+="$p\n"
done
choices+="edit\ncolor\n"

# Выбор пункта
selection=$(echo -e "$choices" | dmenu -i -p "Довідка та інструменти:" -fn "monospace:size=12")
[ -z "$selection" ] && exit 0

# Обрабатываем выбор
if [ "$selection" = "edit" ]; then
    page="$WIKI_PATH/index.md"
    ~/awards/scripts/st -t "Редагування Wiki" -e nvim "$page"
elif [ "$selection" = "color" ]; then
    # Запускаем скрипт выбора цвета
    /home/alex320388/.local/bin/dwm/selcolor_with_dmenuklik.sh
else
    page="$WIKI_PATH/$selection.md"
    ~/awards/scripts/st -t "Довідка Wiki:$selection" -e bash -c "glow -p \"$page\""
fi
