#!/usr/bin/env bash

WIKI_PATH="$HOME/awards/org-wiki"
TERMINAL="$HOME/awards/scripts/st"
COLOR_PICKER="$HOME/.local/bin/dwm/selcolor_with_dmenuklik.sh"
FONT="monospace:size=12"

# --------------------------------------------------
# dmenu: единые настройки
# --------------------------------------------------

dmenu_cmd() {
    local prompt="$1"
    shift

    local colors=()

    if [[ -f "$HOME/.lightmode" ]]; then
        colors=(
            -nb "#eeeeee"
            -nf "#222222"
            -sb "#005577"
            -sf "#eeeeee"
        )
    fi

    dmenu -i -fn "$FONT" "${colors[@]}" -p "$prompt" "$@"
}

# --------------------------------------------------
# Справка по клавишам dwm
# --------------------------------------------------

show_keys() {
    cat <<'EOF' | dmenu_cmd "⌨ Клавіші:" -l 14
Alt+Return              Переместить окно в master (zoom)
Ctrl+\                  Открыть файловый менеджер lf
Alt+a                   Открыть Org Agenda
Alt+F6                  Принудительно запустить Eye Break
Alt+F7                  Пропустить Eye Break
Ctrl+Alt+t              Переключить тему
Alt+p                   Запустить dmenu
Alt+Ctrl+Return         Открыть терминал st
Alt+Shift+s             Выбор цвета под курсором
Alt+Refresh             Калькулятор
Alt+\                   Редактировать задачи
Alt+z                   Получить содержимое буфера обмена
Alt+Shift+z             Отправить в буфер обмена
Alt+x                   Меню истории буфера обмена
Alt+Shift+x             Очистить историю буфера обмена
Alt+n                   Запустить AWARDS53
Alt+Shift+n             Запустить DRS
Alt+Shift+r             Интернет-радио
Alt+/                   Открыть справку
Ctrl+Space              Переключить раскладку клавиатуры
Alt+b                   Показать / скрыть панель dwm
Alt+j / Alt+k           Фокус вниз / вверх по стеку
Alt+h / Alt+l           Уменьшить / увеличить master (mfact)
Alt+i / Alt+d           Больше / меньше master-окон
Alt+t                   Раскладка tile ([]=)
Alt+f                   Раскладка floating (><>)
Alt+m                   Раскладка monocle ([M])
Alt+r                   Раскладка doubledeck (DD)
Alt+Space               Следующая раскладка
Ctrl+Alt+Space          Переключить floating
Alt+Shift+t             Вернуться к предыдущему тегу
Alt+Shift+c             Закрыть активное окно
Alt+0                   Показать все теги
Alt+Shift+0             Назначить все теги окну
Alt+, / Alt+.           Переключить монитор влево / вправо
Alt+Shift+, / Alt+Shift+. Переместить окно на другой монитор
Alt+1 ... Alt+9         Переключить тег
Ctrl+Alt+1 ... Ctrl+Alt+9 Показать / скрыть тег
Alt+Shift+1 ... Alt+Shift+9 Назначить тег окну
Ctrl+Alt+Shift+1 ... 9   Добавить / убрать тег у окна
Alt+Shift+q             Выход из dwm
EOF
}

# --------------------------------------------------
# Просмотр Org-справки
# --------------------------------------------------

show_wiki() {
    while true; do

        selection=$(
            {
                find "$WIKI_PATH" -name "*.org" -printf "%f\n" | sed 's/\.org//'
            } | dmenu_cmd "📖 Довідка:" -l 12
        )

        [[ -z "$selection" ]] && return

        page="$WIKI_PATH/$selection.org"

        "$TERMINAL" -t "View: $selection" -e bash -c \
            'glow -p "$1"' _ "$page"

        action=$(printf '%s\n' \
            "❌ Close" \
            "✏ Edit" \
            "🔄 Re-read" |
            dmenu_cmd "Файл: $selection")

        case "$action" in
            "✏ Edit")
                "$TERMINAL" -t "Edit: $selection" -e nvim "$page"
                ;;
            "🔄 Re-read")
                continue
                ;;
            *)
                break
                ;;
        esac
    done
}

# --------------------------------------------------
# Главное меню
# --------------------------------------------------

while true; do

    selection=$(printf '%s\n' \
        "⌨ Клавіші dwm" \
        "📖 Довідка" \
        "🎨 Колір під курсором" |
        dmenu_cmd "?:" -l 3)

    case "$selection" in
        "⌨ Клавіші dwm")
            show_keys
            ;;
        "📖 Довідка")
            show_wiki
            ;;
        "🎨 Колір під курсором")
            if [[ -x "$COLOR_PICKER" ]]; then
                "$COLOR_PICKER"
            else
                sh "$COLOR_PICKER"
            fi
            ;;
        *)
            exit 0
            ;;
    esac
done
