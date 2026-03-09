#!/bin/bash

# 1. Показуємо dmenu з інструкцією
# Ми використовуємо "echo", щоб dmenu відкрилося і чекало, поки ви натиснете Enter або просто бачили текст
echo "Клікніть на екрані для отримання кольору..." | dmenu -p "Піпетка:" -fn "monospace:size=12" &
DMENU_PID=$!

# 2. Запускаємо піпетку
COLOR=$(python3 ~/.local/bin/dwm/select_color.py)

# 3. Закриваємо dmenu (якщо воно ще висить) і показуємо результат
kill $DMENU_PID 2>/dev/null
if [ ! -z "$COLOR" ]; then
   printf "%s" "$COLOR" | xclip -selection clipboard 
   echo "$COLOR" | dmenu -p "Обраний колір [скопійовано]:" -nb "$COLOR" -nf "#005577" -fn "monospace:size=12"
fi
