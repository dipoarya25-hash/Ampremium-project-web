# Amprem Web

Website Alight Motion Premium - 7 varian aktivasi, masing-masing halaman terpisah.

## File Penting

| File | Fungsi |
|------|---------|
| `server.js` | Backend Express |
| `config.js` | Konfigurasi API key |
| `setup-vps-domain.sh` | Setup VPS + Domain (auto install semua) |
| `setup-termux-domain.sh` | Setup Termux + Domain (auto install semua) |
| `setup-nginx.sh` | Setup VPS (semua opsi) |
| `setup-termux.sh` | Setup Termux (semua opsi) |
| `config.sh` | Edit config via CLI |

---

# CARA INSTALL - PILIH SALAH SATU

## VPS + DOMAIN (Auto Setup)

### Langkah 1: Siapkan VPS

Gunakan VPS (Ubuntu 20/22) dari provider seperti:
- DigitalOcean
- Vultr
- Linode
- Hetzner
- AWS EC2
- dll

Buka ports: **80** dan **443** di firewall/panel VPS.

### Langkah 2: Clone & Jalankan

```bash
# SSH ke VPS, lalu:

# 1. Install git
sudo apt update && sudo apt install -y git

# 2. Clone repo
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web

# 3. Jalankan auto setup
sudo bash setup-vps-domain.sh
```

### Langkah 3: Masukkan Domain

```
Masukkan domain (contoh: amprem.example.com): amprem.example.com
```

### Langkah 4: Edit Config

Script akan buka `nano` untuk edit `config.js`:

```
amprem6ApiKey : 'SK-5A6D0C0FB6D7B35A71B9A70F'   <- komunitas (ganti kalau mau)
amprem2ApiKey : ''                                  <- WAJIB ISI kalau pakai Amprem2
```

- `amprem2ApiKey`: daftar di https://api.haidarxd.my.id untuk dapat key
- Tekan **Ctrl+O** -> **Enter** -> **Ctrl+X** untuk save & exit nano

### Langkah 5: Setup SSL

```
Pasang SSL sekarang? [Y/n]: Y
```

Kalau DNS sudah pointing ke IP VPS, SSL otomatis terinstall.

### Langkah 6: Selesai

```
SELESAI!
  Domain  : https://amprem.example.com
  Lokal   : http://localhost:3000
```

---

## TERMUX (HP ANDROID) + DOMAIN (Auto Setup)

### Langkah 1: Install Termux

1. Download **Termux** dari **F-Droid** (bukan Play Store!)
   - Play Store versi Termux sudah tidak diupdate dan tidak work
   - Download: https://f-droid.org/en/packages/com.termux/

2. Buka Termux

### Langkah 2: Update Package

```bash
pkg update && pkg upgrade -y
```

### Langkah 3: Install Git

```bash
pkg install git -y
```

### Langkah 4: Clone Repo

```bash
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
```

### Langkah 5: Jalankan Auto Setup

```bash
bash setup-termux-domain.sh
```

### Langkah 6: Masukkan Domain

```
Masukkan domain (contoh: amprem.example.com): amprem.example.com
```

### Langkah 7: Login Cloudflare

- Browser akan terbuka
- Login ke Cloudflare
- Pilih domain yang mau dipakai
- Kembali ke Termux, tekan **ENTER**

### Langkah 8: Edit Config

Script akan buka `nano`:

```
amprem6ApiKey : 'SK-5A6D0C0FB6D7B35A71B9A70F'   <- komunitas
amprem2ApiKey : ''                                  <- WAJIB ISI kalau pakai Amprem2
```

- Tekan **Ctrl+O** -> **Enter** -> **Ctrl+X** untuk save & exit

### Langkah 9: Selesai

```
SELESAI!
  Domain  : https://amprem.example.com
  Lokal   : http://localhost:8080
```

---

## VPS - TANPA DOMAIN (IP Only)

### Langkah 1: Install di VPS

```bash
# SSH ke VPS
sudo apt update && sudo apt install -y git nodejs npm nginx

# Clone
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
npm install

# Edit config
nano config.js

# Jalankan
npm start
```

### Langkah 2: Buka Port

```bash
sudo ufw allow 80
sudo ufw allow 3000
```

### Langkah 3: Akses

Buka browser: `http://IP_VPS_KAMU`

---

## TERMUX - TANPA DOMAIN (Lokal/WiFi)

### Langkah 1: Install di Termux

```bash
# Update
pkg update && pkg upgrade -y

# Install
pkg install nodejs git -y

# Clone
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
npm install

# Edit config
nano config.js

# Jalankan
npm start
```

### Langkah 2: Akses

```
Lokal      : http://localhost:3000     (di HP sendiri)
WiFi       : http://IP_HP:3000        (dari HP/laptop lain, 1 WiFi)
```

Cek IP HP:
```bash
ifconfig | grep inet
```

---

# EDIT CONFIG

## Via Nano (Editor)

```bash
nano config.js
```

## Via Script Interaktif

```bash
bash config.sh
```

## Via Sed (Langsung)

```bash
# Ganti amprem6ApiKey:
sed -i "s/amprem6ApiKey: '.*'/amprem6ApiKey: 'SK-BARU'/" config.js

# Ganti amprem2ApiKey:
sed -i "s/amprem2ApiKey: '.*'/amprem2ApiKey: 'KEY_BARU'/" config.js
```

---

# KONFIGURASI API KEY

Buka `config.js`:

```js
amprem6ApiKey: 'SK-5A6D0C0FB6D7B35A71B9A70F'
// ^ API key komunitas (gratisan). Bisa kena limit.
//   Daftar sendiri: free-restapi.biz.id/users/register

amprem2ApiKey: ''
// ^ WAJIB ISI kalau mau pakai Amprem2.
//   Daftar di: api.haidarxd.my.id
```

**Varian lain tidak butuh config tambahan** - langsung jalan.

---

# UPDATE KE VERSI TERBARU

```bash
cd amprem-web
git pull origin main
npm install
```

---

# TROUBLESHOOTING

### "Port 3000 sudah dipakai"

```bash
# Cari process
lsof -i :3000

# Kill
kill -9 <PID>

# Atau pakai port lain
PORT=8080 npm start
```

### VPS: "apt: command not found"

```bash
# CentOS/RHEL
yum update
yum install -y git nodejs npm nginx

# Atau pakai NodeSource:
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
yum install -y nodejs
```

### Termux: "Permission denied"

```bash
termux-setup-storage
# Pilih Allow
```

### VPS: "SSL gagal install"

Pastikan DNS domain sudah pointing ke IP VPS:
```bash
# Cek IP VPS
curl ifconfig.me

# Cek DNS domain
dig +short namadomain.com
```

### Server tidak jalan

```bash
# Cek log
cat /tmp/amprem.log        # VPS
cat /tmp/amprem-termux.log # Termux

# Restart
cd amprem-web && node server.js
```

### Termux: "cloudflared: command not found"

```bash
pkg install cloudflared -y
```

---

# RINGKASAN COMMAND

## Termux

```bash
# Install semua dari awal
pkg update && pkg upgrade -y
pkg install git nodejs -y
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
npm install

# Domain auto setup
bash setup-termux-domain.sh

# Edit config
nano config.js

# Jalanin
npm start
PORT=8080 npm start
```

## VPS

```bash
# Install semua dari awal
sudo apt update && sudo apt install -y git
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs nginx certbot
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
npm install

# Domain auto setup
sudo bash setup-vps-domain.sh

# Edit config
nano config.js

# Jalanin
npm start
PORT=8080 npm start

# Atau pakai PM2 (tahan restart)
npm install -g pm2
pm2 start server.js --name amprem
pm2 save
pm2 startup
```

## GitHub Repo

https://github.com/yowbxz/amprem-web
