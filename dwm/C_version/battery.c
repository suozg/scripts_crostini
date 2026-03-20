#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void send_notification(const char *msg) {
    char command[256];
    sprintf(command, "notify-send -u normal 'Battery' '%s'", msg);
    system(command);
}

int main() {
    int capacity = 0;
    char status[32] = {0};
    
    // Шляхи саме для вашої системи
    FILE *f_cap = fopen("/sys/class/power_supply/battery/capacity", "r");
    FILE *f_stat = fopen("/sys/class/power_supply/battery/status", "r");

    if (!f_cap || !f_stat) {
        printf("󰂃 Error\n");
        if (f_cap) fclose(f_cap);
        if (f_stat) fclose(f_stat);
        return 1;
    }

    fscanf(f_cap, "%d", &capacity);
    fscanf(f_stat, "%s", status);
    fclose(f_cap);
    fclose(f_stat);

    const char *icon = "🔋";
    int is_discharging = (strcmp(status, "Discharging") == 0);

    if (strcmp(status, "Charging") == 0) icon = "⚡";
    else if (strcmp(status, "Full") == 0) icon = "🔌";

    // Якщо треба просту логіку без сповіщень, залишити тільки printf
    if (capacity < 21 && is_discharging) {
        printf("⚠️ %s%d%%", icon, capacity);
        // Створення мітки, щоб не спамити notify-send
        if (access("/tmp/bat_low", F_OK) == -1) {
            send_notification("Низький заряд! Підключіть живлення.");
            system("touch /tmp/bat_low");
        }
    } else if (capacity > 80 && !is_discharging) {
        printf("%s%d%%", icon, capacity);
        if (access("/tmp/bat_high", F_OK) == -1) {
            send_notification(">80% Можна вимкнути зарядку.");
            system("touch /tmp/bat_high");
        }
    } else {
        printf("%s%d%%", icon, capacity);
        // Видаляємо мітки, коли стан змінився
        unlink("/tmp/bat_low");
        unlink("/tmp/bat_high");
    }

    printf("\n");
    return 0;
}
