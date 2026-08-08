#!/bin/bash
set -e

# Перевірка вхідного файлу
INPUT_FILE="$1"
if [[ -z "$INPUT_FILE" || "${INPUT_FILE##*.}" != "pdf" ]]; then
    echo "Будь ласка, виберіть PDF файл."
    exit 1
fi

BASE_NAME=$(basename "$INPUT_FILE" .pdf)
OUTPUT_FILE="${BASE_NAME}_shrunk.pdf"
TMP_DIR="/tmp/tmp_process_$(date +%s)"

echo "--- Початок обробки: $INPUT_FILE ---"

# 1. Створення тимчасової робочої директорії
mkdir -p "$TMP_DIR/resized"

# 2. Розбиття PDF на зображення (JPEG, якість 80)
echo "Розбиття на зображення..."
pdftoppm -jpeg -jpegopt quality=80 "$INPUT_FILE" "$TMP_DIR/page"

# 3. Зменшення розміру зображень (700px по висоті)
echo "Зменшення зображень..."
find "$TMP_DIR" -maxdepth 1 -type f -name "page-*.jpg" | while read -r img; do
    # Використовуємо -resize x700 (висота 700, ширина пропорційно)
    convert "$img" -resize x700 "$TMP_DIR/resized/$(basename "$img")"
done

# 4. Збирання нового PDF
echo "Збирання PDF..."
# Збираємо файли з папки resized у правильному порядку
img2pdf --pagesize A4 --output "$OUTPUT_FILE" $(ls -1v "$TMP_DIR/resized/"*.jpg)

# 5. Очищення
echo "Очищення тимчасових файлів..."
rm -rf "$TMP_DIR"

echo "--- Готово! Створено: $OUTPUT_FILE ---"
