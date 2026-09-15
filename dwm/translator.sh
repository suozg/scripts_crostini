#!/bin/sh
# перекладач з англійської на укранську і навпаки

text="$(xclip -selection clipboard -o 2>/dev/null)"

[ -z "$text" ] && exit 0

# Перевіряємо наявність кириличних літер
if echo "$text" | grep -q -P '[а-щА-ЩЬьЮюЯяЇїІіЄєҐґ]'; then
    # Назва UK -> EN словника (дізнатися точно можна через `sdcv -l`)
    DICT_NAME="dictd_www.mova.org_slovnyk_uk-en"
else
    # Назва EN -> UK словника
    DICT_NAME="slovnyk_en-uk"
fi

# Пошук у конкретному словнику
result="$(sdcv -u "$DICT_NAME" -n "$text" 2>/dev/null |
    sed -E '/^-->/d; /^Found/d; /^Dictionary/d; /^[[:space:]]*$/d' |
    grep -i -v "^${text}$" |
    tr -d '""' |
    xargs)"

[ -z "$result" ] && result="Переклад не знайдено"

dunstify -t 10000 "$text" "$result"
