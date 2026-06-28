#!/bin/bash

# ================================
# Поиск фразы в текстовых, офисных и GPG-файлах
# Пароль GPG вводится один раз
# ================================

# --- 1. ПАРСИНГ АРГУМЕНТОВ ---
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Использование: $0 <фраза> <папка>"
    exit 1
fi

SEARCH_TERM="$1"
SEARCH_DIR="$2"

# --- 2. ВРЕМЕННЫЕ ПАПКИ ---
TEMP_DIR=$(mktemp -d -p /dev/shm 2>/dev/null || mktemp -d)
export GPG_TTY=$(tty)
trap 'rm -rf "$TEMP_DIR"' EXIT

# --- 3. ВЫБОР ИНСТРУМЕНТА ПОИСКА ---
if command -v rg >/dev/null 2>&1; then
    SEARCH_CMD='rg -i -F --color=always'
else
    SEARCH_CMD='grep -a -i -F --color=always'
fi

# --- 4. ВВОД ПАРОЛЯ GPG ОДИН РАЗ ---
GPG_FILES=$(find "$SEARCH_DIR" -type f -iname "*.gpg")
if [ -n "$GPG_FILES" ]; then
    echo -n "🔑 Пароль (або Enter): "
    read -rs GPG_PASSWORD
    echo
fi

# --- 5. СОБОР ВСЕХ ФАЙЛОВ ---
mapfile -d '' FILES < <(
    find -L "$SEARCH_DIR" -type f \( \
        -iname "*.gpg" -o -iname "*.txt" -o -iname "*.csv" -o -iname "*.log" \
        -o -iname "*.doc*" -o -iname "*.xls*" -o -iname "*.odt" -o -iname "*.ods" \
        -o -iname "*.pdf" \
    \) -print0
)

# --- 6. ОБРАБОТКА ФАЙЛОВ ---
for FILE in "${FILES[@]}"; do
    TARGET_FILE="$FILE"
    DECRYPTED_FILE=""

    # --- 6.1 РАСШИФРОВКА GPG ---
    if [[ "$FILE" =~ \.gpg$ ]]; then
        DECRYPTED_FILE="$TEMP_DIR/dec_$(basename "${FILE%.gpg}")"
        if ! printf '%s\n' "$GPG_PASSWORD" | \
            gpg --quiet --batch --yes \
                --pinentry-mode loopback \
                --passphrase-fd 0 \
                --output "$DECRYPTED_FILE" \
                --decrypt "$FILE" 2>/dev/null
        then
            echo "❌ Помилка розшифрування: $FILE"
            continue
        fi
        TARGET_FILE="$DECRYPTED_FILE"
    fi

    # --- 6.2 ПОИСК ---
    MATCHES=""
    EXT="${TARGET_FILE##*.}"

    case "${EXT,,}" in
        txt|csv|log)
            MATCHES=$($SEARCH_CMD "$SEARCH_TERM" "$TARGET_FILE" 2>/dev/null)
            ;;
        pdf)
            if command -v pdftotext >/dev/null 2>&1; then
                MATCHES=$(pdftotext "$TARGET_FILE" - 2>/dev/null | $SEARCH_CMD "$SEARCH_TERM")
            fi
            ;;
        *)
            soffice --headless --convert-to txt:"Text" \
                "$TARGET_FILE" --outdir "$TEMP_DIR" >/dev/null 2>&1
            CONV_FILE="$TEMP_DIR/$(basename "${TARGET_FILE%.*}.txt")"
            if [ -f "$CONV_FILE" ]; then
                MATCHES=$($SEARCH_CMD "$SEARCH_TERM" "$CONV_FILE" 2>/dev/null)
                rm -f "$CONV_FILE"
            fi
            ;;
    esac

    # --- 6.3 ВЫВОД РЕЗУЛЬТАТОВ ---
    if [ -n "$MATCHES" ]; then
        echo
        echo "🔥 Співпадіння: $FILE"
        echo "$MATCHES" | sed 's/^/  ➡️ /'
    fi

    [ -n "$DECRYPTED_FILE" ] && rm -f "$DECRYPTED_FILE"
done

# --- 7. ОЧИСТКА ПАРОЛЯ ---
unset GPG_PASSWORD

echo
echo "✅ Пошук завершений."

