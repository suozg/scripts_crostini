#!/bin/bash

echo "=== Проверка процессов (топ-20 по памяти) ==="
ps aux --sort=-%mem | head -n 20
echo

echo "=== Слушающие порты (TCP/UDP) ==="
sudo ss -tulnp
echo

echo "=== Потенциально подозрительные процессы ==="
ps aux | grep -E 'meterpreter|msfconsole|nc|netcat|bash -i|python -m http.server'
echo

echo "=== Исполняемые файлы в домашней директории ==="
find ~/ -type f -perm /111 -exec ls -lh {} \;
echo

echo "=== Исполняемые файлы в /usr/local/bin ==="
sudo find /usr/local/bin -type f -perm /111 -exec ls -lh {} \;
echo

echo "=== Автозагрузка пользователя ==="
ls ~/.config/autostart/ 2>/dev/null

echo "=== Bash и профильные скрипты ==="
ls -lh ~/.bashrc ~/.profile ~/.bash_profile 2>/dev/null
echo

echo "=== Системные сервисы (running) ==="
systemctl list-units --type=service --state=running
echo

echo "=== Активные сетевые соединения (ESTABLISHED) ==="
sudo ss -tunap | grep ESTAB
echo

echo "=== Последние 50 команд пользователя ==="
tail -n 50 ~/.bash_history
echo

echo "=== Скрипты в домашней директории ==="
find ~/ -name '*.sh' -o -name '*.py'
echo

echo "=== Проверка завершена ==="
echo "# Убираем флаг исполнения (только файлы, не каталоги)"
echo "find /home/user/WORK/ -type f -exec chmod -x {} \;"
