#!/usr/bin/env bash

# Кольори з вашого config.h
COL_GRAY1="#222222"
COL_GRAY3="#bbbbbb"
COL_GRAY4="#eeeeee"
COL_CYAN="#005577"
FONT="monospace:size=12"

# Перевірка теми 
if [[ -f "$HOME/.lightmode" ]]; then
    # Світла тема
    export CM_LAUNCHER=dmenu
    clipmenu -i -fn "$FONT" -nb "$COL_GRAY3" -nf "$COL_GRAY1" -sb "$COL_CYAN" -sf "$COL_GRAY4"
else
    # Темна тема
    export CM_LAUNCHER=dmenu
    clipmenu -i -fn "$FONT"
fi
