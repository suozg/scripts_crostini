## Демон для DWM та MPV який виводить в dwmblocks назву композиції, що програється

!(radio dwm)[radio/image.png]

* Компіляція
---
```
gcc -O2 mpvdwm.c -o mpvdwm
sudo cp mpvdwm /usr/local/bin/
```

* Тестовий запуск
---
Щоб перевірити, чи бачать MPV та демон MPVDWM один одного:

1. У першому терміналі запустіть демон: ./mpvdwm

2. У другому терміналі запустіть mpv з прапорцем сокета:
```
mpv --no-video --input-ipc-server=/tmp/mpv-radio-socket "URL_РАДІО"
```

3. Переглянути вміст файлу: 
```
cat /tmp/dwm-radio-status
```

Якщо там з'явилася назва пісні, C-код працює.

* Автоматизація DWM

1. Редагуємо blocks.h
```
static const Block blocks[] = {
    {"", "cat /tmp/dwm-radio-status", 0, 15},
};
```
1. Автозапуск демона (.xinitrc або ваш скрипт автозапуску)

# У вашому скрипті автозапуску додайте строку
```
/usr/local/bin/mpvdwm &
```
