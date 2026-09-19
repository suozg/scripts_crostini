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

// Перевірка, чи змонтовано точку монтажу 
int is_mounted(const char *path) {
    struct stat st_target, st_parent;
    char parent_path[1024];

    if (!dir_exists(path)) return 0;

    // Отримуємо шляхи для точки та її батьківської папки
    snprintf(parent_path, sizeof(parent_path), "%s/..", path);

    if (stat(path, &st_target) != 0 || stat(parent_path, &st_parent) != 0) {
        return 0;
    }

    // Якщо device ID тома відрізняється від батьківського — значить том змонтовано!
    return (st_target.st_dev != st_parent.st_dev);
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
    printf("󰆼%ld%%", root_usage);

    // /tmp (иконка можно сменить)
    if (tmp_usage >= 0) {
        printf(" %ld%%", tmp_usage);

        if (tmp_usage > 80) {
            printf(" ⚠️");
        }
    }

    // SD Card (якщо НЕМАЄ фізичної флешки)
    if (!dir_exists("/mnt/chromeos/removable/SD Card/now")) {
        printf(" ⚠️SDC");
    }

    // IRON (якщо Є)
    if (dir_exists("/mnt/chromeos/removable/IRON")) {
        printf(" IRN");
    }

   // KINGSTON (якщо Є)
    if (dir_exists("/mnt/chromeos/removable/KINGSTON")) {
        printf(" KNG");
    }


    // --- Перевірка rclone тома now_unencrypted ---
    if (is_mounted("/home/alex320388/.now_unencrypted")) {
        printf(" 󰋊CPT:SNW");  // Якщо змонтовано crypt-диск
    }
    
    // --- Перевірка rclone тома old_unencrypted ---
    if (is_mounted("/home/alex320388/.old_unencrypted")) {
        printf(" 󰋊CPT:SLD");  // Якщо змонтовано crypt-диск
    }
    
     // --- Другий rclone-том ---
    if (is_mounted("/home/alex320388/.iron_unencrypted")) {
        printf(" 󰋊CPT:IRN"); 
    }
 
    // --- Другий rclone-том ---
    if (is_mounted("/home/alex320388/.kingston_unencrypted")) {
        printf(" 󰋊CPT:KNG"); 
    }
    

    // Кошик
    if (trash > 0) {
        printf(" 🚮%d", trash);
    }

    printf("\n");
    return 0;
}
