#define _XOPEN_SOURCE 700  
#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <dirent.h>
#include <unistd.h>
#define DIARY_DIR "/home/alex320388/awards/vimwiki/diary/"

int main() {
    struct dirent *entry;
    DIR *dp = opendir(DIARY_DIR);
    if (!dp) { 
        printf("🗓️ 0\n\n"); 
        return 0; 
    }

    time_t now = time(NULL);
    struct tm *local_now = localtime(&now);

    int count = 0;
    char msg_buffer[2048] = "";

    while ((entry = readdir(dp))) {
        if (entry->d_type == DT_REG && strstr(entry->d_name, ".md")) {
            char path[512];
            snprintf(path, sizeof(path), "%s%s", DIARY_DIR, entry->d_name);
            
            FILE *f = fopen(path, "r");
            if (!f) continue;

            char date_str[11];
            strncpy(date_str, entry->d_name, 10);
            date_str[10] = '\0';

            char line[256];

            while (fgets(line, sizeof(line), f)) {
                int h, m;
                // Парсим формат "- HH:MM"
                if (sscanf(line, "- %d:%d", &h, &m) == 2) {
                    count++;

                    struct tm tm_event;
                    memset(&tm_event, 0, sizeof(tm_event));
                    
                    if (strptime(date_str, "%Y-%m-%d", &tm_event) != NULL) {
                        tm_event.tm_hour = h;
                        tm_event.tm_min = m;
                        
                        time_t t_event = mktime(&tm_event);
                        double diff = difftime(t_event, now);

                        // Уведомление: если до события осталось от 0 до 2 часов (7200 сек)
                        if (diff >= 0 && diff <= 7200) {
                            line[strcspn(line, "\r\n")] = 0;
                            
                            // Видаляємо символ '-' та пробіл на початку рядка
                            char *task_text = line;
                            while (*task_text == '-' || *task_text == ' ' || *task_text == '\t') {
                                task_text++;
                            }
                            
                            // Додаємо текст завдання
                            strncat(msg_buffer, task_text, sizeof(msg_buffer) - strlen(msg_buffer) - 1);
                            strncat(msg_buffer, "\\n", sizeof(msg_buffer) - strlen(msg_buffer) - 1);
                        }
                    }
                }
            }
            fclose(f);
        }
    }
    closedir(dp);

    // Вивід для статусбару
    printf("🗓️ %d\n\n", count);

    if (strlen(msg_buffer) > 0) {
        char command[4096];
        snprintf(command, sizeof(command),
            "dunstify -r 555 -u critical \"🗓️ Найближчі плани:\" \"%s\"",
            msg_buffer);
        
        char bus[128];
        snprintf(bus, sizeof(bus),
            "unix:path=/run/user/%d/bus", getuid());

        setenv("DBUS_SESSION_BUS_ADDRESS", bus, 1);
        char *disp = getenv("DISPLAY");
        if (!disp) setenv("DISPLAY", ":0", 1);

        system(command);
    }

    return 0;
}
