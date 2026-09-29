#!/bin/bash
# 
set -u

# потрібен xsettingsd
if ! command -v xsettingsd >/dev/null 2>&1; then
    echo "Помилка: xsettingsd не встановлений."
    exit 1
fi

if ! pgrep -x xsettingsd >/dev/null; then
    echo "Помилка: xsettingsd не запущений."
    exit 1
fi

THEMES_DIR="$HOME/.themes"
WALLPAPER="$THEMES_DIR/wallpaper.jpg"

LIGHTSOLID="#E3E2CF"
DARKSOLID="#2A2E2A"

LIGHTMODE_FILE="$HOME/.lightmode"

GTK3_CONFIG="$HOME/.config/gtk-3.0/settings.ini"

BAT_CONFIG_DIR="$HOME/.config/bat"
BAT_CONFIG="$BAT_CONFIG_DIR/config"


# ============================================================
# Визначення режиму
# ============================================================

case "${1:-}" in

    start)
        # Автоматичний режим за часом (світлий з 5 до 19, інакше темний)
        current_hour=$(date +%H)
        current_hour=$((10#$current_hour))
        
        if (( current_hour >= 5 && current_hour < 19 )); then
            NEW_MODE="light"
        else
            NEW_MODE="dark"
        fi
        ;;

    light)
        NEW_MODE="light"
        ;;

    dark)
        NEW_MODE="dark"
        ;;

    "")
        # Ручне перемикання: перевіряємо наявність файлу ~/.lightmode
        if [[ -f "$LIGHTMODE_FILE" ]]; then
            NEW_MODE="dark"
        else
            NEW_MODE="light"
        fi
        ;;

    *)
        echo "Використання:"
        echo "  $0 start   - режим за часом"
        echo "  $0 light   - світлий режим"
        echo "  $0 dark    - темний режим"
        echo "  $0         - перемикнути режим"
        exit 2
        ;;

esac

echo "Режим: $NEW_MODE"


# ============================================================
# Wallpaper
# ============================================================

if [[ "$NEW_MODE" == "light" ]]; then
    SOLID="$LIGHTSOLID"
else
    SOLID="$DARKSOLID"
fi

if command -v hsetroot >/dev/null 2>&1; then
    hsetroot -solid "$SOLID" -center "$WALLPAPER"
fi


# ============================================================
# GTK
# ============================================================

if [[ "$NEW_MODE" == "dark" ]]; then
    GTK_THEME="W9_Dark"      # Замініть на вашу реальну темну тему
else
    GTK_THEME="W9" # Замініть на вашу реальну світлу тему
fi

mkdir -p "$(dirname "$GTK3_CONFIG")"

CURRENT_GTK_THEME=""
if [[ -f "$GTK3_CONFIG" ]]; then
    CURRENT_GTK_THEME=$(sed -n 's/^gtk-theme-name=//p' "$GTK3_CONFIG" | head -n1)
fi

if [[ "$CURRENT_GTK_THEME" != "$GTK_THEME" ]]; then
    if [[ -f "$GTK3_CONFIG" ]] && grep -q '^gtk-theme-name=' "$GTK3_CONFIG"; then
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$GTK3_CONFIG"
    elif [[ -f "$GTK3_CONFIG" ]] && grep -q '^\[Settings\]' "$GTK3_CONFIG"; then
        sed -i "/^\[Settings\]/a gtk-theme-name=$GTK_THEME" "$GTK3_CONFIG"
    else
        cat > "$GTK3_CONFIG" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
EOF
    fi
    echo "GTK: $GTK_THEME"
fi


# ============================================================
# Xsettingsd (оновлення демона на льоту)
# ============================================================

XSETTINGS_CONF="$HOME/.xsettingsd"

# Записуємо параметр теми у форматі xsettingsd
if [[ -f "$XSETTINGS_CONF" ]] && grep -q 'Net/ThemeName' "$XSETTINGS_CONF"; then
    sed -i "s|Net/ThemeName.*|Net/ThemeName \"$GTK_THEME\"|" "$XSETTINGS_CONF"
else
    echo "Net/ThemeName \"$GTK_THEME\"" >> "$XSETTINGS_CONF"
fi

# Сигналимо демону xsettingsd оновити конфігурацію на льоту
pkill -HUP xsettingsd || true


# ============================================================
# ST (Xresources + оновлення палітри для відкритих вікон)
# ============================================================

XRES_LIGHT="$HOME/.Xresources.light"
XRES_DARK="$HOME/.Xresources.dark"

if [[ "$NEW_MODE" == "dark" ]]; then
    XRES_FILE="$XRES_DARK"
else
    XRES_FILE="$XRES_LIGHT"
fi

if [[ ! -f "$XRES_FILE" ]]; then
    echo "Попередження: немає $XRES_FILE"
else
    # --------------------------------------------------------
    # 1. Оновлюємо xrdb
    # --------------------------------------------------------

    xrdb -merge "$XRES_FILE"

    # --------------------------------------------------------
    # 2. Читаємо палітру st безпосередньо з Xresources
    # --------------------------------------------------------

    XRDB=$(xrdb -query)

    declare -a COLORS

    for i in {0..15}; do
        COLORS[$i]=$(printf '%s\n' "$XRDB" |
            awk -v n="st.color$i:" '$1 == n {print $2; exit}')
    done

    COLORS[16]=$(printf '%s\n' "$XRDB" |
        awk '$1 == "st.foreground:" {print $2; exit}')

    COLORS[17]=$(printf '%s\n' "$XRDB" |
        awk '$1 == "st.background:" {print $2; exit}')

    COLORS[18]=$(printf '%s\n' "$XRDB" |
        awk '$1 == "st.cursorColor:" {print $2; exit}')

    # --------------------------------------------------------
    # 3. Формуємо OSC для вже відкритих st
    # --------------------------------------------------------

    osc_seq=""

    for i in {0..15}; do
        [[ -n "${COLORS[$i]:-}" ]] &&
            osc_seq+="\033]4;${i};${COLORS[$i]}\007"
    done

    [[ -n "${COLORS[16]:-}" ]] &&
        osc_seq+="\033]10;${COLORS[16]}\007"

    [[ -n "${COLORS[17]:-}" ]] &&
        osc_seq+="\033]11;${COLORS[17]}\007"

    [[ -n "${COLORS[18]:-}" ]] &&
        osc_seq+="\033]12;${COLORS[18]}\007"

    # --------------------------------------------------------
    # 4. Надсилаємо нову палітру у вже відкриті st
    # --------------------------------------------------------

    for pty in /dev/pts/[0-9]*; do
        if [[ -w "$pty" ]]; then
            printf '%b' "$osc_seq" > "$pty" 2>/dev/null || true
        fi
    done
fi

# ============================================================
# DWM Mode File State
# ============================================================

if [[ "$NEW_MODE" == "light" ]]; then
    touch "$LIGHTMODE_FILE"
else
    rm -f -- "$LIGHTMODE_FILE"
fi


# ============================================================
# Перезавантаження DWM
# ============================================================

mapfile -t DWM_PIDS < <(pgrep -x dwm)

if ((${#DWM_PIDS[@]})); then
    kill -HUP "${DWM_PIDS[@]}"
fi


# ============================================================
# bat
# ============================================================

mkdir -p "$BAT_CONFIG_DIR"

if [[ "$NEW_MODE" == "dark" ]]; then
    BAT_THEME="Monokai Extended"
else
    BAT_THEME="GitHub"
fi

NEW_BAT_CONFIG="--theme=\"$BAT_THEME\""
CURRENT_BAT_CONFIG=""

if [[ -f "$BAT_CONFIG" ]]; then
    CURRENT_BAT_CONFIG=$(<"$BAT_CONFIG")
fi

if [[ "$CURRENT_BAT_CONFIG" != "$NEW_BAT_CONFIG" ]]; then
    printf '%s\n' "$NEW_BAT_CONFIG" > "$BAT_CONFIG"
fi

echo "Готово: $NEW_MODE"
