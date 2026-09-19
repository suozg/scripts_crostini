#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/sysinfo.h>
#include <sys/time.h>
#include <locale.h>

typedef struct {
    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
} CpuStats;

const char* get_iface_icon(const char *iface) {
    if (strncmp(iface, "eth", 3) == 0 || strncmp(iface, "en", 2) == 0) return "󰈀";
    if (strncmp(iface, "wlan", 4) == 0 || strncmp(iface, "wl", 2) == 0) return "󰖩";
    if (strncmp(iface, "tun", 3) == 0 || strncmp(iface, "wg", 2) == 0) return "󰦝";
    if (strncmp(iface, "lo", 2) == 0) return "󰓡";
    return "󰲝";
}

void get_active_interface(char *iface) {
    FILE *f = fopen("/proc/net/route", "r");
    if (!f) return;
    char line[256], name[32], dest[32];
    fgets(line, sizeof(line), f);
    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, "%31s %31s", name, dest) == 2) {
            if (strcmp(dest, "00000000") == 0) {
                strncpy(iface, name, 31);
                iface[31] = '\0';
                break;
            }
        }
    }
    fclose(f);
}

int get_net_bytes(const char *iface, unsigned long long *rx, unsigned long long *tx) {
    FILE *f = fopen("/proc/net/dev", "r");
    if (!f) return 0;
    
    char line[512];
    *rx = 0;
    *tx = 0;
    int found = 0;

    while (fgets(line, sizeof(line), f)) {
        char *colon = strchr(line, ':');
        if (!colon) continue;

        *colon = '\0';
        char *iface_name = line;
        while (*iface_name == ' ') iface_name++;

        if (strcmp(iface_name, iface) == 0) {
            sscanf(colon + 1, "%llu %*u %*u %*u %*u %*u %*u %*u %llu", rx, tx);
            found = 1;
            break;
        }
    }
    fclose(f);
    return found;
}

void get_cpu_stats(CpuStats *st) {
    FILE *f = fopen("/proc/stat", "r");
    if (!f) return;
    char line[256];
    if (fgets(line, sizeof(line), f)) {
        sscanf(line, "cpu %llu %llu %llu %llu %llu %llu %llu %llu",
               &st->user, &st->nice, &st->system, &st->idle,
               &st->iowait, &st->irq, &st->softirq, &st->steal);
    }
    fclose(f);
}

double calculate_cpu_percent(const CpuStats *s1, const CpuStats *s2) {
    unsigned long long idle1 = s1->idle + s1->iowait;
    unsigned long long idle2 = s2->idle + s2->iowait;

    unsigned long long non_idle1 = s1->user + s1->nice + s1->system + s1->irq + s1->softirq + s1->steal;
    unsigned long long non_idle2 = s2->user + s2->nice + s2->system + s2->irq + s2->softirq + s2->steal;

    unsigned long long total1 = idle1 + non_idle1;
    unsigned long long total2 = idle2 + non_idle2;

    double total_diff = (double)(total2 - total1);
    double idle_diff = (double)(idle2 - idle1);

    if (total_diff == 0.0) return 0.0;
    return ((total_diff - idle_diff) / total_diff) * 100.0;
}

double get_ram_usage(void) {
    FILE *f = fopen("/proc/meminfo", "r");
    if (!f) return 0.0;

    char line[256];
    unsigned long total = 0, available = 0;

    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, "MemTotal: %lu kB", &total) == 1) continue;
        if (sscanf(line, "MemAvailable: %lu kB", &available) == 1) continue;
    }
    fclose(f);

    if (total == 0) return 0.0;

    unsigned long used = total - available;
    return ((double)used / total) * 100.0;
}
void format_speed(double bytes_per_sec, char *buffer, size_t buf_size) {
    if (bytes_per_sec >= 1024.0 * 1024.0 * 1024.0) {
        snprintf(buffer, buf_size, "%.1fG", bytes_per_sec / (1024.0 * 1024.0 * 1024.0));
    } else if (bytes_per_sec >= 1024.0 * 1024.0) {
        snprintf(buffer, buf_size, "%.1fM", bytes_per_sec / (1024.0 * 1024.0));
    } else if (bytes_per_sec >= 1024.0) {
        snprintf(buffer, buf_size, "%.0fK", bytes_per_sec / 1024.0);
    } else {
        snprintf(buffer, buf_size, "%.0fB", bytes_per_sec);
    }
}
int main(int argc, char *argv[]) {
    if (!setlocale(LC_ALL, "en_US.UTF-8")) {
        setlocale(LC_ALL, "");
    }

    char iface[32] = "";
    if (argc > 1) {
        strncpy(iface, argv[1], 31);
    } else {
        get_active_interface(iface);
    }

    // 1. Отримуємо поточний час (у секундах з мікросекундами)
    struct timeval tv;
    gettimeofday(&tv, NULL);
    double now = tv.tv_sec + (tv.tv_usec / 1000000.0);

    // 2. Зчитуємо поточні показники мережі та CPU
    unsigned long long rx2 = 0, tx2 = 0;
    int found = get_net_bytes(iface, &rx2, &tx2);
    
    CpuStats cpu2;
    get_cpu_stats(&cpu2);

    // 3. Зчитуємо попередні показники з тимчасового файлу /tmp/dwmblocks_stat.tmp
    double prev_time = 0;
    unsigned long long rx1 = 0, tx1 = 0;
    CpuStats cpu1 = {0};

    FILE *f_tmp = fopen("/tmp/dwmblocks_stat.tmp", "r");
    if (f_tmp) {
        fscanf(f_tmp, "%lf %llu %llu %llu %llu %llu %llu %llu %llu %llu %llu",
               &prev_time, &rx1, &tx1,
               &cpu1.user, &cpu1.nice, &cpu1.system, &cpu1.idle,
               &cpu1.iowait, &cpu1.irq, &cpu1.softirq, &cpu1.steal);
        fclose(f_tmp);
    }

    // 4. Записуємо нові значення у файл для наступного виклику dwmblocks
    f_tmp = fopen("/tmp/dwmblocks_stat.tmp", "w");
    if (f_tmp) {
        fprintf(f_tmp, "%.3f %llu %llu %llu %llu %llu %llu %llu %llu %llu %llu\n",
                now, rx2, tx2,
                cpu2.user, cpu2.nice, cpu2.system, cpu2.idle,
                cpu2.iowait, cpu2.irq, cpu2.softirq, cpu2.steal);
        fclose(f_tmp);
    }

    // 5. Обчислюємо затримку за часом (dt)
    double dt = now - prev_time;
    double rx_bytes_sec = 0.0, tx_bytes_sec = 0.0;
    double cpu_usage = 0.0;

    if (dt > 0.1 && dt < 10.0) { // Перевірка, що дані адекватні
        rx_bytes_sec = (rx2 >= rx1) ? (double)(rx2 - rx1) / dt : 0.0;
        tx_bytes_sec = (tx2 >= tx1) ? (double)(tx2 - tx1) / dt : 0.0;
        cpu_usage = calculate_cpu_percent(&cpu1, &cpu2);
    }

    char rx_str[16], tx_str[16];
    format_speed(rx_bytes_sec, rx_str, sizeof(rx_str));
    format_speed(tx_bytes_sec, tx_str, sizeof(tx_str));

    struct sysinfo s_info;
    sysinfo(&s_info);
    long h = (s_info.uptime % 86400) / 3600;
    long m = (s_info.uptime % 3600) / 60;

    double ram_usage = get_ram_usage();
    const char *icon = get_iface_icon(iface);

    // 6. Компактний вивід для dwmblocks
    if (!found || strlen(iface) == 0) {
        printf("󰔛%ld:%02ld 󰍛:%.0f%% 󰍛%.0f%% %s❌\n", h, m, cpu_usage, ram_usage, icon);
    } else {
        printf("󰔛%ld:%02ld 󰓅%.0f%% 󰍛%.0f%% %s%s%s\n", 
               h, m, cpu_usage, ram_usage, icon, rx_str, tx_str);
    }
    printf("\n");

    return 0;
}
