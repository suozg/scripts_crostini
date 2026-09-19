#include <stdio.h>
#include <sys/statvfs.h>
#include <sys/stat.h>
#include <dirent.h>
#include <string.h>

// Перевірка існування директорії
int dir_exists(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0 && S_ISDIR(st.st_mode));
}

// % використання файлової системи
long get_disk_usage(const char *path) {
    struct statvfs vfs;
    if (statvfs(path, &vfs) != 0) return -1;

    unsigned long total = vfs.f_blocks * vfs.f_frsize;
    unsigned long free  = vfs.f_bavail * vfs.f_frsize;

    if (total == 0) return 0;
    return ((total - free) * 100 + total / 2) / total;
}

// Кількість файлів у кошику
int get_trash_count() {
    int count = 0;
    struct dirent *de;
    const char *trash_path = "/home/alex320388/.local/share/Trash/files";

    DIR *dr = opendir(trash_path);
    if (!dr) return 0;

    while ((de = readdir(dr)) != NULL) {
        if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, ".."))
            continue;
        count++;
    }

    closedir(dr);
    return count;
}

int main() {
    long root_usage = get_disk_usage("/");
    long tmp_usage  = get_disk_usage("/tmp");
    int trash = get_trash_count();

    // Корінь
    printf("󰆼 %ld%%", root_usage);

    // /tmp (иконка можно сменить)
    if (tmp_usage >= 0) {
        printf("  %ld%%", tmp_usage);

        if (tmp_usage > 80) {
            printf(" ⚠️");
        }
    }

    // SD Card (якщо НЕМАЄ)
    if (!dir_exists("/mnt/chromeos/removable/SD Card/now")) {
        printf(" ⚠️SD");
    }

    // KINGSTON (якщо Є)
    if (dir_exists("/mnt/chromeos/removable/KINGSTON")) {
        printf("  KNG");
    }

    // Кошик
    if (trash > 0) {
        printf(" 🚮 %d", trash);
    }

    printf("\n");
    return 0;
}
