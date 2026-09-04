# Amprem Web

Website Alight Motion Premium - 7 varian aktivasi premium.

---

# CARA INSTALL (GAMPANG)

## 1. Clone Repo

**Termux (HP Android):**
```bash
pkg update && pkg install git -y
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
```

**VPS (Ubuntu/Debian):**
```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
```

## 2. Jalankan Setup

```bash
bash setup.sh
```

Selesai! Script otomatis install semua yang dibutuhkan dan tanya mau pakai cara akses yang mana.

---

# YANG DILAKUKAN SCRIPT

```
1. Install dependencies    - Node.js, Git, nano, cloudflared (otomatis)
2. Install project        - npm install (otomatis)
3. Edit config           - Buka nano untuk atur API key
4. Pilih deployment       - Pilih cara akses
5. Jalankan server       - Done!
```

---

# PILIHAN DEPLOYMENT

## Termux (HP Android)

| No | Cara | Hasil | Kebutuhan |
|----|------|-------|-----------|
| 1 | WiFi Lokal | `http://IP_HP:8080` | HP lain di WiFi sama |
| 2 | Cloudflare Quick | URL `*.trycloudflare.com` | Semua orang (URL berubah tiap restart) |
| 3 | Domain | `https://domain.com` | Domain di Cloudflare |

## VPS (Ubuntu/Debian)

| No | Cara | Hasil | Kebutuhan |
|----|------|-------|-----------|
| 1 | IP Only | `http://IP_VPS` | IP publik VPS |
| 2 | Domain + SSL | `https://domain.com` | Domain + Certbot |
| 3 | Cloudflare Quick | URL `*.trycloudflare.com` | Semua orang (URL berubah) |
| 4 | Domain + Cloudflare | `https://domain.com` | Domain di Cloudflare |

---

# EDIT CONFIG

Buka `config.js` untuk atur API key:

```bash
nano config.js
```

Atau lewat script:
```bash
bash config.sh
```

Isi yang penting:
- **amprem2ApiKey** - WAJIB isi kalau pakai Amprem2. Daftar di `api.haidarxd.my.id`
- **amprem6ApiKey** - Sudah ada default (komunitas). Ganti kalau mau punya sendiri di `free-restapi.biz.id`

---

# PERINTAH PENTING

```bash
# Jalankan server
node server.js

# Ganti port
PORT=8080 node server.js

# Lihat log
cat /tmp/amprem.log

# Stop server
pkill -f "node server"

# Update ke versi terbaru
git pull origin main && npm install
```

---

# FILE UTAMA

```
setup.sh              - SATU script install + setup (pakai ini)
config.sh             - Edit config via CLI
config.js             - Konfigurasi API key
server.js             - Backend Express
public/               - Frontend (HTML/CSS/JS)
```

---

# TROUBLESHOOTING

**Port sudah dipakai:**
```bash
lsof -i :3000
kill -9 <PID>
```

**npm install error:**
```bash
rm -rf node_modules package-lock.json
npm install
```

**VPS: Port tidak bisa diakses:**
```bash
sudo ufw allow 80
sudo ufw allow 443
```

---

Repo: https://github.com/yowbxz/amprem-web
