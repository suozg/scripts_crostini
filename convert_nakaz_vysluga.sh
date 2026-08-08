#!/bin/bash

# 1. Перевірка, чи передано файл як аргумент
if [ -z "$1" ]; then
    echo "Помилка: Не вказано файл документа!"
    echo "Використання: $0 <файл.docx|.doc|.odt>"
    exit 1
fi

INPUT_FILE="$1"

# Перевірка, чи взагалі існує такий файл
if [ ! -f "$INPUT_FILE" ]; then
    echo "Помилка: Файл '$INPUT_FILE' не знайдено!"
    exit 1
fi

# Перевірка розширення файлу (реєстронезалежна)
EXT="${INPUT_FILE##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

if [[ "$EXT_LOWER" != "docx" && "$EXT_LOWER" != "doc" && "$EXT_LOWER" != "odt" ]]; then
    echo "Помилка: Непідтримуваний формат файлу (очікується .docx, .doc або .odt)!"
    exit 1
fi

echo "=== Крок 1: Конвертація $INPUT_FILE в input.txt за допомогою LibreOffice ==="

# 2. Конвертація у формат .txt засобами LibreOffice
# Працює однаково добре для docx, doc та odt
soffice --headless --convert-to txt "$INPUT_FILE" --outdir .

# Оскільки LibreOffice міняє розширення оригіналу на .txt, обчислюємо назву створеного файлу
GENERATED_TXT="${INPUT_FILE%.*}.txt"

if [ ! -f "$GENERATED_TXT" ]; then
    echo "Помилка: Не вдалося сконвертувати файл за допомогою LibreOffice."
    exit 1
fi

# Перейменовуємо отриманий файл в input.txt для сумісності з обробником
mv "$GENERATED_TXT" "input.txt"
echo "Конвертація успішна! Створено тимчасовий input.txt."
echo "-----------------------------------"

# 3. Налаштування категорій
file_10_15="10_15.txt"
file_15_20="15_20.txt"
file_20_25="20_25.txt"
file_above_25="above_25.txt"

# Очистка файлів результатів
> $file_10_15
> $file_15_20
> $file_20_25
> $file_above_25

echo "=== Крок 2: Обробка тексту та сортування за вислугою ==="

# Читання файлу построчно з виправленням вісімкової системи числення (10#)
while IFS= read -r line; do
    if [[ $line =~ календарна\ –\ ([0-9]+)\ .* ]]; then
        years=${BASH_REMATCH[1]}
        
        if [[ 10#$years -ge 10 && 10#$years -lt 15 ]]; then
            echo "$line" >> $file_10_15
        elif [[ 10#$years -ge 15 && 10#$years -lt 20 ]]; then
            echo "$line" >> $file_15_20
        elif [[ 10#$years -ge 20 && 10#$years -lt 25 ]]; then
            echo "$line" >> $file_20_25
        elif [[ 10#$years -ge 25 ]]; then
            echo "$line" >> $file_above_25
        fi
    fi
done < "input.txt"

# 4. Виведення результатів у консоль
echo "Записи в диапазоне 10-15 лет:"
cat $file_10_15
echo "-----------------------------------"

echo "Записи в диапазоне 15-20 лет:"
cat $file_15_20
echo "-----------------------------------"

echo "Записи в диапазоне 20-25 лет:"
cat $file_20_25
echo "-----------------------------------"

echo "Записи более 25 лет:"
cat $file_above_25
echo "-----------------------------------"

# Очищення тимчасового файлу, щоб не смітити в папці
rm "input.txt"
