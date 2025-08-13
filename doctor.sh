#!/usr/bin/env bash
set -euo pipefail

stamp=$(date +%F-%H%M%S)
log="doctor-$stamp.log"

have(){ command -v "$1" >/dev/null 2>&1; }

{
  echo "### Port Doctor — $stamp"
  echo "== Host =="; hostnamectl 2>/dev/null || hostname; echo
  echo "== Uptime =="; uptime; echo
  echo "== Disk (/, /var) =="; df -hT | awk 'NR==1 || $7=="/" || $7=="/var"'; echo
  echo "== Memory summary =="; free -h; echo
  echo "== Network: listening sockets =="
  if have ss; then ss -tulpn | awk 'NR==1 || /LISTEN/'
  else lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null || true
  fi
  echo
  echo "== Top CPU =="; ps -eo pid,ppid,comm,%cpu,%mem --sort=-%cpu | head -n 8; echo
  echo "== Top MEM =="; ps -eo pid,ppid,comm,%mem,%cpu --sort=-%mem | head -n 8; echo
  echo "== Recent critical logs =="
  if have journalctl; then journalctl -p 3..0 -n 50 --no-pager || true
  elif [ -f /var/log/syslog ]; then tail -n 200 /var/log/syslog
  else echo "(no journal/syslog available)"
  fi
} | tee "$log"

echo "Saved report: $log"
