#!/usr/bin/env bash
set -euo pipefail

WIKI_PATH="$HOME/awards/vimwiki"

ICON_PAGE="📄"
ICON_EDIT="✏"
ICON_COLOR="🎨"
ICON_MENU="📚"

choices=""
declare -A map

while IFS= read -r file; do
    name=$(basename "$file" .md)
    [[ "$name" == "index" ]] && continue

    up=${name^^}
    label="$ICON_PAGE $up"

    choices+="$label\n"
    map["$label"]="$name"
done < <(find "$WIKI_PATH" -maxdepth 1 -type f -name "*.md" | sort)

choices+="$ICON_EDIT EDIT\n"
choices+="$ICON_COLOR COLOR\n"

selection=$(printf "%b" "$choices" | dmenu -i -l 10 -p "$ICON_MENU Довідка та інструменти:" -fn "monospace:size=12")
[[ -z "$selection" ]] && exit 0

if [[ "$selection" == "$ICON_EDIT EDIT" ]]; then
    page="$WIKI_PATH/index.md"
    ~/awards/scripts/st -t "Редагування Wiki" -e nvim "$page"

elif [[ "$selection" == "$ICON_COLOR COLOR" ]]; then
    /home/alex320388/.local/bin/dwm/selcolor_with_dmenuklik.sh

else
    page="$WIKI_PATH/${map[$selection]}.md"
    ~/awards/scripts/st -t "Довідка Wiki:$selection" -e bash -c "glow -p \"$page\""
fi
