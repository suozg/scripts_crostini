#!/bin/bash

# Функція для читання документів Word (.docx)
read_word() {
    file="$1"
    if command -v docx2txt &>/dev/null; then
        docx2txt < "$file" -
    else
        echo "Не знайдено інструментів для обробки Word документів"
    fi
}

# Функція для читання Excel файлів (.xlsx)
read_excel() {
    file="$1"
    if command -v xlsx2csv &>/dev/null; then
        xlsx2csv "$file"
    else
        echo "Не знайдено інструментів для обробки Excel файлів"
    fi
}

# Функція для читання RTF файлів
read_rtf() {
    file="$1"
    if command -v unrtf &>/dev/null; then
        unrtf "$file"
    elif command -v pandoc &>/dev/null; then
        pandoc "$file" -t plain
    else
        echo "Не знайдено інструментів для обробки RTF файлів"
    fi
}

# Функція для читання ODT файлів
read_odt() {
    file="$1"
    if command -v pandoc &>/dev/null; then
        pandoc "$file" -t plain
    else
        echo "Не знайдено інструментів для обробки ODT файлів"
    fi
}

# Основна функція для визначення типу файлу
read_file() {
    file="$1"
    ext="${file##*.}"

    case "$ext" in
        doc|docx)
            read_word "$file"
            ;;
        xls|xlsx)
            read_excel "$file"
            ;;
        rtf)
            read_rtf "$file"
            ;;
        odt)
            read_odt "$file"
            ;;
        *)
            echo "Невідомий формат файлу: $ext"
            ;;
    esac
}

# Основна логіка
file_path="$1"
if [ -f "$file_path" ]; then
    content=$(read_file "$file_path")
    if [ -n "$content" ]; then
        echo "$content" | micro
    else
        echo "Не вдалося отримати вміст файлу."
    fi
else
    echo "Файл не знайдено!"
fi
