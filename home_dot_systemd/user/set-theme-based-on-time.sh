#!/bin/bash

set -u

THEMES_DIR="$HOME/.themes"
WALLPAPER="$THEMES_DIR/wallpaper.jpg"

LIGHTSOLID="#E3E2CF"
DARKSOLID="#2A2E2A"

LIGHTMODE_FILE="$HOME/.lightmode"

GTK3_CONFIG="$HOME/.config/gtk-3.0/settings.ini"

LO_CONF="$HOME/.config/libreoffice/4/user/registrymodifications.xcu"
LO_LIGHT_CONF="$HOME/.config/libreoffice/4/user/registrymodifications.xcu.light"
LO_DARK_CONF="$HOME/.config/libreoffice/4/user/registrymodifications.xcu.dark"

GEANY_CONF="$HOME/.config/geany/geany.conf"
GEANY_LIGHT="$HOME/.config/geany/geany_light.conf"
GEANY_DARK="$HOME/.config/geany/geany_dark.conf"

BAT_CONFIG_DIR="$HOME/.config/bat"
BAT_CONFIG="$BAT_CONFIG_DIR/config"

VISIDATA_CONFIG="$HOME/.visidatarc"
VISIDATA_LIGHT="$HOME/.config/visidata/visidatarc-light"
VISIDATA_DARK="$HOME/.config/visidata/visidatarc-dark"

ST_LIGHT="$HOME/.local/bin/dwm/st_w"
ST_DARK="$HOME/.local/bin/dwm/st_b"
ST_LINK="$HOME/.local/bin/st"


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
# LibreOffice
# ============================================================

if ! pgrep -x soffice.bin >/dev/null && \
   ! pgrep -x libreoffice >/dev/null && \
   ! pgrep -x oosplash >/dev/null; then

    if [[ "$NEW_MODE" == "dark" ]]; then
        TARGET_LO_CONF="$LO_DARK_CONF"
    else
        TARGET_LO_CONF="$LO_LIGHT_CONF"
    fi

    if [[ -f "$TARGET_LO_CONF" ]]; then
        if [[ ! -f "$LO_CONF" ]] || ! cmp -s "$TARGET_LO_CONF" "$LO_CONF"; then
            mkdir -p "$(dirname "$LO_CONF")"
            cp -f -- "$TARGET_LO_CONF" "$LO_CONF"
            echo "LibreOffice: $NEW_MODE"
        fi
    else
        echo "Попередження: немає $TARGET_LO_CONF"
    fi
else
    echo "LibreOffice запущено — конфігурацію не змінено."
fi


# ============================================================
# ST
# ============================================================

if [[ "$NEW_MODE" == "dark" ]]; then
    ST_TARGET="$ST_DARK"
else
    ST_TARGET="$ST_LIGHT"
fi

if [[ -e "$ST_TARGET" ]]; then
    ln -sfn "$ST_TARGET" "$ST_LINK"
else
    echo "Попередження: не знайдено $ST_TARGET"
fi


# ============================================================
# Geany
# ============================================================

if command -v geany >/dev/null 2>&1; then
    if [[ "$NEW_MODE" == "dark" ]]; then
        TARGET_GEANY_CONF="$GEANY_DARK"
    else
        TARGET_GEANY_CONF="$GEANY_LIGHT"
    fi

    if [[ -f "$TARGET_GEANY_CONF" ]]; then
        if [[ ! -f "$GEANY_CONF" ]] || ! cmp -s "$TARGET_GEANY_CONF" "$GEANY_CONF"; then
            mkdir -p "$(dirname "$GEANY_CONF")"
            cp -- "$TARGET_GEANY_CONF" "$GEANY_CONF"
            echo "Geany: $NEW_MODE"
        fi
    else
        echo "Попередження: немає $TARGET_GEANY_CONF"
    fi
fi


# ============================================================
# VisiData
# ============================================================

if [[ "$NEW_MODE" == "dark" ]]; then
    VISIDATA_TARGET="$VISIDATA_DARK"
else
    VISIDATA_TARGET="$VISIDATA_LIGHT"
fi

if [[ -f "$VISIDATA_TARGET" ]]; then
    ln -sfn "$VISIDATA_TARGET" "$VISIDATA_CONFIG"
else
    echo "Попередження: немає $VISIDATA_TARGET"
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
