# AGENTS.md

## Gambaran Proyek
Mengubah **satu HP Android jadul** (Android 9–12, 32 atau 64-bit) menjadi cloud pribadi, dikendalikan dari **satu HP Android lain**. Keduanya memakai Termux. Tanpa web, tanpa root.

Server = **sshd (SSH + SFTP) + folder `CLOUD_ROOT` + watchdog**. Tidak ada biner pihak ketiga yang diunduh, jadi tidak ada urusan arsitektur selain yang sudah ditangani paket `openssh` Termux.

* `server/` – berjalan di **HP cloud**. Satu CLI: `server/cloudctl`. Dideploy ke `~/cloud-server`.
* `admin/` – berjalan di **HP admin**. `admin/cloudctl` (perintah `cloud` setelah `admin/install.sh`) membungkus perintah server lewat SSH, plus `ls/push/pull/monitor`.

## Konvensi
* **Pemisahan peran:** `server/` tidak mengasumsikan HP admin; `admin/` tidak mengasumsikan Termux server. Jembatannya hanya SSH + `tar`/`scp`.
* Setiap perintah baru: implementasi di `server/cloudctl`; tambahkan pembungkus di `admin/cloudctl` bila perlu remote; perbarui tabel README.
* `server/`: shebang `#!/data/data/com.termux/files/usr/bin/bash`, `set -eu`, tanpa root, path relatif ke `SERVER_DIR` (via `readlink -f`).
* `admin/`: shebang `#!/usr/bin/env bash`, `set -euo pipefail`, hanya butuh `ssh`, `scp`, `tar`.
* Konfigurasi hanya lewat `*.env`; variabel baru wajib punya default di `load_env`/`load_conf` dan contoh di `*.env.example`.
* Skrip idempotent. Proses dilacak lewat PID file + verifikasi `/proc/PID/cmdline`, bukan `pkill -f`. `stop` harus menghentikan watchdog **sebelum** sshd.
* Uji konektivitas dengan TCP (`/dev/tcp`), bukan `ping`/`curl`/DNS, agar tanpa dependensi.
* Jangan hardcode asumsi 64-bit; jangan butuh fitur kernel khusus.
* Repo harus berada di `~` Termux, bukan `/sdcard`.
* Jangan membuka port ke internet publik; akses jarak jauh via Tailscale.
* Bahasa output dan dokumen: Indonesia. Wajib lolos `bash -n` (dan `shellcheck` bila tersedia).

## Ide Lanjutan
* Sinkronisasi dua arah otomatis (rsync bila tersedia, atau `scp` bertahap).
* Backup terjadwal dari HP admin ke penyimpanan lain.
* Akun SFTP terbatas (satu folder per pengguna) selain akun admin.
* Antarmuka web (Filebrowser) sebagai lapisan opsional di atas server ini.
