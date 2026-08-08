#!/bin/bash
# === Автоматическая проверка подключённой флешки ===
# Использование: sudo ./check_usb_auto.sh

echo "=== Поиск USB-накопителей ==="

# Находим USB-устройства по имени и типу
USB_DEV=$(lsblk -dpno NAME,TRAN | grep usb | awk '{print $1}' | head -n1)

if [ -z "$USB_DEV" ]; then
    echo "Флешка не найдена. Вставьте устройство и повторите."
    exit 1
fi

echo "Обнаружено устройство: $USB_DEV"
PART="${USB_DEV}1"

# Проверка логов ядра
echo
echo "--- Последние сообщения ядра ---"
dmesg | tail -n 30 | grep -i "$(basename "$USB_DEV")" || echo "Ошибок не найдено."

# Проверка файловой системы
if [ -b "$PART" ]; then
    echo
    echo "--- Проверка файловой системы ---"
    sudo umount "$PART" 2>/dev/null
    sudo fsck -v "$PART"
else
    echo
    echo "Раздел $PART не найден. Пропускаю fsck."
fi

# Проверка физических ошибок
echo
echo "--- Проверка на битые блоки (занимает время) ---"
sudo badblocks -sv "$USB_DEV"

echo
echo "=== Проверка завершена ==="

