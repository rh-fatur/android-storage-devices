# Android Storage Cloud

Satu HP Android jadul jadi **cloud pribadi**, dikendalikan dari **HP Android lain**. Keduanya hanya butuh **Termux**, tanpa root dan tanpa web.

```text
 HP admin (apa saja)  ──── SSH/SFTP, port 8022 ────▶  HP cloud (jadul, dicolok terus)
 perintah: cloud ...                                   perintah: cloudctl ...
                                                       sshd + folder CloudStorage + watchdog
```

Server hanya terdiri dari tiga hal: **sshd** (SSH dan SFTP), **satu folder penyimpanan**, dan **watchdog** yang menjaga semuanya tetap hidup dan online. File dikirim dan diambil lewat `cloud push` dan `cloud pull`, atau lewat aplikasi SFTP apa pun.

> **Keselamatan:** baterai HP lama yang dicolok 24/7 bisa menggembung. Taruh di tempat berventilasi dan hentikan pemakaian bila baterai membesar atau sangat panas.

## Syarat

| | HP cloud | HP admin |
| --- | --- | --- |
| Android | 9 sampai 12 (API 28–32) | apa saja yang bisa memasang Termux |
| Arsitektur | 32-bit atau 64-bit (`armv7l`, `armv8l`, `aarch64`, x86) | bebas |
| Kernel | tidak butuh fitur khusus (hanya sshd dan shell) | bebas |
| Aplikasi | Termux, Termux:Boot, Termux:API | Termux, Termux:API (untuk notifikasi) |
| Koneksi | Wi-Fi stabil, **online terus**, dicolok charger | online saat dipakai |

Termux, Termux:Boot, dan Termux:API wajib dari sumber yang sama (**F-Droid** atau **GitHub Releases**), bukan Play Store.

## Setup

**1. Di HP cloud** (manual, sekali):
```bash
pkg update -y && pkg install -y openssh
termux-setup-storage        # izinkan akses storage (hanya bisa langsung dari HP)
passwd                      # password sementara untuk login pertama
whoami                      # catat username, mis. u0_a123
sshd                        # SSH aktif di port 8022
ifconfig                    # catat IP Wi-Fi, mis. 192.168.1.50
```

**2. Di HP admin** (clone ke `~`, jangan ke `/sdcard`):
```bash
pkg update -y && pkg install -y git
cd ~ && git clone https://github.com/rh-fatur/android-storage-cloud.git
cd android-storage-cloud
bash admin/install.sh       # memasang paket + perintah `cloud`
```

**3. Hubungkan dan jalankan** (dari HP admin):
```bash
cloud init                  # isi IP & username HP cloud; kunci SSH dipasang otomatis
cloud setup                 # kirim skrip + siapkan folder cloud
cloud start                 # sshd + watchdog
cloud boot-install          # auto-start setelah HP cloud restart
cloud ssh-harden            # matikan login password (setelah kunci berfungsi)
cloud monitor --bg          # notifikasi di HP admin bila HP cloud mati
```
Lalu buka aplikasi **Termux:Boot** di HP cloud satu kali.

## Pemakaian

| Tujuan | Perintah |
| --- | --- |
| Status (perangkat, sshd, internet, IP, storage, baterai) | `cloud status` |
| Start / stop / restart | `cloud start` · `cloud stop` · `cloud restart` |
| Isi folder cloud | `cloud ls` · `cloud ls Foto` |
| Kirim ke cloud | `cloud push ~/storage/shared/DCIM/foto.jpg Foto` |
| Ambil dari cloud | `cloud pull Foto/foto.jpg` (masuk ke Downloads) |
| Log watchdog | `cloud logs` · `cloud logs -f` |
| Edit konfigurasi HP cloud | `cloud config`, lalu `cloud restart` |
| Kirim ulang skrip setelah `git pull` | `cloud deploy` |
| Terminal HP cloud | `cloud shell` |

Langsung di HP cloud: `bash ~/cloud-server/cloudctl help`. Hindari spasi pada nama file untuk `push`/`pull`.

## Cara server bekerja

1. `cloudctl start` mengaktifkan **wake-lock**, menjalankan **sshd** di port 8022, lalu **watchdog** di latar belakang.
2. Folder `CLOUD_ROOT` (bawaan `~/storage/shared/CloudStorage`) adalah isi cloud. Karena ada di storage bersama, juga terlihat di aplikasi File di HP cloud.
3. **Watchdog** (tiap `WD_INTERVAL` detik, bawaan 60):
   * menyalakan ulang sshd jika mati;
   * menguji internet lewat koneksi TCP ke `1.1.1.1:443` (cadangan `8.8.8.8:53`), tanpa DNS atau curl;
   * jika gagal `WD_NET_FAILS` kali berturut-turut, mencoba mematikan lalu menyalakan Wi-Fi lewat Termux:API (hanya berhasil di sebagian perangkat);
   * mencatat peringatan bila suhu baterai ≥ `WD_TEMP_WARN` atau charger terlepas.
4. **Termux:Boot** menyalakan semuanya lagi setelah HP restart, dan menunggu jaringan siap dulu.
5. **Monitor** di HP admin memeriksa port 8022 tiap 60 detik dan mengirim notifikasi Android saat HP cloud mati atau pulih.

Watchdog tidak bisa memperbaiki router mati, gangguan ISP, listrik padam, atau Android yang mematikan Termux. Untuk itu ada monitor.

## Menjaga HP cloud tetap online (pengaturan Android)

* **Opsi pengembang → Tetap aktif** saat mengisi daya.
* **Baterai → Tanpa pembatasan** untuk Termux, Termux:Boot, dan Termux:API. Kunci Termux di daftar aplikasi terbaru bila ROM mematikan aplikasi latar belakang.
* **IP tetap:** pesan IP HP cloud di router (DHCP reservation), atau pakai Tailscale (IP `100.x.y.z` tidak berubah, dan bisa diakses dari luar rumah tanpa port forwarding).
* **Android 12 (API 31–32):** sistem bisa mematikan proses latar Termux (*phantom process killer*), termasuk sshd. Menurut wiki Termux, perbaikannya lewat `adb` (Wireless debugging): `adb shell "settings put global settings_enable_monitor_phantom_procs false"`, atau di Android 12 awal: `adb shell "device_config put activity_manager max_phantom_processes 2147483647"`. Android 9–11 tidak terpengaruh.

## Keamanan
* Jangan *port forward* 8022 ke internet publik. Untuk akses dari luar rumah, pakai Tailscale dan isi `CLOUD_HOST` dengan IP Tailscale.
* Pakai kunci SSH dan jalankan `cloud ssh-harden`. Simpan kunci privat `~/.ssh/id_ed25519_cloud` di HP admin. Jika HP admin hilang, buka Termux langsung di HP cloud untuk memasang kunci baru.
* Satu HP berarti satu titik gagal. Salin file penting ke tempat lain secara berkala.

## Pemecahan Masalah

| Gejala | Solusi |
| --- | --- |
| `cloud init` gagal tersambung | Pastikan `sshd` jalan di HP cloud, IP benar, satu Wi-Fi (atau Tailscale), port 8022. |
| `setup`: "Akses storage belum diberikan" | Jalankan `termux-setup-storage` langsung di HP cloud, lalu ulangi `cloud setup`. |
| sshd sering mati sendiri | Cek `cloud logs`. Di Android 12, lihat bagian *phantom process killer*. |
| Tidak menyala setelah HP cloud restart | Buka Termux:Boot sekali, cek `server/data/boot.log` di HP cloud, ulangi `cloud boot-install`. |
| Notifikasi monitor tidak muncul | Pasang aplikasi Termux:API (sumber sama dengan Termux) dan izinkan notifikasinya. |
| Tidak bisa SSH setelah `cloud stop` | `stop` mematikan sshd. Nyalakan dari HP cloud: `bash ~/cloud-server/cloudctl start`. |
| `git`: "dubious ownership" | Repo ada di `/sdcard`. Pindahkan ke `~`, atau `git config --global --add safe.directory <path>`. |

## Struktur

```text
├── server/                  # dideploy ke ~/cloud-server di HP cloud
│   ├── cloudctl             # setup | start | stop | restart | status | logs | boot-install | ssh-harden
│   ├── boot/start-cloud.sh  # dipanggil Termux:Boot
│   └── config/server.env.example
└── admin/                   # dipakai di HP admin
    ├── install.sh           # pasang paket + perintah `cloud`
    ├── cloudctl             # init | setup | start | status | ls | push | pull | monitor | ...
    └── config/admin.env.example
```

## Lisensi
Lihat berkas [LICENSE](LICENSE).
