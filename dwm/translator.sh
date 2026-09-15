#!/bin/sh

text="$(xclip -selection clipboard -o 2>/dev/null)"

[ -z "$text" ] && exit 0

result="$(sdcv -n "$text" 2>/dev/null |
    sed -E '/^-->/d; /^Found/d; /^Dictionary/d; /^[[:space:]]*$/d' |
    grep -i -v "^${text}$" |
    tr -d '""' |
    xargs)"

[ -z "$result" ] && result="Переклад не знайдено"

dunstify -t 10000 "$text" "$result"
