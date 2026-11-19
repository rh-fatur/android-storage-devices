#!/data/data/com.termux/files/usr/bin/bash
# Dipanggil Termux:Boot (lewat wrapper dari `cloudctl boot-install`).
SERVER_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
mkdir -p "$SERVER_DIR/data"

termux-wake-lock 2>/dev/null

# Tunggu jaringan siap (maks ~60 dtk) daripada sleep tetap
for _ in $(seq 1 30); do
  ifconfig 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {f=1} END{exit !f}' && break
  sleep 2
done

bash "$SERVER_DIR/cloudctl" start >> "$SERVER_DIR/data/boot.log" 2>&1
