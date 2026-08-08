#!/usr/bin/env bash

WIKI_PATH="$HOME/awards/org-wiki"
TERMINAL="$HOME/awards/scripts/st"
COLOR_PICKER="$HOME/.local/bin/dwm/selcolor_with_dmenuklik.sh"

while true; do
    # Створюємо гарну тонку лінію для dmenu
    line="────────────────────────────────────────"

    # Формуємо список: спочатку колір, потім лінія, потім файли
    selection=$({ 
        echo "🎨 Колір під курсором"
        echo "$line"
        find "$WIKI_PATH" -name "*.org" -printf "%f\n" | sed 's/\.org//'
    } | dmenu -i -l 12 -p "📖 Довідка:" -fn "monospace:size=12")

    [[ -z "$selection" ]] && exit 0

    # Якщо обрали лінію-роздільник — просто ігноруємо і відкриваємо меню заново
    if [[ "$selection" == "$line" ]]; then
        continue
    fi

    # Якщо обрали вибір кольору
    if [[ "$selection" == "🎨 Колір під курсором" ]]; then
        if [[ -x "$COLOR_PICKER" ]]; then
            "$COLOR_PICKER"
        else
            sh "$COLOR_PICKER"
        fi
        continue
    fi

    # Якщо обрали файл довідки
    page="$WIKI_PATH/$selection.org"

    while true; do
        $TERMINAL -t "View: $selection" -e bash -c "glow -p \"$page\""
        
        action=$(dmenu -i -p "Файл: $selection" -fn "monospace:size=12" <<< "❌ Close
✏ Edit
🔄 Re-read")

        case "$action" in
            "✏ Edit")
                $TERMINAL -t "Edit: $selection" -e nvim "$page"
                ;;
            "🔄 Re-read")
                continue
                ;;
            *)
                break
                ;;
        esac
    done
done
