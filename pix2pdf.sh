#!/bin/bash
echo "# Скрипт для конвертації зображень у PDF з опціональним накладанням штампа."
echo "# Використання:"
echo "#   ./pix_2_pdf_universal.sh"
echo "#   ./pix_2_pdf_universal.sh -s /шлях/до/водяного_знаку.pdf"

set -euo pipefail # <<< ДОДАНО ДЛЯ ПІДВИЩЕННЯ НАДІЙНОСТІ

# --- НАЛАШТУВАННЯ ---
IMAGE_MASKS=(*.jpg *.jpeg *.JPG *.JPEG *.png *.PNG)
OUTPUT_FILE="final_document.pdf"
STAMP_FILE=""  # Залишається порожнім, якщо не передано опцію -s

# Параметри для режиму зі штампом
CUSTOM_PAGE_SIZE="595x992pt"             # A4 + ~150pt знизу
Y_SHIFT_FOR_ALIGNMENT="0 75"             # Зсув вмісту сторінок угору
TEMP_BASE_PDF="/tmp/base_doc_$$.pdf"     # Проміжний PDF з запасом
TEMP_SHIFTED_PDF="/tmp/shifted_doc_$$.pdf" # Проміжний PDF зі зсунутим вмістом

# --- ФУНКЦІЯ ОЧИЩЕННЯ ---
cleanup() {
    # Використовуємо -f, щоб не викликати помилку, якщо файл вже видалено,
    # і не завершувати скрипт через 'set -e'
    if [ -n "$STAMP_FILE" ]; then
        echo "Очищення тимчасових файлів..."
        rm -f "$TEMP_BASE_PDF" "$TEMP_SHIFTED_PDF" || true
    fi
}
# Викликати cleanup при будь-якому виході
trap cleanup EXIT

# --- ОБРОБКА АРГУМЕНТІВ КОМАНДНОГО РЯДКА ---
while getopts "s:" opt; do
    case ${opt} in
        s )
            STAMP_FILE=$OPTARG
            ;;
        \? )
            echo "Використання: $0 [-s /шлях/до/штампа.pdf]"
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# --- ПЕРЕВІРКА ЗАЛЕЖНОСТЕЙ ---
echo "Перевірка залежностей..."
if ! command -v img2pdf &> /dev/null; then
    echo "Помилка: Програма 'img2pdf' не знайдена."
    exit 1
fi

if [ -n "$STAMP_FILE" ]; then
    if ! command -v cpdf &> /dev/null; then
        echo "Помилка: Режим зі штампом вимагає 'cpdf'. Програма не знайдена."
        exit 1
    fi
    if [ ! -f "$STAMP_FILE" ]; then
        echo "Помилка: Файл штампа '$STAMP_FILE' не знайдено."
        exit 1
    fi
    OUTPUT_FILE="stamped_document.pdf" # Змінюємо ім'я для режиму зі штампом
fi

# --- ЗБІР ФАЙЛІВ ЗОБРАЖЕНЬ ---
FILES_TO_CONVERT=()
for mask in "${IMAGE_MASKS[@]}"; do
    # Обробка випадків, коли маска не знаходить файлів (інакше set -u може викликати помилку)
    shopt -s nullglob # Включаємо nullglob, щоб маски, які не знайшли файлів, розширювалися до порожнього списку
    for file in $mask; do
        if [ -f "$file" ]; then
            FILES_TO_CONVERT+=("$file")
        fi
    done
    shopt -u nullglob # Вимикаємо nullglob
done


if [ ${#FILES_TO_CONVERT[@]} -eq 0 ]; then
    echo "Помилка: Не знайдено файлів зображень для конвертації."
    exit 1
fi

# --- ВИКОНАННЯ КОНВЕРТАЦІЇ ---

if [ -z "$STAMP_FILE" ]; then
    ## РЕЖИМ 1: ЗВИЧАЙНА КОНВЕРТАЦІЯ (img2pdf A4)
    echo "Запуск: Звичайна конвертація зображень у A4 PDF ($OUTPUT_FILE)..."
    
    img2pdf \
        --pagesize A4 \
        --output "$OUTPUT_FILE" \
        "${FILES_TO_CONVERT[@]}"

    echo "✅ Готово! Файл $OUTPUT_FILE успішно створено."
    
else
    ## РЕЖИМ 2: КОНВЕРТАЦІЯ ЗІ ШТАМПОМ (img2pdf + cpdf)
    echo "Запуск: Конвертація із застосуванням штампа '$STAMP_FILE' у $OUTPUT_FILE..."
    
    # КРОК 1: КОНВЕРТАЦІЯ ТА СТВОРЕННЯ ЗАПАСУ
    echo "1/3: Конвертація зображень та створення нижнього поля..."
    img2pdf --pagesize "$CUSTOM_PAGE_SIZE" \
            --output "$TEMP_BASE_PDF" \
            "${FILES_TO_CONVERT[@]}"

    # КРОК 2: ЗСУВ ВМІСТУ ВГОРУ
    echo "2/3: Зсув вмісту сторінок угору на 75pt..."
    cpdf -shift "$Y_SHIFT_FOR_ALIGNMENT" "$TEMP_BASE_PDF" -o "$TEMP_SHIFTED_PDF"

    # КРОК 3: НАКЛАДАННЯ ШТАМПА
    echo "3/3: Накладання штампа '$STAMP_FILE' на нижній центр..."
    cpdf -stamp-on "$STAMP_FILE" "$TEMP_SHIFTED_PDF" -o "$OUTPUT_FILE"

    echo "✅ Успіх! Фінальний документ з колонтитулом: $OUTPUT_FILE"

fi

# 'trap cleanup EXIT' забезпечить видалення тимчасових файлів після завершення.
