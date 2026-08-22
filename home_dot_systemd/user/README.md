systemctl --user daemon-reload
systemctl --user start myscript.service


--- вставить в .bashrc
# ---------------------------------------------------------------
# Функція для швидкого створення systemd таймера
# Використання: sys-timer "назва" "години,хвилини" "/шлях/до/скрипта.sh"
# Приклад: sys-timer myscript "07:00,19:00" "$HOME/script.sh"
# ---------------------------------------------------------------
sys-timer() {
    if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" || -z "$2" || -z "$3" ]]; then
        echo "Використання: sys-timer <назва> <години> <шлях_до_скрипта>"
        echo "Приклад:     sys-timer myscript \"07:00,19:00\" \"$HOME/script.sh\""
        echo ""
        echo "Параметри:"
        echo "  назва         Унікальне ім'я для сервісу та таймера"
        echo "  години        Час запуску у форматі ЧЧ:ММ (можна кілька через кому)"
        echo "  шлях          Абсолютний шлях до виконуваного скрипта"
        return 0
    fi

    local name="$1"
    local times="$2"
    local script_path="$3"
    local dir="$HOME/.config/systemd/user"

    mkdir -p "$dir"

    # Створюємо service файл
    cat << EOF > "$dir/$name.service"
[Unit]
Description=Timer script $name

[Service]
Type=oneshot
ExecStart=$script_path
EOF

    # Генеруємо OnCalendar рядки
    local calendar_lines=""
    IFS=',' read -ra ADDR <<< "$times"
    for t in "${ADDR[@]}"; do
        calendar_lines+="OnCalendar=*-*-* $t:00"$'\n'
    done

    # Створюємо timer файл
    cat << EOF > "$dir/$name.timer"
[Unit]
Description=Timer for $name

[Timer]
$calendar_lines
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Оновлюємо та запускаємо
    systemctl --user daemon-reload
    systemctl --user enable --now "$name.timer"
    echo "Таймер '$name' успішно створено та запущено!"
}

# ------------------------------------------------------------------


