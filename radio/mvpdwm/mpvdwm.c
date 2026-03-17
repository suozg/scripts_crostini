#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#define SOCKET_PATH "/tmp/mpv-radio-socket"
#define OUTPUT_FILE "/tmp/dwm-radio-status"

int main() {
    int sock = 0;
    struct sockaddr_un serv_addr;
    char buffer[1024] = {0};

    while (1) {
        if ((sock = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
            sleep(2); continue;
        }

        serv_addr.sun_family = AF_UNIX;
        strcpy(serv_addr.sun_path, SOCKET_PATH);

        if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
            close(sock);
            sleep(2); continue;
        }

        // Підписка на події зміна метаданих (observe_property)
        const char *cmd = "{\"command\": [\"observe_property\", 1, \"media-title\"]}\n";
        send(sock, cmd, strlen(cmd), 0);

        while (read(sock, buffer, 1024) > 0) {
            // парсинг JSON 
            char *title = strstr(buffer, "\"data\":\"");
            if (title) {
                title += 8;
                char *end = strchr(title, '"');
                if (end) {
                    *end = '\0';
                    FILE *f = fopen(OUTPUT_FILE, "w");
                    if (f) {
                        // fprintf(f, "📻 %s\n", title);
                        fprintf(f, "📻 %.20s%s", title, strlen(title) > 20 ? " .." : "");
                        fclose(f);
                    }
                    // Сигнал dwmblocks 
                    system("pkill -RTMIN+15 dwmblocks");
                }
            }
            memset(buffer, 0, 1024);
        }
        close(sock);
    }
    return 0;
}
