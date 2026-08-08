#!/bin/bash

# Шляхи з вашого конфігу
NVIM_CONFIG="$HOME/.config/nvim"
NVIM_PLUGINS="$HOME/.local/share/nvim/plugged"
NVIM_DATA="$HOME/.local/share/nvim"
PYTHON_VENV="/home/alex320388/venv"

echo "=== Аналіз займаного місця Neovim (v0.7.2) ==="
echo "-----------------------------------------------"

# Функція для вимірювання (якщо шлях існує)
check_size() {
    if [ -d "$1" ] || [ -f "$1" ]; then
        du -sh "$1"
    else
        echo "Шлях не знайдено: $1"
    fi
}

echo "1. Конфігурація та шаблони:"
check_size "$NVIM_CONFIG"

echo -e "\n2. Плагіни (vim-plug):"
check_size "$NVIM_PLUGINS"

echo -e "\n3. Python venv (з pyright та іншим):"
check_size "$PYTHON_VENV"

echo -e "\n4. Системні утиліти (використовуються в скрипті):"
for tool in pandoc zathura nvim; do
    tool_path=$(which $tool)
    if [ ! -z "$tool_path" ]; then
        size=$(du -sh $(realpath $tool_path) | cut -f1)
        echo "$size	$tool_path"
    fi
done

# Окремий пошук для weasyprint
WP_PATH=$(which weasyprint)
if [ -z "$WP_PATH" ]; then
    # Перевіряємо у вашому venv
    if [ -f "/home/alex320388/venv/bin/weasyprint" ]; then
        WP_PATH="/home/alex320388/venv/bin/weasyprint"
    fi
fi

if [ ! -z "$WP_PATH" ]; then
    size=$(du -sh $(realpath $WP_PATH) | cut -f1)
    echo "$size	$WP_PATH (WeasyPrint)"
else
    echo "WeasyPrint не знайдено через 'which'. Спробуйте: pip show weasyprint"
fi
echo -e "\n5. Загальні дані Neovim (кеш, undo, shada):"
check_size "$NVIM_DATA"

echo "-----------------------------------------------"
echo "Порада: найбільше місця зазвичай займає $PYTHON_VENV через LSP сервери."
