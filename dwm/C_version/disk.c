#include <stdio.h>
#include <sys/statvfs.h>
#include <sys/stat.h>
#include <dirent.h>
#include <string.h>

// Функція для перевірки, чи існує директорія
int dir_exists(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
        return 1;
    }
    return 0;
}

long get_disk_usage(const char *path) {
    struct statvfs vfs;
    if (statvfs(path, &vfs) != 0) return -1;
    unsigned long total = vfs.f_blocks * vfs.f_frsize;
    unsigned long free = vfs.f_bfree * vfs.f_frsize;
    if (total == 0) return 0;
    return ((total - free) * 100) / total;
}

int get_trash_count() {
    int count = 0;
    struct dirent *de;
    const char *trash_path = "/home/alex320388/.local/share/Trash/files";
    DIR *dr = opendir(trash_path);
    if (dr == NULL) return 0;
    while ((de = readdir(dr)) != NULL) {
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0)
            continue;
        count++;
    }
    closedir(dr);
    return count;
}

int main() {
    long root_usage = get_disk_usage("/");
    int trash = get_trash_count();

    // Вивід кореневого розділу
    printf("󰆼 %ld%%", root_usage);

    // Перевірка SD Card (якщо НЕМАЄ — виводимо попередження)
    if (!dir_exists("/mnt/chromeos/removable/SD Card/now")) {
        printf(" ⚠️ SD!");
    }

    // Перевірка KINGSTON (якщо Є — виводимо назву)
    if (dir_exists("/mnt/chromeos/removable/KINGSTON")) {
        printf("  KNG"); //  - іконка USB в Nerd Fonts
    }

    // Кошик
    if (trash > 0) {
        printf(" 🚮 %d", trash);
    }

    printf("\n");
    return 0;
}
