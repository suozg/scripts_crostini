#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

section() {
    echo
    echo -e "${BLUE}=== $1 ===${NC}"
}

section "Проверка процессов (топ-20 по памяти)"
ps aux --sort=-%mem | head -n 20

section "Слушающие порты (TCP/UDP)"
sudo ss -tulnp

section "Подозрительные процессы"
pgrep -af 'meterpreter|msfconsole|netcat|bash -i|python -m http.server' \
    || echo -e "${GREEN}Ничего не найдено${NC}"

section "Активные соединения"
sudo ss -tunap | grep ESTAB \
    || echo -e "${GREEN}Нет активных ESTABLISHED соединений${NC}"

section "Исполняемые файлы в HOME"
find ~/ -type f -perm /111 -exec ls -lh {} \;

section "Исполняемые файлы в /usr/local/bin"
sudo find /usr/local/bin -type f -perm /111 -exec ls -lh {} \;

section "DWM autostart"
find ~/.local/share/dwm -name "autostart*" 2>/dev/null

section ".xinitrc и .xsession"
ls -lh ~/.xinitrc ~/.xsession 2>/dev/null

section "Автозагрузка X11"
grep -n "exec" ~/.xinitrc ~/.xsession 2>/dev/null

section "Системные сервисы"
systemctl list-units --type=service --state=running

section "Пользовательские сервисы"
systemctl --user list-units --type=service --state=running

section "User systemd units"
find ~/.config/systemd/user -type f 2>/dev/null

section "Таймеры systemd"
systemctl list-timers --all

section "Cron пользователя"
crontab -l 2>/dev/null \
    || echo -e "${GREEN}Cron-задачи отсутствуют${NC}"

section "SSH ключи"
ls -lah ~/.ssh 2>/dev/null \
    || echo -e "${GREEN}Каталог ~/.ssh отсутствует${NC}"

section "Последние команды"
tail -n 50 ~/.bash_history

section "Shell-скрипты"
find ~/ \( -name "*.sh" -o -name "*.py" \)

section "npm пакеты"
command -v npm >/dev/null && npm list -g --depth=0 \
    || echo -e "${YELLOW}npm не установлен${NC}"

section "Конфигурация npm"
if command -v npm >/dev/null; then
    echo "prefix: $(npm config get prefix)"
    echo "cache : $(npm config get cache)"
fi

section "Ручные пакеты Debian"
apt-mark showmanual

section "Недавно изменённые файлы в HOME (7 дней)"
find ~ -type f -mtime -7 2>/dev/null | head -100

section "Проверка завершена"
echo -e "${GREEN}Готово${NC}"

echo
echo -e "${YELLOW}Команда для снятия executable-бита:${NC}"
echo "find ~/WORK/ -type f -exec chmod -x {} \;"

