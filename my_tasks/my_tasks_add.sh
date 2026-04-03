#!/usr/bin/env bash
set -euo pipefail

DIARY_DIR="$HOME/awards/vimwiki/diary"
INDEX_FILE="$DIARY_DIR/diary.md"
mkdir -p "$DIARY_DIR"

# 1. Отримуємо дату
date_input=$(printf "" | dmenu -p "Дата (YYYY-MM-DD) або Enter:" -fn "monospace:size=12")
[ -z "$date_input" ] && date_input=$(date +%Y-%m-%d)

FILE="$DIARY_DIR/$date_input.md"
NEW_FILE=false

# 2. Якщо файлу дня ще немає — створюємо його
if [ ! -f "$FILE" ]; then
    echo "# $date_input" > "$FILE"
    NEW_FILE=true
fi

# 3. Отримуємо дані завдання
time_input=$(printf "" | dmenu -p "Час (HH:MM):" -fn "monospace:size=12")
[ -z "$time_input" ] && exit 0
text_input=$(printf "" | dmenu -p "Задача:" -fn "monospace:size=12")
[ -z "$text_input" ] && exit 0

# 4. Записуємо задачу
echo "- $time_input $text_input" >> "$FILE"

# 5. ОНОВЛЕННЯ diary.md (Індексу)
if [ "$NEW_FILE" = true ] || [ ! -f "$INDEX_FILE" ]; then
    [ -f "$INDEX_FILE" ] || echo "# Diary" > "$INDEX_FILE"

    # 1. Тимчасовий файл для чистого списку
    tmp_index=$(mktemp)
    
    # 2. Записуємо "шапку"
    echo "# Diary" > "$tmp_index"
    echo "" >> "$tmp_index"
    
    # 3. Додаємо нову дату до поточного файлу, щоб вона теж потрапила в обробку
    echo "$date_input" >> "$INDEX_FILE"

    # 4. ОЧИЩЕННЯ ТА СОРТУВАННЯ:
    # - Витягуємо ТІЛЬКИ цифри дати (ігноруємо дужки, зірочки, сміття)
    # - Сортуємо у зворотному порядку, видаляємо дублікати
    # - Формуємо чистий рядок: * [[YYYY-MM-DD]]
    grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" "$INDEX_FILE" | \
    sort -ur | \
    while read -r d; do
        echo "* [[$d]]" >> "$tmp_index"
    done

    # 5. Замінюємо старий "брудний" файл новим і чистим
    mv "$tmp_index" "$INDEX_FILE"
fi

# 6. Фіналізація
pkill -RTMIN+10 dwmblocks || true
dunstify -u low "Vimwiki" "Запис додано в $date_input та оновлено індекс."

