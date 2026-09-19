#include <X11/Xlib.h>
#include <X11/XKBlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

static bool has_dunstify = false;
static bool last_caps_state = false; // Зберігаємо попередній стан Caps Lock

bool check_dunstify() {
    return system("which dunstify >/dev/null 2>&1") == 0;
}

void show_notification(bool caps_on) {
    if (!has_dunstify) return;

    // Якщо стан не змінився, нічого не робимо (запобігає морганню)
    if (caps_on == last_caps_state) return;

    last_caps_state = caps_on;

    if (caps_on) {
        // Створюємо постійне вікно лише при увімкненні Caps Lock
        system("dunstify -r 9991 -u critical -t 3000 'Caps Lock' 'УВІМКНЕНО 🔒' &");
    } else {
        // Примусово закриваємо вікно 9991 БЕЗ створення нового
        system("dunstify -C 9991 &");
    }
}

int main() {
    Display *display = XOpenDisplay(NULL);
    if (!display) return 1;

    has_dunstify = check_dunstify();
    if (!has_dunstify) {
        fprintf(stderr, "watch_caps: dunstify не знайдено. Сповіщення вимкнено.\n");
    }

    int xkb_base_event_code;
    XkbQueryExtension(display, NULL, &xkb_base_event_code, NULL, NULL, NULL);
    XkbSelectEvents(display, XkbUseCoreKbd, XkbStateNotifyMask, XkbStateNotifyMask);

    // Отримуємо початковий стан Caps Lock при старті програми
    XkbStateRec xkb_state;
    XkbGetState(display, XkbUseCoreKbd, &xkb_state);
    last_caps_state = (xkb_state.mods & LockMask) != 0;

    XEvent event;
    while (1) {
        XNextEvent(display, &event);
        if (event.type == xkb_base_event_code) {
            XkbEvent *xkb_event = (XkbEvent *)&event;
            if (xkb_event->any.xkb_type == XkbStateNotify) {
                if (xkb_event->state.changed & XkbModifierStateMask) {
                    system("pkill -RTMIN+1 dwmblocks");

                    bool caps_on = (xkb_event->state.mods & LockMask) != 0;
                    show_notification(caps_on);
                }
            }
        }
    }

    XCloseDisplay(display);
    return 0;
}
