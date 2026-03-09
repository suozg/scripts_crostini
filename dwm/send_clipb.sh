#!/bin/bash

# Получаем содержимое буфера обмена (CLIPBOARD)
DISPLAY=:20 xclip -o -selection clipboard | DISPLAY=:0 xclip -i -selection clipboard


