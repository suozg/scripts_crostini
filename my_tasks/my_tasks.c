#define _XOPEN_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


#define EVENTS_FILE "/home/user/awards/events.txt"
#define MAX_LINE 512

int main() {
    FILE *f = fopen(EVENTS_FILE, "r");
    if (!f) {
        printf("🗓️ 0\n\n");
        return 0;
    }

    char line[MAX_LINE];
    time_t now = time(NULL);
    struct tm tm_event;
    int count = 0;
    char msg_buffer[4096] = "";

    while (fgets(line, sizeof(line), f)) {
        if (line[0] == '#' || strlen(line) < 16) continue;
        memset(&tm_event, 0, sizeof(tm_event));
        if (strptime(line, "%Y-%m-%d %H:%M", &tm_event) == NULL) continue;
        time_t t_event = mktime(&tm_event);
        double diff = difftime(t_event, now);

        if (diff >= 0) count++; // будущие события

        // Для всплывашки: события в пределах +1 часа
        if (diff >= 0 && diff <= 3600) {
            char *msg = strchr(line, ' ');
            if (msg) msg = strchr(msg+1, ' '); // отрезаем дату и время
            if (msg) {
                strncat(msg_buffer, msg+1, sizeof(msg_buffer)-strlen(msg_buffer)-2);
                strncat(msg_buffer, "\n", sizeof(msg_buffer)-strlen(msg_buffer)-1);
            }
        }
    }
    fclose(f);

    // Вывод для dwmblocks
    printf("🗓️ %d\n\n", count);

    // Всплывающее окно (если есть события ближайшего часа)
    if (strlen(msg_buffer) > 0) {
        char command[8192];
        snprintf(command, sizeof(command),
                 "notify-send '🗓️ Активні події' '%s' -t 5000", msg_buffer);
        system(command);
    }

    return 0;
}
