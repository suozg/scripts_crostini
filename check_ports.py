#!/usr/bin/env python3

import subprocess
import sys
import re
from datetime import datetime
import os

# --- КОНФІГУРАЦІЯ ---
# Визначте очікуваний ("добрий") набір сокетів, що прослуховуються.
# Формат: кортеж (протокол, адреса:порт, назва_процесу)
# Використовуйте точні рядки з виводу 'sudo ss -tulnp', який ви вважаєте нормальним.
GOOD_SOCKETS = {
    ('udp', '0.0.0.0:68', 'dhclient'),
    ('udp', '0.0.0.0:55761', 'avahi-daemon'),
    ('udp', '0.0.0.0:5353', 'avahi-daemon'),
    ('udp', '*:49425', 'avahi-daemon'),
    ('udp', '*:5353', 'avahi-daemon'),
    ('tcp', '127.0.0.1:631', 'cupsd'),
    ('tcp', '[::1]:631', 'cupsd')
}

# Регулярний вираз для вилучення назви процесу з рядка 'users:(("process_name",pid=PID,...))'
PROCESS_RE = re.compile(r'users:\(\("([^"]+)",')

# Файл для логування помилок виконання скрипта (не для сповіщень i3-nagbar)
LOG_FILE = "/tmp/socket_check_script.log"
# --- КІНЕЦЬ КОНФІГУРАЦІЇ ---


def log_error(message):
    """Записує повідомлення про помилку скрипта у лог-файл."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] ERROR: {message}\n")
    print(f"ERROR: {message}", file=sys.stderr) # Також виводимо в stderr (видно крону)


def get_current_sockets():
    """Виконує 'sudo ss -tulnp', парсить вивід та повертає набір сокетів."""
    try:
        # Виконуємо команду ss. Потрібно налаштувати sudo без пароля для цієї команди.
        # 'check=True' викличе помилку, якщо команда завершиться з ненульовим кодом (напр., ss не знайдено)
        result = subprocess.run(
            ['sudo', 'ss', '-tulnp'],
            capture_output=True,
            text=True,
            check=True
        )
        lines = result.stdout.strip().split('\n')

    except FileNotFoundError:
        msg = "'ss' command not found. Please install ss (usually provided by iproute2 package)."
        log_error(msg)
        # Можливо, також сповістити користувача через i3-nagbar про критичну помилку скрипта
        subprocess.run(['i3-nagbar', '-m', f"ПОМИЛКА МОНІТОРИНГУ: Команда 'ss' не знайдена. {msg}"], check=False)
        return None
    except subprocess.CalledProcessError as e:
        msg = f"Error executing 'sudo ss -tulnp'. Return code: {e.returncode}. Stderr: {e.stderr.strip()}"
        log_error(msg)
        # Сповістити користувача про помилку виконання команди перевірки
        subprocess.run(['i3-nagbar', '-m', f"ПОМИЛКА МОНІТОРИНГУ МЕРЕЖІ: Не вдалося виконати 'ss'. Код: {e.returncode}"], check=False)
        return None
    except Exception as e:
        msg = f"An unexpected error occurred during ss execution: {e}"
        log_error(msg)
        subprocess.run(['i3-nagbar', '-m', f"ПОМИЛКА МОНІТОРИНГУ МЕРЕЖІ: Неочікувана помилка скрипта. Див. логи."], check=False)
        return None

    current_sockets = set()
    # Пропускаємо рядок заголовка
    for line in lines[1:]:
        parts = line.split()
        # Перевірка на мінімальну кількість колонок, щоб уникнути помилок парсингу
        if len(parts) < 5:
             # log_error(f"Skipping malformed ss output line: {line}") # Можливо, занадто багато логу
             continue

        netid = parts[0]
        local_address_port = parts[4] # Адреса:Порт - 5-та колонка (індекс 4)

        process_name = "N/A" # За замовчуванням, якщо інформація про процес відсутня
        # Інформація про процес починається з 6-ї колонки (індекс 5)
        if len(parts) > 5:
             process_str_parts = parts[5:]
             full_process_str = " ".join(process_str_parts) # Об'єднуємо частини, якщо в назві процесу є пробіли
             match = PROCESS_RE.search(full_process_str)
             if match:
                 process_name = match.group(1)
             # інакше process_name залишається "N/A"

        # Додаємо до набору тільки TCP або UDP сокети
        if netid in ['tcp', 'udp']:
             current_sockets.add((netid, local_address_port, process_name))
        # else: log_error(f"Skipping non-tcp/udp socket type: {netid} in line: {line}") # Можливо, занадто багато логу


    return current_sockets

def main():
    current_sockets = get_current_sockets()

    if current_sockets is None:
        # Помилка виконання ss, сповіщення вже відправлено з get_current_sockets
        sys.exit(1) # Виходимо з кодом помилки

    # Знаходимо сокети, які зараз прослуховуються, але яких НЕМАЄ в нашому "доброму" списку
    unexpected_sockets = current_sockets - GOOD_SOCKETS

    # Необов'язково: Знаходимо сокети з "доброго" списку, які ЗАРАЗ НЕ прослуховуються
    # missing_sockets = GOOD_SOCKETS - current_sockets

    if not unexpected_sockets:
        # Виявлено неочікувані сокети - формуємо повідомлення про тривогу
        message = "⚠️ МЕРЕЖЕВА ТРИВОГА: Виявлено неочікувані мережеві служби, що прослуховуються!"
        message += "\n\nНеочікувані сокети:"

        # Сортуємо список для послідовного виводу повідомлень
        for sock in sorted(list(unexpected_sockets)):
            # sock - це кортеж (протокол, адреса:порт, назва_процесу)
            protocol = sock[0].upper()
            address_port = sock[1]
            process = sock[2] if sock[2] != "N/A" else "Невідомо" # Виводимо "Невідомо" якщо процес не визначено
            message += f"\n- {protocol} {address_port} (Процес: {process})"

        message += "\n\nПеревірте систему та налаштування фаєрволу."
        message += f"\nЧас виявлення: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"


        # Виводимо повідомлення в i3-nagbar
        try:
            # check=False, щоб скрипт моніторингу не падав, якщо i3-nagbar не працює
            subprocess.run(['i3-nagbar', '-m', message], check=False)
        except FileNotFoundError:
            log_error("'i3-nagbar' command not found. Cannot display alert.")
        except Exception as e:
            log_error(f"Error calling i3-nagbar: {e}")

    # Якщо потрібно сповіщати також про відсутні очікувані сокети, додайте тут блок elif missing_sockets:
    # (Але для "помаранчевої" панелі зазвичай важливіше неочікуване).

    else:
        # Сокети відповідають "доброму" списку. Нічого не робимо, i3-nagbar не викликається.
        pass


    # Скрипт завершився без виявлення неочікуваних сокетів або після сповіщення про них.
    sys.exit(0) # Виходимо з кодом успіху, навіть якщо були сповіщення (адже скрипт відпрацював)


if __name__ == "__main__":
    # Перевіряємо, чи скрипт не запущений від root напряму (має запускатися від користувача через sudo)
    if os.geteuid() == 0:
        log_error("Script should not be run directly as root. Use cron with NOPASSWD sudo.")
        sys.exit(1)

    main()