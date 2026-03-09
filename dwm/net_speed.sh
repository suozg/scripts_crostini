#!/bin/bash
# usage: ./net_speed [IFACE]   (по умолчанию eth0)
IFACE="${1:-eth0}"

# автопоиск, если интерфейс не найден
if [ ! -d "/sys/class/net/$IFACE" ]; then
  IFACE=$(ls -1 /sys/class/net | grep -v lo | head -n1)
  [ -z "$IFACE" ] && { echo "Не знайдено інтерфейс"; exit 1; }
fi

# надёжное чтение байт RX и TX из /proc/net/dev
get_bytes() {
  awk -v iface="$IFACE" -F'[: ]+' '$1==iface {print $2, $10}' /proc/net/dev
}

read RX1 TX1 < <(get_bytes)
# fallback на случай странного формата
if [ -z "$RX1" ] || [ -z "$TX1" ]; then
  line=$(grep -E "^\s*$IFACE:" /proc/net/dev)
  read RX1 TX1 < <(echo "$line" | sed 's/^[ \t]*//' | sed 's/:/ /' | awk '{print $2, $10}')
fi

sleep 1

read RX2 TX2 < <(get_bytes)
if [ -z "$RX2" ] || [ -z "$TX2" ]; then
  line=$(grep -E "^\s*$IFACE:" /proc/net/dev)
  read RX2 TX2 < <(echo "$line" | sed 's/^[ \t]*//' | sed 's/:/ /' | awk '{print $2, $10}')
fi

: "${RX1:=0}"; : "${TX1:=0}"; : "${RX2:=0}"; : "${TX2:=0}"

DRX=$((RX2 - RX1))
DTX=$((TX2 - TX1))
[ "$DRX" -lt 0 ] && DRX=0
[ "$DTX" -lt 0 ] && DTX=0

# Kbps с двумя знаками
KBRX=$(awk -v b="$DRX" 'BEGIN{printf "%.1f", b*8/1024}')
KBTX=$(awk -v b="$DTX" 'BEGIN{printf "%.1f", b*8/1024}')

UPTIME_ONLY=$(uptime | sed -E 's/.* up ([^,]+),.*/\1/')
LOAD_AVG=$(uptime \
  | awk -F'load average: ' '{print $2}' \
  | tr ',' '.' \
  | awk '{printf "%.2f", ($1+$2+$3)/3}')
UPTM="↑T$UPTIME_ONLY, λ $LOAD_AVG"

# если трафик 0, проверяем пинг до 1.1.1.1 и выводим статус
if [ "$DRX" -eq 0 ] && [ "$DTX" -eq 0 ]; then
  if ping -c1 -W1 1.1.1.1 >/dev/null 2>&1; then
    echo "$UPTM | 🖧 ↓${KBRX} ↑${KBTX} Kbps"
  else
    echo "$UPTM | ❌🖧"
  fi
else
  echo "$UPTM | 🖧 ↓${KBRX} ↑${KBTX} Kbps"
fi

