#!/bin/bash

file="$1"
width="$2"
height="$3"

# ------------------ БАЗОВІ ПЕРЕВІРКИ ------------------
[ -r "$file" ] || exit 0
[ -n "$width" ] && [ -n "$height" ] || exit 0

# Заборона віддалених ФС
case "$file" in
    /mnt/*|/media/*)
        echo "Віддалена ФС: перегляд вимкнено."
        exit 0
        ;;
esac

# ------------------ ЛІМІТИ ----------------------
# Ліміт розміру файлу (100 MB для тексту/метаданих)
MAX_SIZE=104857600
file_size=$(stat --format=%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)

if [ -n "$file_size" ] && [ "$file_size" -gt "$MAX_SIZE" ]; then
    echo "Великий файл: перегляд вимкнено."
    exit 0
fi

# очищення tmp
[ $((RANDOM % 20)) -eq 0 ] && find /tmp -name "lf-pdf-*.jpg" -mmin +60 -delete 2>/dev/null &

# ------------------ МЕТАДАНІ ------------------
mime=$(file --mime-type -b "$file")
echo -e "\e[1;32mТип:\e[0m $mime"

if [ -d "$file" ]; then
    echo -e "\e[1;32mПапка:\e[0m містить $(find "$file" -mindepth 1 -maxdepth 1 | wc -l) елементів"
elif [[ "$mime" == text/* ]] || [[ "$mime" == application/json ]]; then
    echo -e "\e[1;32mРядки:\e[0m $(wc -l < "$file")"
elif [[ "$mime" == image/* ]]; then
    if command -v identify >/dev/null 2>&1; then
        dimensions=$(identify -format "%wx%h" "$file" 2>/dev/null)
        echo -e "\e[1;32mРозмір:\e[0m $dimensions px"
    fi
fi

if [ -f "$file" ]; then
    mod_time=$(stat -c '%y' "$file" 2>/dev/null | cut -d. -f1)
    echo -e "\e[1;32mЗмінено:\e[0m $mod_time"
fi

echo -e "\e[1;34m$(printf '%.s─' $(seq 1 "$width"))\e[0m"

# ------------------ КОНТЕНТ ------------------

ext="${file##*.}"
ext="${ext,,}"

content_height=$((height - 5))
[ "$content_height" -gt 0 ] || content_height=10

# Унікальний хеш для цього файлу (залежить від контенту та імені)
STATE_HASH=$(echo "${file}_${file_size}_$(stat -c '%Y' "$file" 2>/dev/null)" | md5sum | awk '{print $1}')

case "$mime" in
    image/*)
        # viu працює дуже швидко, його не треба кешувати
        viu -w "$width" -h "$content_height" -t "$file"
        ;;

    application/pdf)
        # Кешуємо тільки процес конвертації PDF -> JPG
        TMP_PDF="/tmp/lf-pdf-$STATE_HASH.jpg"
        
        if [ ! -f "$TMP_PDF" ]; then
            pdftoppm -f 1 -l 1 -jpeg -singlefile "$file" "${TMP_PDF%.jpg}" 2>/dev/null
        fi
        
        # Відображення вже готового JPG (це миттєво)
        [ -f "$TMP_PDF" ] && viu -w "${width}" -h "${content_height}" -t "$TMP_PDF"
        ;;

    text/*|application/json)
        BAT_BIN=$(command -v batcat || command -v bat)
        if [ -n "$BAT_BIN" ]; then
            $BAT_BIN \
                  --color=always \
                  --style=plain \
                  --paging=never \
                  --terminal-width="$width" \
                  --line-range=1:"$content_height" \
                  "$file"
        else
            head -n "$content_height" "$file"
        fi
        ;;

    *)
        case "$ext" in
            zip|7z|rar|tar|gz|bz2|xz|tbz2|tgz)
                if command -v als >/dev/null 2>&1; then
                    # Використовуємо als для всіх архівів
                    als "$file" 2>/dev/null | head -n "$content_height"
                else
                    # якщо atool не встановлено
                    case "$ext" in
                        rar) 
                            unrar lb "$file" 2>/dev/null | awk '{ printf "%10s  %s\n", "", $0 }'
                            ;;
                        zip|7z)
                            7z l -ba "$file" 2>/dev/null | awk '
                            {
                                printf "%s %s %10s  ", $1, $2, $4
                                for (i=6; i<=NF; i++) printf "%s ", $i
                                print ""
                            }'
                            ;;
                        *) tar -tvf "$file" 2>/dev/null ;;
                    esac
                fi | head -n "$content_height"
                ;;
            docx)
                if command -v docx2txt >/dev/null; then
                    docx2txt "$file" - | awk 'NF' | head -n "$content_height"
                else
                    pandoc -s "$file" -t markua 2>/dev/null | head -n "$content_height"
                fi
                ;;

            odt)
                if command -v odt2txt >/dev/null; then
                    odt2txt "$file" | awk 'NF' | head -n "$content_height"
                else
                    pandoc -s "$file" -t markua 2>/dev/null | head -n "$content_height"
                fi
                ;;

            rtf)
                if command -v catdoc >/dev/null; then
                    catdoc "$file"  2>/dev/null | awk 'NF' | head -n "$content_height"
                else
                    pandoc -s "$file" -t markua 2>/dev/null | head -n "$content_height" 
                fi
                ;;
            doc)
                catdoc "$file" 2>/dev/null | awk 'NF' | head -n "$content_height"
                ;;
            ods)
                if command -v ods2txt >/dev/null; then
                    ods2txt "$file" | awk 'NF' | column -s$'\t' -t | head -n "$content_height"
                else
                    libreoffice --headless --convert-to "csv:Text - txt - csv (StarCalc):44,34,76" "$file" --outdir /tmp
                    column -s, -t /tmp/$(basename "${file%.*}").csv | head -n "$content_height"
                fi
                ;;
            xlsx|xls)
                if command -v xlsx2csv >/dev/null && [[ "$ext" =~ xlsx ]]; then
                    xlsx2csv "$file" | awk 'NF' | head -n "$content_height"
                elif command -v xls2csv >/dev/null && [[ "$ext" =~ xls ]]; then
                    xls2csv "$file" | awk 'NF' | head -n "$content_height"
                fi
                ;;
            iso)
                command -v isoinfo >/dev/null && isoinfo -l -i "$file" | head -n "$content_height"
                ;;
            *) 
                file -b "$file" | fold -s -w "$width" | head -n "$content_height"
                ;;
        esac
        ;;
esac
