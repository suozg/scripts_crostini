#!/bin/bash

THEMES_DIR="$HOME/.themes"
WALLPAPER="wallpaper.jpg"
LIGHTSOLID="#E3E2CF"
DARKSOLID="#2A2E2A"
LIGHTMODE_FILE="$HOME/.lightmode"

# === Проверка аргумента командной строки ===
if [[ "$1" == "start" ]]; then
    # === определяем режим по времени суток ===
    current_hour=$(date +%H | sed 's/^0*//')
    day_start=5    # утро
    day_end=19     # вечер

    if [[ "$current_hour" -ge "$day_start" && "$current_hour" -lt "$day_end" ]]; then
        NEW_MODE="light"
        hsetroot -solid $LIGHTSOLID -center "$THEMES_DIR/$WALLPAPER" > /dev/null
    else
        NEW_MODE="dark"
        hsetroot -solid $DARKSOLID -center "$THEMES_DIR/$WALLPAPER" > /dev/null
    fi

# --- Встановлюємо режим, якщо передано 'light' або 'dark' ---
elif [[ "$1" == "light" ]]; then
    NEW_MODE="light"
    hsetroot -solid $LIGHTSOLID -center "$THEMES_DIR/$WALLPAPER" >/dev/null

elif [[ "$1" == "dark" ]]; then
    NEW_MODE="dark"
    hsetroot -solid $DARKSOLID -center "$THEMES_DIR/$WALLPAPER" >/dev/null

# --- Перемикаємо режим, якщо аргумент не передано або він невідомий ---
else
    # === Получить текущую тему GTK через settings.ini ===
    if [[ -f "$HOME/.config/gtk-3.0/settings.ini" ]]; then
        CURRENT_GTK_THEME=$(grep '^gtk-theme-name=' "$HOME/.config/gtk-3.0/settings.ini" | cut -d= -f2)
    else
        # fallback на gsettings
        CURRENT_GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme)
        CURRENT_GTK_THEME=${CURRENT_GTK_THEME//\'/}
    fi

    # === Определить режим по текущей теме ===
    if [[ "$CURRENT_GTK_THEME" =~ [Dd]ark ]]; then
        MODE="dark"
    else
        MODE="light"
    fi

    # === Определить новую тему (противоположную текущей) ===
    if [[ "$MODE" == "dark" ]]; then
        NEW_MODE="light"
        hsetroot -solid $LIGHTSOLID -center "$THEMES_DIR/$WALLPAPER" >/dev/null
    else
        NEW_MODE="dark"
        hsetroot -solid $DARKSOLID -center "$THEMES_DIR/$WALLPAPER" >/dev/null
    fi

fi

# === Визначаємо GTK тему ===
GTK_THEME=""

# Шукаємо теми в ~/.themes для нового режиму
if [[ -d "$THEMES_DIR" ]]; then
    for THEME in "$THEMES_DIR"/*; do
        [ -d "$THEME" ] || continue
        NAME=$(basename "$THEME")
        if [[ "$NEW_MODE" == "dark" && "$NAME" =~ [Dd]ark ]]; then
            GTK_THEME="$NAME"
            break
        elif [[ "$NEW_MODE" == "light" && ! "$NAME" =~ [Dd]ark ]]; then
            GTK_THEME="$NAME"
            break
        fi
    done
fi

# Якщо нічого не знайдено, використовуємо стандартну тему
if [[ -z "$GTK_THEME" ]]; then
    if [[ "$NEW_MODE" == "dark" ]]; then
        #GTK_THEME="Adwaita-dark"
        #GTK_THEME="Mojave-Dark"
        #GTK_THEME="Arc-Dark"
        GTK_THEME="W9"
    else
        #GTK_THEME="Adwaita"
        #GTK_THEME="Mojave-Light"        
        #GTK_THEME="Arc"
        GTK_THEME="W9_Dark"
    fi
fi

echo "Визначено режим $NEW_MODE."


# === Записуємо тему в ~/.config/gtk-3.0/settings.ini ===
GTK3_CONFIG="$HOME/.config/gtk-3.0/settings.ini"

# --- 1. Визначаємо, чи потрібно оновлювати тему ---
# Спочатку визначаємо поточну тему
CURRENT_GTK_THEME_CHECK=""
if [[ -f "$GTK3_CONFIG" ]]; then
    CURRENT_GTK_THEME_CHECK=$(grep '^gtk-theme-name=' "$GTK3_CONFIG" | cut -d= -f2)
else
    # Якщо файл не існує, використовуємо заглушку, яка не співпаде з $GTK_THEME
    CURRENT_GTK_THEME_CHECK="NONE"
fi

# Порівнюємо фактично встановлену тему з бажаною ($GTK_THEME)
if [[ "$CURRENT_GTK_THEME_CHECK" != "$GTK_THEME" ]]; then
    echo "Оновлення GTK: стара тема '$CURRENT_GTK_THEME_CHECK', нова '$GTK_THEME'."
    
    # --- Запис на диск тільки тут ---
    if [[ ! -f "$GTK3_CONFIG" ]]; then
        # 1. Створення директорії, якщо треба
        mkdir -p "$(dirname "$GTK3_CONFIG")" 
        # 2. Створення нового файлу
        cat > "$GTK3_CONFIG" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
EOF
    else
        # 3. Редагування існуючого файлу (запис)
        if grep -q '^gtk-theme-name=' "$GTK3_CONFIG"; then
            sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$GTK3_CONFIG"
        else
            sed -i "/^\[Settings\]/a gtk-theme-name=$GTK_THEME" "$GTK3_CONFIG"
        fi
    fi
    # --- Кінець запису на диск ---

else
    :
fi

# ---
# === Налаштування LibreOffice ===
LO_CONF="$HOME/.config/libreoffice/4/user/registrymodifications.xcu"
LO_LIGHT_CONF="$HOME/.config/libreoffice/4/user/registrymodifications.xcu.light"
LO_DARK_CONF="$HOME/.config/libreoffice/4/user/registrymodifications.xcu.dark"

# --- Перевірка, чи запущено LibreOffice ---
# Шукаємо основні процеси LibreOffice
if pgrep -x "soffice.bin" > /dev/null || pgrep -x "libreoffice" > /dev/null || pgrep -x "oosplash" > /dev/null; then
    echo "LibreOffice виконується. Зміни теми не будуть застосовані, щоб уникнути конфліктів."

else
    # === Визначити, який файл конфігурації LibreOffice використовувати ===
    TARGET_LO_CONF=""
    if [[ "$NEW_MODE" == "dark" ]]; then
        TARGET_LO_CONF="$LO_DARK_CONF"
    else
        TARGET_LO_CONF="$LO_LIGHT_CONF"
    fi

    # === Оновити конфігурацію LibreOffice шляхом копіювання файлу ===
    if [[ -f "$TARGET_LO_CONF" ]]; then
        # Перевіряємо, чи вже встановлена потрібна конфігурація, щоб уникнути зайвого копіювання
        if ! cmp -s "$TARGET_LO_CONF" "$LO_CONF"; then
            cp "$TARGET_LO_CONF" "$LO_CONF"
        else
            :
        fi
    else
        echo "Не знайдено еталонний файл конфігурації LibreOffice для режиму '$NEW_MODE': $TARGET_LO_CONF"
    fi

fi

# === Настройки ST terminal ===
if [[ "$NEW_MODE" == "dark" ]]; then
    ln -sf $HOME/.local/bin/dwm/st_b $HOME/.local/bin/st
else
    ln -sf $HOME/.local/bin/dwm/st_w $HOME/.local/bin/st
fi

#   if pgrep -x "sakura" > /dev/null; then
#       echo "Sakura виконується. Зміни теми не будуть застосовані, щоб уникнути конфліктів."

#   else
        # === Оновити конфігурацію шляхом копіювання файлу ===
#       if [[ -f "$TARGET_SAKURA_CONF" ]]; then
           # Перевіряємо, чи вже встановлена потрібна конфігурація, щоб уникнути зайвого копіювання
#          if ! cmp -s "$TARGET_SAKURA_CONF" "$SAKURA_CONF"; then
#               cp "$TARGET_SAKURA_CONF" "$SAKURA_CONF"
#          else
#               :
#          fi
#       else
#          echo "Не знайдено еталонний файл конфігурації Sakura для режиму '$NEW_MODE': $TARGET_SAKURA_CONF"
#       fi
#   fi
#else
#    :
#fi


# =============== GEANY ============
if command -v geany >/dev/null 2>&1; then
    
    GEANY_CONF="$HOME/.config/geany/geany.conf"
    GEANY_LIGHT="$HOME/.config/geany/geany_light.conf"
    GEANY_DARK="$HOME/.config/geany/geany_dark.conf"
    TARGET_GEANY_CONF=""

    if [[ "$NEW_MODE" == "dark" ]]; then
        TARGET_GEANY_CONF="$GEANY_DARK"
    else
        TARGET_GEANY_CONF="$GEANY_LIGHT"
    fi

    # Проверяем, существует ли целевой файл-источник
    if [[ -f "$TARGET_GEANY_CONF" ]]; then
        # Сравниваем содержимое текущего файла с целевым файлом
        if ! cmp -s "$TARGET_GEANY_CONF" "$GEANY_CONF"; then
            cp "$TARGET_GEANY_CONF" "$GEANY_CONF"
        else
            :
        fi
    else
        echo "Не знайдено еталонний файл конфігурації Geany для режиму '$NEW_MODE': $TARGET_GEANY_CONF"
    fi

else
    :
fi


# =============== DWM ============
# Обновляем файл .lightmode для DWM
if [[ "$NEW_MODE" == "light" ]]; then
    touch "$LIGHTMODE_FILE"
else
    rm -f "$LIGHTMODE_FILE"
fi

# Получаем PID dwm
DWM_PID=$(pgrep -x dwm)

# Отправляем сигнал SIGHUP
if [[ -n "$DWM_PID" ]]; then
    kill -HUP "$DWM_PID"
fi

