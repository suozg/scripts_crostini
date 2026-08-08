#!/bin/bash
# перемикання клавіатури
initial_layout=$(cat /tmp/dwm_layout 2>/dev/null || echo "🗽US")
if [[ "$current" == "us" ]]; then
    xkb-switch -s ua
    echo "🌻UA" > /tmp/dwm_layout
    pkill -RTMIN+1 dwmblocks
fi

# Шляхи до нової системи
SCRIPT_PATH="$HOME/.local/bin/dwm"
ORG_PATH="$HOME/awards/org"
DIARY_FILE="$ORG_PATH/diary.org"
FONT="monospace:size=12"

# --- Функція для розумного виклику dmenu ---
dmenu_cmd() {
    local prompt="$1"
    local opts=("-i" "-p" "$prompt" "-fn" "$FONT")
    if [[ -f "$HOME/.lightmode" ]]; then
        opts+=("-nb" "#eeeeee" "-nf" "#222222" "-sb" "#005577" "-sf" "#eeeeee")
    fi
    dmenu "${opts[@]}"
}

# Меню dmenu через нашу функцію
choice=$(printf  "📝Створити\n📅Сьогодні\n📚Всі записи\n🔍Відкрити файл" | dmenu_cmd "Завдання:")

case "$choice" in
    "📝Створити")
        $SCRIPT_PATH/my_tasks_add.sh
        ;;
    "📅Сьогодні")
        $HOME/.local/bin/st -e nvim --cmd "let g:session_autoload = 'no'" -c "lua require('orgmode').agenda:todos()"
        ;;
    "📚Всі записи")
        $HOME/.local/bin/st -e nvim  --cmd "let g:session_autoload = 'no'" -c "lua require('orgmode').agenda:agenda()"
        ;;
    "🔍Відкрити файл")
        $HOME/.local/bin/st -e nvim "$DIARY_FILE"
        ;;
esac
