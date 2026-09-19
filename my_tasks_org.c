#define _XOPEN_SOURCE 700
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define ORG_FILE "/home/alex320388/awards/org/diary.org"

int main() {
    FILE *f = fopen(ORG_FILE, "r");
    if (!f) { printf("🗓️0\n"); return 0; }

    time_t now = time(NULL);
    char line[512];
    char current_task[256] = "";
    char msg_buffer[2048] = "";
    int active_todo_count = 0;
    int is_todo = 0;

    while (fgets(line, sizeof(line), f)) {
        // 1. Шукаємо заголовок. Org-заголовок починається з '*'
        if (line[0] == '*' && line[1] == ' ') {
            // Перевіряємо, чи це TODO. Якщо DONE — ігноруємо цю гілку.
            if (strstr(line, "* TODO")) {
                is_todo = 1;
                // Копіюємо текст після "* TODO "
                char *start = strstr(line, "TODO") + 5;
                strncpy(current_task, start, sizeof(current_task)-1);
                current_task[strcspn(current_task, "\r\n")] = 0;
            } else {
                is_todo = 0; // Це або DONE, або просто нотатка
            }
            continue;
        }

        // 2. Якщо це активний TODO, шукаємо в ньому час виконання
        if (is_todo) {
            char *sched = strstr(line, "SCHEDULED: <");
            if (sched) {
                int y, M, d, h, m;
                if (sscanf(sched, " SCHEDULED: <%d-%d-%d %*s %d:%d>", &y, &M, &d, &h, &m) == 5) {
                    active_todo_count++;

                    struct tm tm_ev = {0};
                    tm_ev.tm_year = y - 1900;
                    tm_ev.tm_mon = M - 1;
                    tm_ev.tm_mday = d;
                    tm_ev.tm_hour = h;
                    tm_ev.tm_min = m;
                    tm_ev.tm_isdst = -1;

                    time_t t_ev = mktime(&tm_ev);
                    double diff = difftime(t_ev, now);

                    // Уведомлення за 2 години (7200 сек)
                    if (diff >= 0 && diff <= 7200) {
                        strncat(msg_buffer, "• ", sizeof(msg_buffer)-strlen(msg_buffer)-1);
                        strncat(msg_buffer, current_task, sizeof(msg_buffer)-strlen(msg_buffer)-1);
                        strncat(msg_buffer, "\\n", sizeof(msg_buffer)-strlen(msg_buffer)-1);
                    }
                }
            }
        }
    }
    fclose(f);

    // Вивід для dwmblocks
    printf("🗓️%d\n", active_todo_count);

    // Надсилаємо сповіщення, якщо є щось термінове
    if (strlen(msg_buffer) > 0) {
        char cmd[4096];
        snprintf(cmd, sizeof(cmd), "dunstify -r 555 -u critical \"На черзі:\" \"%s\"", msg_buffer);
        system(cmd);
    }

    return 0;
}
