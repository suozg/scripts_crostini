#!/usr/bin/env bash

WIKI_PATH="$HOME/awards/org-wiki"
TERMINAL="$HOME/awards/scripts/st"
COLOR_PICKER="$HOME/.local/bin/dwm/selcolor_with_dmenuklik.sh"
FONT="monospace:size=12"

dmenu_cmd() {
    local prompt="$1"
    shift

    if [[ -f "$HOME/.lightmode" ]]; then
        dmenu \
            -i \
            -p "$prompt" \
            -fn "$FONT" \
            -nb "#eeeeee" \
            -nf "#222222" \
            -sb "#005577" \
            -sf "#eeeeee" \
            "$@"
    else
        dmenu \
            -i \
            -p "$prompt" \
            -fn "$FONT" \
            "$@"
    fi
}

while true; do

    selection=$({
        echo "🎨 Колір під курсором"
        echo ""
        find "$WIKI_PATH" -name "*.org" -printf "%f\n" | sed 's/\.org//'
    } | dmenu_cmd "📖 Довідка:" -l 12)

    [[ -z "$selection" ]] && exit 0

    if [[ "$selection" == "$line" ]]; then
        continue
    fi

    if [[ "$selection" == "🎨 Колір під курсором" ]]; then
        if [[ -x "$COLOR_PICKER" ]]; then
            "$COLOR_PICKER"
        else
            sh "$COLOR_PICKER"
        fi
        continue
    fi

    page="$WIKI_PATH/$selection.org"

        $TERMINAL -t "View: $selection" -e bash -c "glow -p \"$page\""

        action=$(dmenu_cmd "Файл: $selection" <<EOF
❌ Close
✏ Edit
🔄 Re-read
EOF
)
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
