# Amprem Web

Website Alight Motion Premium, 6 varian - **setiap varian punya halaman
sendiri-sendiri** (bukan 1 halaman dengan tab/switcher). Project ini
**berdiri sendiri sepenuhnya** - tidak ada hubungan atau dependency ke
bot WhatsApp/Baileys manapun.

## Struktur

```
server.js          # backend Express, proxy ke semua API amprem
config.js          # API key (amprem6ApiKey, amprem2ApiKey)
setup-nginx.sh     # setup akses publik (VPS: Nginx / Cloudflare Tunnel)
setup-termux.sh    # setup akses publik (Termux: WiFi / Cloudflare)
public/
  index.html       # halaman daftar (link ke 7 halaman)
  amprem.html       # varian 1 - alur utama
  amprem2.html      # varian 2 - scraper 1 langkah
  amprem3.html      # varian 3 - alur alternatif
  amprem4.html      # varian 4 - email pribadi
  amprem5.html      # varian 5 - + langkah konfirmasi
  amprem6.html      # varian 6 - backend komunitas
  amprem7.html      # varian 7 - backend theresav.eu
  style.css         # tampilan bersama
  client.js         # helper JS (apiCall, clipboard, renderSuccessCard)
```

Kenapa halamannya terpisah-pisah (bukan 1 halaman)? Supaya tiap varian
punya URL sendiri, gak saling nyampur/nabrak, dan gampang dipahami mana
yang lagi dipakai.

Kenapa masih ada backend (bukan cuma HTML/JS polos)? API pihak ketiga
yang dipakai (dapjimotionpro, haidarxd, free-restapi) kemungkinan besar
gak ngizinin dipanggil langsung dari browser (CORS), dan API key
`amprem6ApiKey` gak boleh keekspos ke siapapun yang buka halamannya -
jadi backend Express ini yang manggil API-nya, browser cuma ngomong ke
backend sendiri.

## Menjalankan

```bash
npm install
npm start
```

Default buka di `http://localhost:3000`. Port bisa diatur lewat
environment variable `PORT` (atau `SERVER_PORT`) kalau hosting-nya
sudah nentuin port sendiri (umum di Pterodactyl/VPS managed).

### VPS

```bash
sudo apt update && sudo apt install -y nodejs npm
git clone <repo-kamu> amprem-web && cd amprem-web
npm install
npm start
# atau pakai pm2 biar tetap jalan setelah logout:
npm install -g pm2
pm2 start server.js --name amprem-web
```

#### Akses dari HP/Laptop lain

Jalankan script setup yang sudah disediakan:

```bash
sudo bash setup-nginx.sh
```

Script akan tanya mau pakai mode apa:

- **Opsi 1 - Tanpa domain** : Nginx reverse proxy, akses via `http://<IP_VPS>`
- **Opsi 2 - Pakai domain** : pilih sambungkan lewat mana:
  - **a) Nginx langsung** : domain A record ke IP VPS, SSL via Let's Encrypt
  - **b) Cloudflare Tunnel** : domain di Cloudflare, tunnel ke server, SSL otomatis (gak perlu buka port)
- **Opsi 3 - Cloudflare Tunnel tanpa domain** : dapat URL gratis
  - **Quick Tunnel** : langsung jalan, dapat `*.trycloudflare.com` (URL berubah tiap restart)
  - **Named Tunnel** : URL permanen via domain di Cloudflare (perlu login + domain)

Setelah itu pastikan Node.js server juga jalan (`npm start` atau `pm2`).

Kalau tidak bisa diakses, pastikan port 80 & 443 terbuka di firewall VPS:
```bash
sudo ufw allow 80 && sudo ufw allow 443                                        # Ubuntu/Debian
sudo firewall-cmd --add-port={80,443}/tcp --permanent && sudo firewall-cmd --reload  # CentOS
```

### Pterodactyl

1. Buat server baru dengan egg **Node.js Generic** (versi 18+).
2. Upload semua file project ini.
3. Startup Command: `node server.js`.
4. Start server - panel biasanya nyediain env var `SERVER_PORT`, kode
   ini udah baca itu otomatis.

### Termux

Termux tidak punya Nginx/systemd, jadi ada script khusus:

```bash
pkg install nodejs
cd amprem-web
npm install
bash setup-termux.sh
```

Script `setup-termux.sh` akan tanya mau pakai mode apa:

- **1) Lokal saja** - akses dari HP ini di `http://localhost:8080`
- **2) WiFi lokal** - akses dari perangkat lain di WiFi yang sama via IP lokal
- **3) Cloudflare Quick Tunnel** - akses dari internet, URL `*.trycloudflare.com`
- **4) Cloudflare Named Tunnel** - URL permanen via domain di Cloudflare

> Di Termux default port-nya 8080 (bukan 3000) karena beberapa
> perangkat Android blokir port di bawah 1024 dan port 3000 kadang
> conflict. Bisa diubah lewat env var `PORT`.

## Konfigurasi

2 nilai di `config.js`:

```js
amprem6ApiKey: 'SK-...'   // API key komunitas buat varian Amprem6
amprem2ApiKey: ''          // API key buat varian Amprem2 (wajib diisi)
```

- **amprem6ApiKey** - API key **komunitas** (dibagi bareng) buat Amprem6.
  Kalau kena limit, daftar gratis di `free-restapi.biz.id/users/register`.
- **amprem2ApiKey** - API key dari `api.haidarxd.my.id`. Wajib diisi
  supaya Amprem2 bisa jalan. Daftar di situs tersebut untuk dapat key.

Varian lain (Amprem, Amprem3, Amprem4, Amprem5, Amprem7) gak butuh
konfigurasi apapun - langsung jalan begitu `npm start`.
