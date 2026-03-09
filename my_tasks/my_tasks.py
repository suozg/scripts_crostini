#!/usr/bin/env python3
import datetime
import subprocess
import os
import sys

# Файл для збереження подій
EVENTS_FILE = os.path.expanduser("~/awards/events.txt")

# Шлях до терміналу Sakura та редактора Micro
SAKURA_PATH = "/usr/bin/sakura"
MICRO_PATH = "/usr/bin/micro"

# --- Гарантія, що у файлі є приклад ---
def ensure_example_comment():
    """Перевіряє чи є у файлі приклад, і додає його якщо ні."""
    example_line = "# Приклад: 2025-09-10 14:30 Зустріч з командуванням\n"
    if not os.path.exists(EVENTS_FILE):
        # Якщо файла нема – створюємо з прикладом
        with open(EVENTS_FILE, "w") as f:
            f.write(example_line)
        return

    # Якщо файл є – читаємо
    with open(EVENTS_FILE, "r") as f:
        lines = f.readlines()

    # Перевіряємо чи перший рядок вже приклад
    if not lines or not lines[0].startswith("# Приклад:"):
        # Вставляємо приклад на початок
        with open(EVENTS_FILE, "w") as f:
            f.write(example_line)
            # додаємо решту рядків, але без старих прикладів
            for line in lines:
                if not line.startswith("# Приклад:"):
                    f.write(line)

def load_events():
    """Завантажує події з файлу подій."""
    events = []
    if not os.path.exists(EVENTS_FILE):
        return events
    with open(EVENTS_FILE, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            try:
                parts = line.split(maxsplit=2)
                date_str = parts[0]
                time_str = parts[1]
                message = parts[2]
                event_datetime = datetime.datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M")
                events.append({'datetime': event_datetime, 'message': message})
            except (ValueError, IndexError):
                pass
    return events

def get_closest_event(all_events=False):
    """Знаходить найближчу майбутню або активну подію."""
    events = load_events()
    now = datetime.datetime.now()
    closest_event = None
    min_time_diff = datetime.timedelta(days=365 * 10)

    if not all_events:
        for event in events:
            time_until_event = event['datetime'] - now
            if datetime.timedelta(minutes=-30) <= time_until_event < min_time_diff:
                closest_event = event
                min_time_diff = time_until_event
        return closest_event, min_time_diff
    else:
        active_events = []
        for event in events:
            time_until_event = event['datetime'] - now
            if datetime.timedelta(minutes=-5) <= time_until_event <= datetime.timedelta(minutes=5):
                active_events.append(event)
        return active_events, None

def open_editor():
    """Відкриває Sakura з Micro, що редагує файл подій."""
    current_env = os.environ.copy()
    if 'DISPLAY' not in current_env:
        current_env['DISPLAY'] = ':0.0'
    
    try:
        subprocess.Popen([SAKURA_PATH, '-e', f'{MICRO_PATH} {EVENTS_FILE}'],
                         env=current_env)
    except FileNotFoundError:
        with open("/tmp/i3blocks_calendar_error.log", "a") as log_file:
            log_file.write(f"[{datetime.datetime.now()}] Помилка: Sakura ({SAKURA_PATH}) або Micro ({MICRO_PATH}) не знайдено. Перевірте шляхи та PATH.\n")
    except Exception as e:
        with open("/tmp/i3blocks_calendar_error.log", "a") as log_file:
            log_file.write(f"[{datetime.datetime.now()}] Невідома помилка при відкритті редактора: {e}\n")

# --- ЗМІНА: НОВА ФУНКЦІЯ ДЛЯ NOTIFY-SEND ---
def show_notification_reminder(title, message):
    """Відображає нагадування за допомогою notify-send."""
    try:
        # -t 5000: Сповіщення зникне через 5000 мілісекунд (5 секунд)
        # -i dialog-information: Стандартна іконка інформації (або інша, яка тобі подобається)
        subprocess.run(["notify-send", title, message, "-t", "0", "-i", "dialog-information"], check=True)
    except FileNotFoundError:
        with open("/tmp/i3blocks_calendar_error.log", "a") as log_file:
            log_file.write(f"[{datetime.datetime.now()}] Помилка: 'notify-send' не знайдено. Перевірте встановлення 'libnotify-bin' або 'libnotify'.\n")
    except subprocess.CalledProcessError as e:
        with open("/tmp/i3blocks_calendar_error.log", "a") as log_file:
            log_file.write(f"[{datetime.datetime.now()}] Помилка при відображенні notify-send: {e}\n")

if __name__ == "__main__":
    ensure_example_comment()

    #if os.environ.get('BLOCK_BUTTON') == '1':
    #    open_editor()
    #    sys.exit(0)
    if os.environ.get('BLOCK_BUTTON') == '1':
        with open("/tmp/my_tasks_click.log", "a") as log:
            log.write(f"CLICK DETECTED at {datetime.datetime.now()}\n")
        open_editor()
        sys.exit(0)

    active_events_for_notification, _ = get_closest_event(all_events=True) # Змінив назву змінної для ясності

    for event in active_events_for_notification: # Використовуємо нову змінну
        show_notification_reminder("🔔 Нагадування!",
                       f"{event['message']}\n\n"
                       f"Коли: {event['datetime'].strftime('%Y-%m-%d в %H:%M')}")

    closest_event_for_i3bar, min_time_diff = get_closest_event(all_events=False)

    output_text = "🗓️"
    output_color = "#888888"

    if closest_event_for_i3bar:
        total_seconds = int(min_time_diff.total_seconds())

        if total_seconds < 0:
            output_text = "🔔 " + closest_event_for_i3bar['datetime'].strftime('%H:%M')
            output_color = "#FF0000"
        elif total_seconds < 3600:
            minutes = total_seconds // 60
            output_text = f"🔔 {minutes}хв" # Змінено на укр. скорочення
            output_color = "#FFFF00"
        elif total_seconds < 86400:
            hours = total_seconds // 3600
            output_text = f"🔔 {hours}год" # Змінено на укр. скорочення
            output_color = "#99CCFF"
        else:
            output_text = "🔔 " + closest_event_for_i3bar['datetime'].strftime('%d.%m')
            output_color = "#99CCFF"

    print(output_text)
    print(output_color)
    print("")
