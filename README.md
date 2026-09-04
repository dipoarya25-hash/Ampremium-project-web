# Amprem Web

Website Alight Motion Premium - 7 varian aktivasi premium.

---

# CARA INSTALL (GAMPANG)

```bash
git clone https://github.com/yowbxz/amprem-web.git
cd amprem-web
bash setup.sh
```

Selesai. Tinggal pilih menu nya.

---

# MENU SETUP.SH

Jalankan `bash setup.sh`, lalu pilih menu:

## Menu Utama

```
  I) Install         - Install dependencies (Node.js, Git, dll)
  P) Project        - Install npm
  D) Deployment    - Pilih cara akses internet
  C) Cek Status    - Lihat service yang jalan
  R) Restart       - Restart server
  X) Stop Semua   - Hentikan semua service
  E) Edit Config  - Edit config.js
```

---

# OPSI DEPLOYMENT

## Termux (HP Android)

| No | Cara | Hasil | Kebutuhan |
|----|------|-------|-----------|
| 1 | Localhost | `http://localhost:8080` | HP ini aja |
| 2 | WiFi Lokal | `http://IP_HP:8080` | HP/laptop di WiFi sama |
| 3 | Ngrok | URL internet | Akun ngrok.com |
| 4 | Cloudflare Quick | URL `*.trycloudflare.com` | Gratis |
| 5 | Cloudflare Named | `https://domain.com` | Domain + Cloudflare |
| 6 | LocalTunnel | URL `*.l.tunnel.cloud.l.google.com` | Gratis |
| 7 | Pagekite | URL `*.pagekite.me` | Akun pagekite.net |
| 8 | Serveo | URL `subdomain.serveo.net` | Gratis via SSH |
| 9 | Domain + CF Proxy | `https://domain.com` | Domain + CF Proxy |

## VPS (Ubuntu/Debian)

| No | Cara | Hasil | Kebutuhan |
|----|------|-------|-----------|
| 1 | IP + Nginx | `http://IP_VPS` | IP publik |
| 2 | Domain + Nginx + SSL | `https://domain.com` | Domain + Certbot |
| 3 | Domain + Cloudflare | `https://domain.com` | Domain + Cloudflare |
| 4 | Ngrok | URL internet | Akun ngrok.com |
| 5 | Cloudflare Quick | URL `*.trycloudflare.com` | Gratis |
| 6 | Cloudflare Named | `https://domain.com` | Domain + Cloudflare |
| 7 | LocalTunnel | URL `*.l.tunnel.cloud.l.google.com` | Gratis |
| 8 | Serveo | URL `subdomain.serveo.net` | Gratis via SSH |

---

# TUNNEL DETAIL

### Ngrok
- URL internet, tapi butuh akun di https://ngrok.com
- URL stabil (tidak berubah)
- Gratis untuk 1 tunnel
- Butuh authtoken dari dashboard ngrok

### Cloudflare Quick Tunnel
- URL `*.trycloudflare.com`
- **Gratis tanpa akun**
- URL berubah setiap kali restart tunnel
- SSL otomatis

### Cloudflare Named Tunnel
- URL `https://domain.com` sendiri
- **Permanen** (tidak berubah)
- SSL otomatis dari Cloudflare
- Butuh domain yang di-manage di Cloudflare

### LocalTunnel
- URL `*.l.tunnel.cloud.l.google.com`
- **Gratis tanpa akun**
- URL berubah setiap sesi
- Cukup stabil

### Pagekite
- URL `*.pagekite.me`
- Gratis dengan akun
- SSL support
- Daftar di https://pagekite.net

### Serveo
- URL `subdomain.serveo.net`
- **Gratis tanpa akun**
- Via reverse SSH tunnel
- URL stabil jika pakai subdomain tetap
- Contoh: `serveo.net` subdomain `amprem` -> `amprem.serveo.net`

---

# EDIT CONFIG

```bash
# Opsi 1: nano
nano config.js

# Opsi 2: script interaktif
bash config.sh

# Opsi 3: sed (langsung ganti)
sed -i "s/amprem2ApiKey: '.*'/amprem2ApiKey: 'KEY_BARU'/" config.js
```

---

# PERINTAH PENTING

```bash
# Jalankan server (port default 3000)
node server.js

# Port lain
PORT=8080 node server.js

# Cek log
cat /tmp/amprem.log

# Stop
pkill -f "node server"

# Update
git pull origin main && npm install
```

---

# FILE UTAMA

```
setup.sh           - SATU script install + manage (pakai ini)
config.sh          - Edit config via CLI
config.js          - Konfigurasi API key
server.js          - Backend
public/            - Frontend
```

---

# API KEY

Buka `config.js`:

```js
amprem6ApiKey: 'SK-5A6D0C0FB6D7B35A71B9A70F'
// komunitas, ganti kalau mau di free-restapi.biz.id

amprem2ApiKey: ''
// WAJIB isi kalau pakai Amprem2
// Daftar di api.haidarxd.my.id
```

---

Repo: https://github.com/yowbxz/amprem-web
