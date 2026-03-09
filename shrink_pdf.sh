#!/bin/bash

# Налаштування якості (/screen, /ebook, /printer, /prepress)
QUALITY="/ebook"

# Функція для стиснення одного файлу
shrink_file() {
    local f="$1"
    # Перевіряємо, чи це PDF і чи він вже не стиснутий
    if [[ "$f" == *.pdf ]] && [[ "$f" != *_compressed.pdf ]]; then
        dir=$(dirname "$f")
        base=$(basename "$f" .pdf)
        out="$dir/${base}_compressed.pdf"

        echo "Обрабатываю: $f → $out"

        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
           -dPDFSETTINGS=$QUALITY \
           -dNOPAUSE -dQUIET -dBATCH \
           -sOutputFile="$out" "$f"
    fi
}

# ГОЛОВНА ЛОГІКА
if [ -f "$1" ]; then
    # Якщо передано файл — обробляємо тільки його
    shrink_file "$1"
else
    # Якщо передано директорію або нічого не передано
    DIR="${1:-.}"
    echo "Шукаю PDF у директорії: $DIR"
    
    find "$DIR" -type f -name "*.pdf" ! -name "*compressed.pdf" | while read -r f; do
        shrink_file "$f"
    done
fi

echo "✅ Готово."
