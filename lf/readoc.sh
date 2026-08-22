#!/bin/bash

file_path="$1"
[ -f "$file_path" ] || exit 1

ext="${file_path##*.}"
ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

BAT_BIN=$(command -v batcat || command -v bat)

case "$ext" in
    pdf)
        # Спочатку пробуємо витягти текст
        text_content=""
        if command -v pdftotext &>/dev/null; then
            text_content=$(pdftotext -layout "$file_path" - 2>/dev/null | grep -S '[[:alnum:]]')
        fi

        # Якщо в PDF є реальний текст — показуємо його через bat/less
        if [ -n "$text_content" ]; then
            if [ -n "$BAT_BIN" ]; then
                pdftotext -layout "$file_path" - | $BAT_BIN --language=markdown --style=header --paging=always
            else
                pdftotext -layout "$file_path" - | less -R
            fi
        else
            # Якщо тексту немає (це сканована картинка) — рендеримо сторінку через viu або відкриваємо zathura
            if command -v pdftoppm &>/dev/null && command -v viu &>/dev/null; then
                tmp_img="/tmp/lf-readoc-pdf-$$.jpg"
                pdftoppm -f 1 -l 1 -jpeg -singlefile "$file_path" "${tmp_img%.jpg}" 2>/dev/null
                clear
                echo -e "\e[1;33m[PDF / Зображення]\e[0m"
                echo ""
                viu -t "$tmp_img"
                rm -f "$tmp_img"
                echo ""
                read -p "Натисніть Enter для повернення..." _
            elif command -v zathura &>/dev/null; then
                zathura "$file_path" >/dev/null 2>&1 &
            fi
        fi
        ;;

    # doc|docx|xls|xlsx|rtf|odt)
    #     read_file() {
    #         case "$ext" in
    #             doc|docx) docx2txt < "$1" - 2>/dev/null || pandoc "$1" -t markdown 2>/dev/null ;;
    #             xls|xlsx) xlsx2csv "$1" 2>/dev/null || xls2csv "$1" 2>/dev/null ;;
    #             rtf)      unrtf --text "$1" 2>/dev/null || pandoc "$1" -t markdown 2>/dev/null ;;
    #             odt)      odt2txt "$1" 2>/dev/null || pandoc "$1" -t markdown 2>/dev/null ;;
    #         esac
    #     }
    #     if [ -n "$BAT_BIN" ]; then
    #         read_file "$file_path" | $BAT_BIN --language=markdown --style=header --paging=always
    #     else
    #         read_file "$file_path" | less -R
    #     fi
    #     ;;
    doc|docx|rtf|odt)
        read_file() {
            case "$ext" in
                doc|docx) docx2txt < "$1" - 2>/dev/null || pandoc "$1" -t markdown 2>/dev/null ;;
                rtf)      unrtf --text "$1" 2>/dev/null || pandoc "$1" -t markdown 2>/dev/null ;;
                odt)      odt2txt "$1" 2>/dev/null || pandoc "$1" -t markdown 2>/dev/null ;;
            esac
        }

        if [ -n "$BAT_BIN" ]; then
            read_file "$file_path" | $BAT_BIN --language=markdown --style=header --paging=always
        else
            read_file "$file_path" | less -R
        fi
        ;;

    xls|xlsx|ods|csv|tsv)
        vd "$file_path"
        ;;
    *)
        if [ -n "$BAT_BIN" ]; then
            $BAT_BIN --style=header --paging=always "$file_path"
        else
            less -R "$file_path"
        fi
        ;;
esac
