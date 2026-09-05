# Amprem Web

Website Alight Motion Premium - 7 varian aktivasi premium. Setiap varian punya halaman sendiri, berdiri sendiri tanpa bot WhatsApp.

---

# DAFTAR ISI

1. [Persiapan](#persiapan)
2. [Install - Termux](#install-termux-hp-android)
3. [Install - VPS](#install-vps-server)
4. [Jalankan Setup](#jalankan-setup)
5. [Opsi Deployment](#opsi-deployment)
6. [Edit Config](#edit-config)
7. [Kelola Server](#kelola-server)
8. [Update](#update)
9. [Troubleshooting](#troubleshooting)

---

# PERSIAPAN

## Yang Dibutuhkan

### Termux (HP Android)
- HP Android 7+
- Aplikasi **Termux** (download dari **F-Droid**, BUKAN Play Store)
- Koneksi internet
- (Opsional) Domain + Cloudflare untuk deployment permanen

### VPS (Server)
- VPS dengan OS Ubuntu 20/22 atau Debian 11/12
- Akses SSH ke VPS
- (Opsional) Domain + Cloudflare untuk deployment permanen

---

# INSTALL TERMUX (HP ANDROID)

## Langkah 1: Install Termux

1. Buka browser, download **Termux** dari F-Droid:
   ```
   https://f-droid.org/en/packages/com.termux/
   ```
2. Install file APK yang sudah didownload
3. Buka Termux

> **PENTING:** Jangan pakai Termux dari Play Store! Versi di Play Store sudah outdated dan tidak work.

## Langkah 2: Update Package

```bash
pkg update && pkg upgrade -y
```

## Langkah 3: Install Git

```bash
pkg install git -y
```

## Langkah 4: Clone Repo

```bash
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
```

Kalau error clone:
```bash
# Set git config dulu
git config --global user.name "NamaKamu"
git config --global user.email "email@kamu.com"

# Clone lagi
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
```

## Langkah 5: Install Node.js

```bash
pkg install nodejs -y
```

Cek apakah sudah terinstall:
```bash
node -v
npm -v
```

## Langkah 6: Install nano (untuk edit config)

```bash
pkg install nano -y
```

## Langkah 7: Install npm Dependencies

```bash
npm install
```

Tunggu sampai selesai (biasanya 1-2 menit).

## Langkah 8: Selesai!

Lanjut ke [Jalankan Setup](#jalankan-setup)

---

# INSTALL VPS (SERVER)

## Langkah 1: SSH ke VPS

```bash
ssh root@IP_VPS_KAMU
```

Masukkan password atau gunakan SSH key.

## Langkah 2: Update System

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

## Langkah 3: Install Git

```bash
# Ubuntu/Debian
sudo apt install -y git

# CentOS/RHEL
sudo yum install -y git
```

## Langkah 4: Clone Repo

```bash
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
```

## Langkah 5: Install Node.js 20

```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs
```

Cek:
```bash
node -v
npm -v
```

## Langkah 6: Install Tools

```bash
# Ubuntu/Debian
sudo apt install -y nano curl wget

# CentOS/RHEL
sudo yum install -y nano curl wget
```

## Langkah 7: Install npm Dependencies

```bash
npm install
```

## Langkah 8: Selesai!

Lanjut ke [Jalankan Setup](#jalankan-setup)

---

# JALANKAN SETUP

Setelah install selesai, jalankan script setup:

```bash
bash setup.sh
```

Script akan menampilkan menu interaktif:

```
  ██████╗ ███████╗████████╗██████╗  ██████╗
  ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗
  ██████╔╝█████╗     ██║   ██████╔╝██║   ██║
  ██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║
  ██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝
  ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝

  Alight Motion Premium - Setup & Management

  Environment: Termux (HP Android)
  Project: /data/data/com.termux/files/home/amprem-web

  Menu Utama

    I) Install         - Install dependencies
    P) Project        - Install npm project
    D) Deployment   - Pilih cara akses internet
    C) Cek Status   - Lihat service yang jalan
    R) Restart      - Restart server
    X) Stop Semua   - Hentikan semua
    E) Edit Config - Edit config.js

    Pilih:
```

### Menu Utama:

| Pilihan | Fungsi |
|---------|--------|
| `I` | Install dependencies (Node.js, Git, nano, tunnel tools) |
| `P` | Install npm project |
| `D` | Pilih cara deployment / akses internet |
| `C` | Cek status semua service yang jalan |
| `R` | Restart server |
| `X` | Stop semua service |
| `E` | Edit config.js |

---

# OPSI DEPLOYMENT

## Termux (HP Android)

Pilih `D` di menu utama, lalu pilih:

| No | Cara | Hasil | Kebutuhan |
|----|------|-------|-----------|
| 1 | Localhost | `http://localhost:8080` | HP ini aja |
| 2 | WiFi Lokal | `http://IP_HP:8080` | HP/laptop lain di WiFi sama |
| 3 | Ngrok | URL internet | Akun ngrok.com |
| 4 | Cloudflare Quick | URL `*.trycloudflare.com` | Gratis, URL berubah |
| 5 | Cloudflare Named | `https://domain.com` | Domain di Cloudflare |
| 6 | LocalTunnel | URL `*.l.tunnel.cloud.l.google.com` | Gratis |
| 7 | Pagekite | URL `*.pagekite.me` | Akun pagekite.net |
| 8 | Serveo | URL `subdomain.serveo.net` | Gratis via SSH |
| 9 | Domain + CF Proxy | `https://domain.com` | Domain + CF Proxy |

### Detail Setiap Cara

#### 1. Localhost
- Hanya bisa diakses dari HP itu sendiri
- URL: `http://localhost:8080`
- Cocok untuk testing

#### 2. WiFi Lokal
-HP/laptop lain di WiFi yang sama bisa akses
- Buka Termux, ketik:
  ```bash
  ifconfig | grep inet
  ```
- Cari IP lokal (format: `192.168.x.x`)
- Buka browser di HP/laptop lain, masukkan:
  ```
  http://192.168.x.x:8080
  ```

#### 3. Ngrok
- URL internet stabil
- Butuh daftar gratis di https://ngrok.com
- Dapat authtoken dari dashboard ngrok
- Masukkan authtoken saat diminta script

#### 4. Cloudflare Quick
- URL internet gratis tanpa akun
- URL: `https://xxxx.trycloudflare.com`
- **URL berubah setiap kali tunnel di-restart**
- SSL otomatis dari Cloudflare

#### 5. Cloudflare Named
- URL internet permanen pakai domain sendiri
- Butuh domain yang di-manage di Cloudflare
- SSL otomatis
- URL tidak berubah

#### 6. LocalTunnel
- URL internet gratis tanpa akun
- URL: `https://xxxx.l.tunnel.cloud.l.google.com`
- URL berubah setiap sesi

#### 7. Pagekite
- URL internet dengan akun gratis
- Daftar di https://pagekite.net
- SSL support

#### 8. Serveo
- URL internet gratis via SSH reverse tunnel
- Tidak butuh akun
- Pakai subdomain tetap supaya URL tidak berubah
- Contoh: `amprem.serveo.net`

#### 9. Domain + Cloudflare Proxy
- Pakai domain dengan HTTPS dari Cloudflare
- Tidak perlu tunnel/Nginx
- Tapi IP HP bisa berubah, jadi A record perlu diupdate manual

---

## VPS (Server)

Pilih `D` di menu utama, lalu pilih:

| No | Cara | Hasil | Kebutuhan |
|----|------|-------|-----------|
| 1 | IP + Nginx | `http://IP_VPS` | IP publik VPS |
| 2 | Domain + Nginx + SSL | `https://domain.com` | Domain + Certbot |
| 3 | Domain + Cloudflare | `https://domain.com` | Domain + Cloudflare |
| 4 | Ngrok | URL internet | Akun ngrok.com |
| 5 | Cloudflare Quick | URL `*.trycloudflare.com` | Gratis |
| 6 | Cloudflare Named | `https://domain.com` | Domain + Cloudflare |
| 7 | LocalTunnel | URL internet | Gratis |
| 8 | Serveo | URL `subdomain.serveo.net` | Gratis via SSH |

### Detail Setiap Cara

#### 1. IP + Nginx
- Akses langsung via IP publik VPS
- Port 80
- Jalankan script, pilih `1`
- Buka browser: `http://IP_VPS_KAMU`
- Pastikan port 80 terbuka:
  ```bash
  # Ubuntu
  sudo ufw allow 80

  # CentOS
  sudo firewall-cmd --add-port=80/tcp --permanent
  sudo firewall-cmd --reload
  ```

#### 2. Domain + Nginx + SSL
- HTTPS dengan SSL gratis dari Let's Encrypt (Certbot)
- URL: `https://domain.com`
- Pastikan DNS A record domain sudah pointing ke IP VPS
- Script akan otomatis install Certbot dan setup SSL

#### 3. Domain + Cloudflare
- Domain via Cloudflare Tunnel
- HTTPS otomatis dari Cloudflare
- Tidak perlu buka port 80/443

#### 4. Ngrok
- Sama seperti di Termux
- Butuh authtoken dari ngrok.com

#### 5. Cloudflare Quick
- URL internet gratis `*.trycloudflare.com`
- Tidak butuh akun

#### 6. Cloudflare Named
- Domain permanen via Cloudflare Named Tunnel
- SSL otomatis

#### 7. LocalTunnel
- URL internet gratis tanpa akun

#### 8. Serveo
- URL subdomain via SSH reverse tunnel
- Tidak butuh akun

---

# EDIT CONFIG

## Lewat Menu Setup

Jalankan `bash setup.sh`, pilih `E`.

## Lewat Nano

```bash
nano config.js
```

## Lewat Script Interaktif

```bash
bash config.sh
```

Akan muncul menu interaktif untuk edit masing-masing API key.

## Lewat Sed (Langsung)

```bash
# Ganti amprem2ApiKey
sed -i "s/amprem2ApiKey: '.*'/amprem2ApiKey: 'KEY_BARU_KAMU'/" config.js

# Ganti amprem6ApiKey
sed -i "s/amprem6ApiKey: '.*'/amprem6ApiKey: 'SK-BARU'/" config.js
```

---

# FILE config.js

Buka `config.js`:

```js
export const config = {
  amprem6ApiKey: 'SK-5A6D0C0FB6D7B35A71B9A70F',
  // API key komunitas (gratisan, dibagi rame-rame).
  // Kalau mulai gagal, daftar sendiri di:
  // https://free-restapi.biz.id/users/register

  amprem2ApiKey: ''
  // WAJIB ISI kalau mau pakai Amprem2.
  // Daftar di: https://api.haidarxd.my.id
  // Ambil API key dari dashboard situs tersebut.
}
```

### Keterangan API Key:

| Key | WAJIB? | Buat Varian | Daftar di |
|-----|---------|------------|---------|
| `amprem6ApiKey` | Tidak | Amprem6 | free-restapi.biz.id |
| `amprem2ApiKey` | Ya (kalau pakai Amprem2) | Amprem2 | api.haidarxd.my.id |

- **Amprem 1, 3, 4, 5, 7** - tidak butuh config tambahan

---

# KELOLA SERVER

## Cek Status

```bash
bash setup.sh
# Pilih C
```

Atau manual:
```bash
# Cek apakah server jalan
ps aux | grep node

# Cek port yang listen
ss -tlnp | grep node
```

## Start Server

```bash
node server.js
```

## Stop Server

```bash
pkill -f "node server"
```

## Ganti Port

```bash
PORT=8080 node server.js
```

## Lihat Log

```bash
# Log server
cat /tmp/amprem.log

# Log tunnel
cat /tmp/amprem-tunnel.log

# Log Ngrok
cat /tmp/amprem-ngrok.log

# Log LocalTunnel
cat /tmp/amprem-lt.log

# Log Serveo
cat /tmp/amprem-serveo.log

# Log Pagekite
cat /tmp/amprem-pk.log
```

## Restart

```bash
bash setup.sh
# Pilih R
```

Atau manual:
```bash
pkill -f "node server"
sleep 1
node server.js
```

## Stop Semua Service

```bash
bash setup.sh
# Pilih X
```

Atau manual:
```bash
pkill -f "node server"
pkill -f "cloudflared"
pkill -f "ngrok"
pkill -f "lt "
pkill -f "pagekite"
pkill -f "serveo"
```

---

# UPDATE

Update ke versi terbaru dari GitHub:

```bash
cd amprem-web
git pull origin main
npm install
```

---

# TROUBLESHOOTING

## npm install error

```bash
# Hapus node_modules dan coba lagi
rm -rf node_modules package-lock.json
npm install
```

## Port sudah dipakai

```bash
# Cari PID yang pakai port
lsof -i :3000

# Kill process tersebut
kill -9 <PID>

# Atau pakai port lain
PORT=8080 node server.js
```

## Server tidak bisa diakses dari luar

### Termux:
- Pastikan pilih cara deployment yang benar (WiFi/Ngrok/Cloudflare)
- Cek apakah HP masih terhubung ke WiFi
- Kalau pakai IP lokal, pastikan HP lain di WiFi yang sama

### VPS:
- Cek firewall:
  ```bash
  sudo ufw status
  sudo ufw allow 80
  sudo ufw allow 443
  ```
- Cek apakah server jalan:
  ```bash
  ps aux | grep node
  curl http://localhost:3000
  ```
- Cek port:
  ```bash
  ss -tlnp | grep 3000
  ```

## Ngrok error "Your authtoken is invalid"

- Login ke https://dashboard.ngrok.com
- Copy authtoken yang baru
- Jalankan ulang setup, masukkan token yang baru

## Cloudflare Tunnel gagal

- Pastikan sudah login ke Cloudflare:
  ```bash
  cloudflared tunnel login
  ```
- Pastikan domain sudah di-manage di Cloudflare
- Cek DNS propagation:
  ```bash
  dig namadomain.com
  ```

## DNS belum propagasi

```bash
# Cek DNS domain
dig +short namadomain.com

# Atau
nslookup namadomain.com

# Cek propagasi global
curl https://dns.google/resolve?name=namadomain.com&type=A
```

DNS biasanya propagasi 1-24 jam.

## Termux: Permission denied saat install

```bash
termux-setup-storage
# Pilih Allow
```

## VPS: apt command not found

```bash
# CentOS/RHEL
yum update
yum install git nodejs npm
```

## Cloudflare Quick URL tidak muncul

```bash
# Cek log
cat /tmp/amprem-tunnel.log

# Tunggu 10 detik lagi, lalu cek
grep trycloudflare /tmp/amprem-tunnel.log
```

## LocalTunnel / Pagekite / Serveo URL tidak muncul

```bash
# Cek log tunnel masing-masing
cat /tmp/amprem-lt.log
cat /tmp/amprem-pk.log
cat /tmp/amprem-serveo.log
```

## VPS: SSL certbot gagal

```bash
# Cek DNS sudah benar
dig +short namadomain.com

# Pastikan port 80 & 443 terbuka
sudo ufw allow 80
sudo ufw allow 443

# Install certbot manual
sudo apt install -y certbot python3-certbot-nginx

# Jalankan manual
sudo certbot --nginx -d namadomain.com --dry-run
```

---

# PERINTAH CEPAT (CHEATSHEET)

```bash
# Clone & install
git clone https://github.com/yowbxz/amprem-web.git && cd amprem-web && npm install

# Jalankan setup
bash setup.sh

# Edit config
nano config.js

# Jalankan server
node server.js

# Port lain
PORT=8080 node server.js

# Cek log
cat /tmp/amprem.log

# Stop
pkill -f "node server"

# Update
git pull && npm install
```

---

# FILE UTAMA

```
setup.sh           - Script setup & management (pakai ini)
config.sh          - Edit config via CLI
config.js          - Konfigurasi API key
server.js          - Backend Express
package.json       - npm dependencies
public/            - Frontend (HTML/CSS/JS)
```

---

# RINGKASAN DEPLOYMENT

```
TERMUX (HP ANDROID)
├── Localhost           → localhost:8080
├── WiFi Lokal         → IP_HP:8080
├── Ngrok              → URL internet (butuh akun)
├── CF Quick          → *.trycloudflare.com (gratis)
├── CF Named          → domain.com (butuh domain)
├── LocalTunnel       → *.l.tunnel.cloud.l.google.com (gratis)
├── Pagekite          → *.pagekite.me (butuh akun)
├── Serveo           → subdomain.serveo.net (gratis)
└── Domain + CF Proxy → domain.com

VPS (SERVER LINUX)
├── IP + Nginx        → http://IP_VPS
├── Domain + SSL      → https://domain.com (LE)
├── Domain + CF       → https://domain.com (CF tunnel)
├── Ngrok             → URL internet (butuh akun)
├── CF Quick         → *.trycloudflare.com (gratis)
├── CF Named         → domain.com (butuh domain)
├── LocalTunnel      → URL internet (gratis)
└── Serveo          → subdomain.serveo.net (gratis)
```

---

Repo: **https://github.com/yowbxz/amprem-web**

---

## Login pengguna

Semua halaman web pengguna membutuhkan username dan password yang dibuat dari proyek admin terpisah. Gunakan project Supabase yang sama pada kedua web.

Untuk deployment Vercel, isi `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, dan `SUPABASE_SERVICE_ROLE_KEY` melalui Environment Variables Vercel; jangan pernah memasukkan nilai rahasia ke repository.
