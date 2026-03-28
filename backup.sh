#!/usr/bin/env bash
set -Eeuo pipefail

############################
# НАСТРОЙКИ
############################

DIRECTORY_KINGSTON="/mnt/chromeos/removable/KINGSTON/arch/now"
DIRECTORY_SDCARD="/mnt/chromeos/removable/SD Card"
DIRECTORY_SDCARD_NOW="$DIRECTORY_SDCARD/now"
DIRECTORY_SDCARD_BASE="$DIRECTORY_SDCARD_NOW/awards_arch"

GOOGLE_DRIVE_DIR="/mnt/chromeos/GoogleDrive/SharedWithMe/168/now"

WORK_DIR="$HOME/WORK"
DIRECTORY_BASE="$HOME/awards"

LOGFILE="/tmp/encryption.log"

############################
# ЛОГИРОВАНИЕ
############################

exec > >(tee -a "$LOGFILE") 2>&1

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

die() {
  log "FATAL: $*"
  exit 1
}

############################
# ПРОВЕРКА ДИРЕКТОРИЙ
############################

DIRS=(
  "$DIRECTORY_SDCARD"
  "$DIRECTORY_SDCARD_NOW"
  "$DIRECTORY_BASE"
  "$DIRECTORY_SDCARD_BASE"
  "$GOOGLE_DRIVE_DIR"
  "$WORK_DIR"
)

for dir in "${DIRS[@]}"; do
  [ -d "$dir" ] || die "Директорія недоступна: $dir"
done

############################
# ТРАНСЛИТЕРАЦИЯ
############################

transliterate() {
  python3 - "$1" <<'PY'
import os, sys, re

root = sys.argv[1]

translit = {
'А':'A','Б':'B','В':'V','Г':'G','Д':'D','Е':'E','Є':'E','Ж':'Zh','З':'Z','И':'Y','І':'I',
'Ї':'I','Й':'Y','К':'K','Л':'L','М':'M','Н':'N','О':'O','П':'P','Р':'R','С':'S','Т':'T',
'У':'U','Ф':'F','Х':'Kh','Ц':'Ts','Ч':'Ch','Ш':'Sh','Щ':'Shch','Ю':'Yu','Я':'Ya',
'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','є':'e','ж':'zh','з':'z','и':'y','і':'i',
'ї':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r','с':'s','т':'t',
'у':'u','ф':'f','х':'kh','ц':'ts','ч':'ch','ш':'sh','щ':'shch','ю':'yu','я':'ya','ь':'','ʼ':''
}

def safe_rename(old, new):
    if old == new:
        return
    if os.path.exists(new):
        return
    os.rename(old, new)

for dirpath, dirnames, filenames in os.walk(root, topdown=False):
    for name in filenames:
        newname = ''.join([translit.get(c,c) if ord(c)>127 else c for c in name])
        newname = re.sub(r'[ ,:;\'"<>?|]', '_', newname)
        safe_rename(os.path.join(dirpath,name), os.path.join(dirpath,newname))
    for name in dirnames:
        newname = ''.join([translit.get(c,c) if ord(c)>127 else c for c in name])
        newname = re.sub(r'[ ,:;\'"<>?|]', '_', newname)
        safe_rename(os.path.join(dirpath,name), os.path.join(dirpath,newname))
PY
}

log "Виправлення назв файлів..."
transliterate "$DIRECTORY_SDCARD"
transliterate "$WORK_DIR"

############################
# ПАРОЛЬ
############################

if [ -z "${PASSPHRASE:-}" ]; then
  while true; do
    read -rsp "Пароль: " PASSPHRASE; echo
    read -rsp "Підтвердження: " CONFIRM; echo
    [[ "$PASSPHRASE" == "$CONFIRM" ]] && break
    log "Паролі не співпали"
  done
fi

############################
# RSYNC (безопасный)
############################

safe_rsync() {
  src="$1"
  dst="$2"

  [ -n "$src" ] && [ -n "$dst" ] || die "rsync: пустий шлях"
  [ -d "$src" ] || die "rsync: src не існує: $src"

  mkdir -p "$dst" || die "не можу створити директорію: $dst"

  rsync -rptDo \
    --progress \
    --delete \
    --exclude '.fuse_hidden*' \
    "$src/" "$dst/" \
    2>&1 | tee -a "$LOGFILE"
}

############################
# КОПИРОВАНИЕ
############################

read -rp "Копіювати awards? [y/N]: " ans
if [[ "$ans" =~ ^[yYаАдД]$ ]]; then
  log "Копіювання awards"
  safe_rsync "$DIRECTORY_BASE" "$DIRECTORY_SDCARD_BASE"
fi

read -rp "Копіювати WORK? [y/N]: " ans
if [[ "$ans" =~ ^[yYаАдД]$ ]]; then
  log "Копіювання WORK"
  safe_rsync "$WORK_DIR" "$DIRECTORY_SDCARD_NOW/WORK"
fi

############################
# ШИФРОВАНИЕ
############################

log "Шифрування..."

while IFS= read -r -d '' file; do

  log "Шифрую: $file"

  if gpg --batch --yes \
        --pinentry-mode loopback \
        --passphrase "$PASSPHRASE" \
        -c "$file"; then

    if [ -s "$file.gpg" ]; then
      rm -f "$file"
      log "OK: $file"
    else
      log "ERROR: порожній файл $file.gpg"
    fi

  else
    log "ERROR: gpg failed $file"
  fi

done < <(
  find "$DIRECTORY_SDCARD_NOW" -type f \
    ! -name "*.gpg" \
    ! -path "$DIRECTORY_SDCARD_BASE/*" \
    ! -path "*/STATYSTYKA/NN/*" \
    -print0
)

unset PASSPHRASE

############################
# СИНХРОНИЗАЦИЯ
############################

log "Sync → Google Drive"
safe_rsync "$DIRECTORY_SDCARD_NOW" "$GOOGLE_DRIVE_DIR"

if [ -d "$DIRECTORY_KINGSTON" ]; then
  log "Sync → KINGSTON"
  safe_rsync "$DIRECTORY_SDCARD_NOW" "$DIRECTORY_KINGSTON"
fi

sync

log ""
log "ГОТОВО"
