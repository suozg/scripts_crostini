#define _XOPEN_SOURCE 700  
#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <dirent.h>
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
    int current_year = local_now->tm_year;
    int current_mon = local_now->tm_mon;
    int current_mday = local_now->tm_mday;

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
                    // 1. Счетчик: считаем вообще все найденные задачи
                    count++;

                    struct tm tm_event;
                    memset(&tm_event, 0, sizeof(tm_event));
                    
                    if (strptime(date_str, "%Y-%m-%d", &tm_event) != NULL) {
                        tm_event.tm_hour = h;
                        tm_event.tm_min = m;
                        
                        time_t t_event = mktime(&tm_event);
                        double diff = difftime(t_event, now);

                        // 2. Уведомление: если до события осталось от 0 до 2 часов (7200 сек)
                        if (diff >= 0 && diff <= 7200) {
                            line[strcspn(line, "\r\n")] = 0;
                            strncat(msg_buffer, line + 2, 100); 
                            strncat(msg_buffer, "\\n", 3);
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

    // Виклик dunstify
    if (strlen(msg_buffer) > 0) {
        char command[4096];
        // -r 555 замінює попереднє сповіщення з таким же ID
        // -u critical робить його помітним
        snprintf(command, sizeof(command),
                 "dunstify -r 555 -u critical '🗓️ Найближчі плани:' '%s'", msg_buffer);
        system(command);
    }

    return 0;
}
