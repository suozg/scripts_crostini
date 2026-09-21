#!/usr/bin/env bash

file="$1"
width="$2"
height="$3"

# ------------------ БАЗОВЫЕ ПРОВЕРКИ ------------------
[ -r "$file" ] || exit 0
[ -n "$width" ] && [ -n "$height" ] || exit 0

case "$file" in
    /mnt/*|/media/*)
        echo "Удаленная ФС: просмотр отключен."
        exit 0
        ;;
esac

MAX_SIZE=104857600 # 100MB

# ------------------ ИНИЦИАЛИЗАЦИЯ ------------------
if STAT_OUT=$(stat -c "%s %Y %y|%w" "$file" 2>/dev/null); then
    file_size="${STAT_OUT%% *}"
    REST="${STAT_OUT#* }"
    mtime_epoch="${REST%% *}"
    REST="${REST#* }"
    mod_time="${REST%%|*}"
    birth_time="${REST#*|}"
else
    echo "Не удалось получить метаданные файла."
    exit 0
fi

if [ -n "$file_size" ] && [ "$file_size" -gt "$MAX_SIZE" ]; then
    echo "Большой файл ($(numfmt --to=iec-i --suffix=B "$file_size" 2>/dev/null || echo "$file_size bytes")): просмотр отключен."
    exit 0
fi

# Кэш
CACHE_DIR="/tmp/lf_preview_cache"
mkdir -p "$CACHE_DIR"
[ $((RANDOM % 30)) -eq 0 ] && find "$CACHE_DIR" -type f -mmin +120 -delete 2>/dev/null &

# Расширение и хеш
real_file=$(readlink -f "$file" 2>/dev/null || echo "$file")
ext="${real_file##*.}"
ext="${ext,,}"
STATE_HASH=$(echo -n "${real_file}_${file_size}_${mtime_epoch}" | md5sum | awk '{print $1}')

# MIME-тип
mime=$(file --mime-type -b "$file" 2>/dev/null || echo "application/octet-stream")

# Глобальные переменные высоты и окружения
content_height=$((height - 10))
[ "$content_height" -gt 0 ] || content_height=10
BAT_BIN=$(command -v batcat || command -v bat)

# Буфер для Office файлов (чтобы не вызывать unzip повторно)
zip_structure=""

# ------------------ ВЫВОД МЕТАДАННЫХ ------------------
echo -e "\e[1;32mТип:\e[0m $mime"

if [ -d "$file" ]; then
    echo -e "\e[1;32mПапка:\e[0m содержит $(find "$file" -mindepth 1 -maxdepth 1 | wc -l) элементов"
elif [[ "$mime" == text/* || "$mime" == application/json || "$mime" == application/xml ]]; then
    echo -e "\e[1;32mСтрок:\e[0m $(wc -l < "$file")"
elif [[ "$mime" == image/* ]]; then
    if command -v identify >/dev/null 2>&1; then
        dimensions=$(identify -format "%wx%h" "$file" 2>/dev/null)
        [ -n "$dimensions" ] && echo -e "\e[1;32mРазмер:\e[0m $dimensions px"
    fi
fi

if [ -f "$file" ]; then
    mod_time_short="${mod_time%.*}"
    birth_time_short="${birth_time%.*}"
    if [[ "$birth_time_short" == "-" || -z "$birth_time_short" ]]; then
        birth_time_short="недоступно"
    fi
    echo -e "\e[1;32mИзменение:\e[0m     $mod_time_short"
    echo -e "\e[1;32mСоздание:\e[0m      $birth_time_short"
fi

# Метаданные Office
office_exts=" docx xlsx ods odt "
if [[ "$office_exts" =~ " $ext " ]]; then
    author=""
    modifier=""
    zip_structure=$(unzip -Z1 "$file" 2>/dev/null)

    case "$ext" in
        docx|xlsx)
            if echo "$zip_structure" | grep -q "docProps/core.xml"; then
                xml_data=$(unzip -p "$file" docProps/core.xml 2>/dev/null)
                author=$(echo "$xml_data" | sed -n 's/.*<dc:creator>\([^<]*\)<\/dc:creator>.*/\1/p')
                modifier=$(echo "$xml_data" | sed -n 's/.*<cp:lastModifiedBy>\([^<]*\)<\/cp:lastModifiedBy>.*/\1/p')
            fi
            ;;
        odt|ods)
            if echo "$zip_structure" | grep -q "meta.xml"; then
                xml_data=$(unzip -p "$file" meta.xml 2>/dev/null)
# Спочатку шукаємо початкового творця, якщо немає — звичайного dc:creator
                author=$(echo "$xml_data" | sed -n 's/.*<meta:initial-creator>\([^<]*\)<\/meta:initial-creator>.*/\1/p')
                [ -z "$author" ] && author=$(echo "$xml_data" | sed -n 's/.*<dc:creator>\([^<]*\)<\/dc:creator>.*/\1/p')
            fi
            ;;
    esac

    [ -n "$author" ] && echo -e "\e[1;32mАвтор:\e[0m         $author"
    [ -n "$modifier" ] && echo -e "\e[1;32mИзменил:\e[0m       $modifier"
fi

echo -e "\e[1;34m$(printf '%.s─' $(seq 1 "$width"))\e[0m"

# ------------------ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ВЫВОДА ------------------
draw_image() {
    local img_path="$1"
    local max_h="${2:-$content_height}"
    if [ -n "$NVIM" ]; then
        chafa --format=symbols -s "${width}x${max_h}" "$img_path"
    else
        chafa --format=sixels -s "${width}x${max_h}" "$img_path" 2>/dev/null || chafa -s "${width}x${max_h}" "$img_path"
    fi
}

draw_text() {
    if [ -n "$BAT_BIN" ]; then
        $BAT_BIN --color=always --style=plain --paging=never --terminal-width="$width" --line-range=1:"$content_height" "$@"
    else
        head -n "$content_height" "$1"
    fi
}

# ------------------ ОСНОВНЫЕ ФУНКЦИИ ПРЕВЬЮ ------------------

preview_image() {
    draw_image "$file"
}

preview_svg() {
    TMP_SVG_PNG="$CACHE_DIR/svg-$STATE_HASH.png"
    if [ ! -f "$TMP_SVG_PNG" ]; then
        if command -v rsvg-convert >/dev/null 2>&1; then
            rsvg-convert "$file" -o "$TMP_SVG_PNG" 2>/dev/null
        elif command -v inkscape >/dev/null 2>&1; then
            inkscape "$file" -o "$TMP_SVG_PNG" 2>/dev/null
        elif command -v magick >/dev/null 2>&1; then
            magick "$file" "$TMP_SVG_PNG" 2>/dev/null
        fi
    fi

    if [ -s "$TMP_SVG_PNG" ]; then
        draw_image "$TMP_SVG_PNG"
    else
        draw_text "$file"
    fi
}

preview_pdf() {
    TMP_PDF="$CACHE_DIR/pdf-$STATE_HASH.jpg"

    if [ ! -f "$TMP_PDF" ]; then
        pdftoppm -f 1 -l 1 -jpeg -singlefile \
            "$file" "${TMP_PDF%.jpg}" 2>/dev/null
    fi

    if [ -s "$TMP_PDF" ]; then
        draw_image "$TMP_PDF"
    else
        echo "Не удалось отобразить PDF."
    fi
}

preview_mail() {
    echo -e "\e[1;33m=== ЭЛЕКТРОННОЕ ПИСЬМО ===\e[0m"
    awk '
        BEGIN { RS="\r?\n\r?\n"; body=0 }
        NR==1 {
            split($0, lines, "\n")
            for (i in lines) {
                if (lines[i] ~ /^From:/) print "\033[1;32mОт:\033[0m " substr(lines[i], 6)
                if (lines[i] ~ /^To:/) print "\033[1;32mКому:\033[0m " substr(lines[i], 4)
                if (lines[i] ~ /^Date:/) print "\033[1;32mДата:\033[0m " substr(lines[i], 6)
                if (lines[i] ~ /^Subject:/) print "\033[1;33mТема:\033[0m " substr(lines[i], 9)
            }
            print "\033[1;34m----------------------------------------\033[0m"
            next
        }
        { print $0; exit }
    ' "$file" | head -n "$content_height"
}

preview_markdown() {
    if command -v glow >/dev/null 2>&1; then
        glow -s dark -w "$width" "$file" | head -n "$content_height"
    elif command -v mdcat >/dev/null 2>&1; then
        mdcat --columns "$width" "$file" | head -n "$content_height"
    else
        draw_text "$file"
    fi
}

preview_json() {
    if command -v jq >/dev/null 2>&1; then
        jq -C . "$file" 2>/dev/null | head -n "$content_height"
    else
        draw_text "$file"
    fi
}

preview_csv() {
    if command -v tv >/dev/null 2>&1; then
        tv "$file" | head -n "$content_height"
    elif command -v column >/dev/null 2>&1; then
        if [[ "$mime" == "text/tab-separated-values" ]]; then
            column -s $'\t' -t "$file" 2>/dev/null | head -n "$content_height"
        else
            column -s',' -t "$file" 2>/dev/null | head -n "$content_height"
        fi
    else
        draw_text "$file"
    fi
}

preview_html() {
    if command -v w3m >/dev/null 2>&1; then
        w3m -dump -cols "$width" "$file" | head -n "$content_height"
    elif command -v lynx >/dev/null 2>&1; then
        lynx -dump -width="$width" "$file" | head -n "$content_height"
    else
        draw_text "$file"
    fi
}

preview_text() {
    draw_text "$file"
}

preview_archive() {
    if command -v 7z >/dev/null 2>&1; then
        7z l -ba "$file" 2>/dev/null | awk '{
            printf "%s %s %10s  ", $1, $2, $4
            for (i=6; i<=NF; i++) printf "%s ", $i
            print ""
        }' | head -n "$content_height"
    elif command -v bsdtar >/dev/null 2>&1; then
        bsdtar -tf "$file" 2>/dev/null | head -n "$content_height"
    elif command -v tar >/dev/null 2>&1; then
        tar -tf "$file" 2>/dev/null | head -n "$content_height"
    fi
}


preview_office() {
    case "$ext" in
        docx)
            text_content=""
            if command -v docx2txt >/dev/null 2>&1; then
                text_content=$(docx2txt "$file" - 2>/dev/null | grep '[^[:space:]]')
            elif command -v pandoc >/dev/null 2>&1; then
                text_content=$(pandoc -f docx -t plain "$file" 2>/dev/null | grep '[^[:space:]]')
            fi

            img_inside=$(echo "$zip_structure" | grep -iE '^word/media/' | head -n 1)

            if [ -n "$img_inside" ]; then
                TMP_IMG="$CACHE_DIR/docx-$STATE_HASH.jpg"
                [ ! -f "$TMP_IMG" ] && unzip -p "$file" "$img_inside" > "$TMP_IMG" 2>/dev/null

                # Показываем изображение, выделяя под него примерно 35-40% доступной высоты
                img_height=$((content_height * 38 / 100))
                [ "$img_height" -lt 5 ] && img_height=5
                
                # Оставшуюся высоту отдаем под полный текст
                text_lines=$((content_height - img_height - 1))
                [ "$text_lines" -lt 3 ] && text_lines=3

                if [ -n "$text_content" ]; then
                    echo "$text_content" | head -n "$text_lines"
                    echo -e "\e[1;30m---\e[0m"
                fi

                if [ -s "$TMP_IMG" ]; then
                    draw_image "$TMP_IMG" "$img_height"
                fi
            else
                [ -n "$text_content" ] && echo "$text_content" | head -n "$content_height" || echo "Документ не содержит текста."
            fi
            ;;

        odt)
            text_content=""
            if command -v odt2txt >/dev/null 2>&1; then
                text_content=$(odt2txt "$file" 2>/dev/null | awk 'NF')
            elif command -v pandoc >/dev/null 2>&1; then
                text_content=$(pandoc -s "$file" -t plain 2>/dev/null | awk 'NF')
            fi

            img_inside=$(echo "$zip_structure" | grep -iE '^Pictures/' | head -n 1)

            if [ -n "$img_inside" ]; then
                TMP_IMG="$CACHE_DIR/odt-$STATE_HASH.jpg"
                [ ! -f "$TMP_IMG" ] && unzip -p "$file" "$img_inside" > "$TMP_IMG" 2>/dev/null

                img_height=$((content_height * 38 / 100))
                [ "$img_height" -lt 5 ] && img_height=5

                text_lines=$((content_height - img_height - 1))
                [ "$text_lines" -lt 3 ] && text_lines=3

                if [ -n "$text_content" ]; then
                    echo "$text_content" | head -n "$text_lines"
                    echo -e "\e[1;30m---\e[0m"
                fi

                if [ -s "$TMP_IMG" ]; then
                    draw_image "$TMP_IMG" "$img_height"
                fi
            else
                [ -n "$text_content" ] && echo "$text_content" | head -n "$content_height" || echo "Документ не содержит текста."
            fi
            ;;

        xlsx|xls)
            if command -v xlsx2csv >/dev/null 2>&1 && [[ "$ext" == "xlsx" ]]; then
                xlsx2csv "$file" 2>/dev/null | column -s',' -t | head -n "$content_height"
            elif command -v xls2csv >/dev/null 2>&1 && [[ "$ext" == "xls" ]]; then
                xls2csv "$file" 2>/dev/null | column -s',' -t | head -n "$content_height"
            fi
            ;;

        ods)
            if command -v ods2txt >/dev/null 2>&1; then
                ods2txt "$file" | awk 'NF' | column -s$'\t' -t | head -n "$content_height"
            fi
            ;;

        rtf|doc)
            if command -v catdoc >/dev/null 2>&1; then
                catdoc "$file" 2>/dev/null | awk 'NF' | head -n "$content_height"
            else
                pandoc -s "$file" -t plain 2>/dev/null | head -n "$content_height"
            fi
            ;;
    esac
}


preview_by_extension() {
    case "$ext" in
        md|markdown)                         preview_markdown ;;
        eml)                                 preview_mail ;;
        csv)                                 preview_csv ;;
        docx|odt|xlsx|xls|ods|rtf|doc)       preview_office ;;
        zip|7z|rar|tar|gz|bz2|xz|tbz2|tgz|iso|cab|deb|rpm) preview_archive ;;
        *)
            file -b "$file" | fold -s -w "$width" | head -n "$content_height"
            ;;
    esac
}

# ------------------ ОСНОВНОЙ БЛОК МАРШРУТИЗАЦИИ ------------------
case "$mime" in
    image/svg+xml)                       preview_svg ;;
    image/*)                             preview_image ;;
    application/pdf)                     preview_pdf ;;
    message/rfc822|text/x-mail)          preview_mail ;;
    text/markdown|text/x-markdown)       preview_markdown ;;
    application/json|text/json)          preview_json ;;
    text/csv|text/tab-separated-values)  preview_csv ;;
    text/html)                           preview_html ;;
    text/*|application/x-sh|application/javascript) preview_text ;;
    *)
        preview_by_extension
        ;;
esac
