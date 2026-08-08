#!/usr/bin/env bash
# chk_net.sh — быстрый чек сети/процессов для Crostini/Linux-контейнера
# Usage:
#   sudo ./chk_net.sh            # обычная проверка
#   sudo ./chk_net.sh --capture 500  # записать 500 пакетов в /tmp/capture-<pid>.pcap (tcpdump требуется)
#   sudo ./chk_net.sh --fix     # (ОПЦИОНАЛЬНО) установить lsof, net-tools если отсутствуют (apt required)

set -euo pipefail

CAPTURE_COUNT=0
DO_FIX=0

while (( "$#" )); do
  case "$1" in
    --capture)
      shift
      CAPTURE_COUNT=${1:-0}
      shift
      ;;
    --fix)
      DO_FIX=1
      shift
      ;;
    -*)
      echo "Unknown option: $1"; exit 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)."
  exit 1
fi

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

echo "=== Network & process quick-check ==="
echo "Time: $(timestamp)"
echo

# ensure minimal tools
MISSING=()
for cmd in ss lsof systemctl journalctl ps grep awk sed; do
  if ! command -v $cmd &>/dev/null; then
    MISSING+=("$cmd")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Missing commands: ${MISSING[*]}"
  if [[ $DO_FIX -eq 1 ]]; then
    echo "Attempting to install missing packages (apt)..."
    apt update || true
    apt install -y --no-install-recommends net-tools lsof tcpdump || true
  else
    echo "Run with --fix to try installing common tools (requires apt)."
  fi
fi
echo

# 1) Listening sockets (show external bindings)
echo "1) Listening sockets (all):"
ss -tunap || true
echo
echo "1a) Listening on non-loopback (0.0.0.0 / :::):"
ss -tunap | awk '/LISTEN/ && $5 ~ /0.0.0.0|:::/ {print}'
echo

# 2) netstat (if available) - server list
if command -v netstat &>/dev/null; then
  echo "2) netstat -tulpen (if available):"
  netstat -tulpen || true
  echo
fi

# 3) Established connections
echo "3) Established connections (tcp udp):"
ss -tupn state established || true
echo

# 4) lsof network (if available)
if command -v lsof &>/dev/null; then
  echo "4) lsof -i -P -n (network files):"
  lsof -i -P -n || true
  echo
else
  echo "4) lsof not found. Run: sudo apt install lsof"
  echo
fi

# 5) Suspicious processes (names and common networking tools)
echo "5) Look for suspicious process names / network tools:"
ps aux | egrep -i 'meterpreter|msf|msfconsole|exploit|reverse|socat|nc|netcat|bash -i|python -m http.server|python -c' || true
echo

# 6) Processes with open sockets (quick mapping)
echo "6) Processes with listening ports (PID -> cmd):"
ss -tunap | awk '/LISTEN/ {print}'
echo

# 7) Enabled systemd services (interesting ones)
if command -v systemctl &>/dev/null; then
  echo "7) systemctl enabled services (non-oneshot):"
  systemctl list-unit-files --state=enabled --no-pager || true
  echo
  echo "7a) Running services (summary):"
  systemctl list-units --type=service --state=running --no-pager || true
  echo
fi

# 8) Cron / timers
echo "8) Cron and timers:"
crontab -l 2>/dev/null || echo "(no user crontab)"
ls -la /etc/cron.* /etc/cron.d 2>/dev/null || true
systemctl list-timers --all --no-pager || true
echo

# 9) Recent error logs (journalctl)
if command -v journalctl &>/dev/null; then
  echo "9) Recent journal errors (last 200 lines):"
  journalctl -p err -n 200 --no-pager || true
  echo
fi

# 10) Routing / ARP / active IPs
echo "10) Routing and ARP table:"
ip route show || true
ip neigh show || true
echo

# 11) Simple nmap suggestion (not run automatically)
echo "11) Suggestion: run nmap from another machine to scan this host, e.g.:"
echo "    nmap -p- -sV <CHROMEBOOK_IP>"
echo

# 12) Quick heuristic checks & verdict
echo "12) Heuristics:"
SUSP_PORTS=$(ss -tunap | awk '/LISTEN/ && $5 !~ /127.0.0.1|::1/ {print $0}' | wc -l)
ESTAB=$(ss -tupn state established | wc -l)
echo "    Listening non-loopback sockets: $SUSP_PORTS"
echo "    Established connections: $ESTAB"
if (( SUSP_PORTS == 0 )) && (( ESTAB == 0 )); then
  echo "    -> No obvious externally listening services or active established connections found."
else
  echo "    -> Review the lists above for unknown services/processes."
fi
echo

# 13) Optional capture
if (( CAPTURE_COUNT > 0 )); then
  if ! command -v tcpdump &>/dev/null; then
    echo "tcpdump not found. Install with: sudo apt install tcpdump"
  else
    OUT="/tmp/capture-$$.pcap"
    echo "Starting tcpdump: capturing $CAPTURE_COUNT packets to $OUT"
    timeout 300 tcpdump -i any -nn -s 0 'tcp or udp' -c "$CAPTURE_COUNT" -w "$OUT" || true
    echo "Capture saved: $OUT"
    echo "You can analyze it with Wireshark on another machine."
  fi
fi

echo "=== End of check ==="
echo "If you want, run again with --fix to auto-install lsof/net-tools/tcpdump (uses apt)."
