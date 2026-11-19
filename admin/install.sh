#!/data/data/com.termux/files/usr/bin/bash
# Menyiapkan HP ADMIN (Termux): paket yang dibutuhkan + perintah singkat `cloud`.
set -eu

ADMIN_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

echo "Memasang paket admin..."
pkg update -y >/dev/null
pkg install -y openssh git termux-api

chmod +x "$ADMIN_DIR/cloudctl"
printf '#!/data/data/com.termux/files/usr/bin/bash\nexec bash "%s/cloudctl" "$@"\n' "$ADMIN_DIR" > "$PREFIX/bin/cloud"
chmod +x "$PREFIX/bin/cloud"

echo
echo "Selesai. Coba:  cloud help"
echo "Berikutnya:     cloud init"
echo "(Notifikasi monitor butuh aplikasi Termux:API, satu sumber dengan Termux.)"
