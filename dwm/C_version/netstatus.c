#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/sysinfo.h>
#include <locale.h>

// Функція, яка повертає іконку Nerd Font залежно від назви інтерфейсу
const char* get_iface_icon(const char *iface) {
    // Дротовий Ethernet (eth0, enp3s0, ...)
    if (strncmp(iface, "eth", 3) == 0 || strncmp(iface, "en", 2) == 0) {
        return "󰈀"; // Іконка Ethernet (Nerd Font: nf-md-ethernet)
    }
    // Бездротовий Wi-Fi (wlan0, wlp2s0, ...)
    if (strncmp(iface, "wlan", 4) == 0 || strncmp(iface, "wl", 2) == 0) {
        return "󰖩"; // Іконка Wi-Fi (Nerd Font: nf-md-wifi)
    }
    // VPN (tun0, wireguard, ...)
    if (strncmp(iface, "tun", 3) == 0 || strncmp(iface, "wg", 2) == 0) {
        return "󰦝"; // Іконка VPN (Nerd Font: nf-md-vpn)
    }
    // Локальна петля (lo)
    if (strncmp(iface, "lo", 2) == 0) {
        return "󰓡"; // Іконка Loopback
    }
    // За замовчуванням (невідомий тип)
    return "󰲝"; // Загальна іконка мережі
}

void get_active_interface(char *iface) {
    FILE *f = fopen("/proc/net/route", "r");
    if (!f) return;
    char line[256], name[32], dest[32];
    fgets(line, sizeof(line), f);
    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, "%31s %31s", name, dest) == 2) {
            if (strcmp(dest, "00000000") == 0) {
                strcpy(iface, name);
                break;
            }
        }
    }
    fclose(f);
}

void get_net_bytes(const char *iface, unsigned long *rx, unsigned long *tx) {
    FILE *f = fopen("/proc/net/dev", "r");
    if (!f) return;
    char line[256];
    *rx = 0; *tx = 0;
    while (fgets(line, sizeof(line), f)) {
        if (strstr(line, iface)) {
            char *colon = strchr(line, ':');
            if (colon) sscanf(colon + 1, "%lu %*u %*u %*u %*u %*u %*u %*u %lu", rx, tx);
            break;
        }
    }
    fclose(f);
}

int main(int argc, char *argv[]) {
    // Встановлюємо локаль, щоб Nerd Font іконки (UTF-8) виводилися коректно
    if (!setlocale(LC_ALL, "en_US.UTF-8")) {
        setlocale(LC_ALL, "");
    }

    char iface[32] = "eth0";
    unsigned long rx1, tx1, rx2, tx2;
    struct sysinfo s_info;

    if (argc > 1) strncpy(iface, argv[1], 31);
    else get_active_interface(iface);

    get_net_bytes(iface, &rx1, &tx1);
    sleep(1);
    get_net_bytes(iface, &rx2, &tx2);

    double rx_kbps = (rx2 - rx1) * 8.0 / 1024.0;
    double tx_kbps = (tx2 - tx1) * 8.0 / 1024.0;

    sysinfo(&s_info);
    long h = (s_info.uptime % 86400) / 3600;
    long m = (s_info.uptime % 3600) / 60;
    double load = s_info.loads[0] / 65536.0;

    // Отримуємо іконку для поточного інтерфейсу
    const char *icon = get_iface_icon(iface);

    // ВИВІД (максимально компактний, без слів "UP", "Kbps")
    // λ ->  (Nerd Font CPU)
    printf("T %ld:%02ld | λ %.2f | %s ", h, m, load, icon);

    if (rx2 == 0 && tx2 == 0) {
        printf("❌");
    } else {
        // v ->  , ^ ->  (Nerd Font Arrows)
        printf("%.1f %.1f Kbps", rx_kbps, tx_kbps);
    }

    printf("\n");
    return 0;
}
