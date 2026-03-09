#!/bin/sh

HISTORY_DIR="$HOME/.local/share/dwm-calc"
HISTORY_FILE="$HISTORY_DIR/bc_history"

mkdir -p "$HISTORY_DIR" 2>/dev/null
[ -f "$HISTORY_FILE" ] || touch "$HISTORY_FILE"

SCALE=4
#
LAST_RESULT=$(grep -oP '= \K[0-9.]+$' "$HISTORY_FILE" 2>/dev/null | head -n 1)
[ -z "$LAST_RESULT" ] && LAST_RESULT=""

# 1. Вивід запрошення (додаємо історію та останній результат у prompt)
CALC_INPUT=$(cat "$HISTORY_FILE" 2>/dev/null | dmenu -p "bc ($LAST_RESULT):" -l 10 -i -fn "monospace:size=12")

# 2. Якщо користувач скасував введення, вихід
[ -z "$CALC_INPUT" ] && exit 0

# 3. Обробка та обчислення (витягуємо вираз, навіть якщо обрано історію)
# Якщо обрано елемент історії (містить " = ")
if echo "$CALC_INPUT" | grep -q " = "; then
    EXPRESSION=$(echo "$CALC_INPUT" | awk -F ' = ' '{print $1}')
    $HOME/.local/bin/st -e sh -c 'printf "\033]0;Калькулятор bc (для завершення ввести quit)\007"; bc'
    exit 0
fi
EXPRESSION=$(echo "$CALC_INPUT" | awk -F ' = ' '{print $1}')
RESULT=$(echo "scale=$SCALE; $EXPRESSION" | bc -l 2>/dev/null)

# 4. Обробка результату
if [ -n "$RESULT" ] && [ "$RESULT" != "." ]; then
    CLEAN_RESULT=$(echo "$RESULT" | sed '/\./ s/\(.*\.\)0*$/\1/' | sed 's/\.$//')

    HISTORY_ENTRY="$EXPRESSION = $CLEAN_RESULT"

    { echo "$HISTORY_ENTRY"; cat "$HISTORY_FILE" 2>/dev/null; } | head -n 10 > "$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

    echo "$CLEAN_RESULT" | xsel -i -b &
    
    # Рекурсивний виклик для продовження сесії
    exec "$0"

else
    # Виходимо, якщо невдача
    exit 1
fi
