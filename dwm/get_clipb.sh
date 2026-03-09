#!/bin/bash

# Получаем содержимое буфера обмена (CLIPBOARD)
DISPLAY=:0 xclip -o -selection clipboard | DISPLAY=:20 xclip -i -selection clipboard


