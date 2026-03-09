#!/bin/bash
# переключение раскладки клавиатури
current_layout=$(setxkbmap -query | grep layout | awk '{print $2}')

if [[ "$current_layout" == "ua" ]]; then
    layouts="us"
else
    layouts="ua"
fi

setxkbmap "$layouts"
