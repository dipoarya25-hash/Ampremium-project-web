#!/bin/bash
# ============================================================
# Setup Amprem Web di VPS dengan Domain + SSL
# VPS: Ubuntu / Debian
# Hasil: https://domain.com
# Jalankan sebagai root: sudo bash setup-vps-domain.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
    fail "Jalankan pakai sudo: sudo bash setup-vps-domain.sh"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGINX_CONF="/etc/nginx/sites-available/amprem"
NGINX_LINK="/etc/nginx/sites-enabled/amprem"

# ============================================================
#  Tanya domain
# ============================================================
echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  VPS + Domain Setup${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
read -rp "Masukkan domain (contoh: amprem.example.com): " DOMAIN
DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
[ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

# ============================================================
#  Install Node.js
# ============================================================
echo ""
info "1/6 - Install Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || {
    warn "Cara pertama gagal, coba cara lain..."
    apt update -qq
    apt install -y nodejs npm
}
ok "Node.js: $(node -v)"

# ============================================================
#  Install Nginx
# ============================================================
echo ""
info "2/6 - Install Nginx..."
if command -v nginx &>/dev/null; then
    ok "Nginx sudah terinstall"
else
    apt update -qq && apt install -y nginx nano
    ok "Nginx terinstall"
fi

# ============================================================
#  Setup direktori Nginx
# ============================================================
if [ ! -d "/etc/nginx/sites-available" ]; then
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    sed -i '/http\s*{/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
fi

# ============================================================
#  Install project
# ============================================================
echo ""
info "3/6 - Install project..."
cd "$SCRIPT_DIR"
npm install --silent 2>/dev/null || npm install
ok "npm dependencies terinstall"

# ============================================================
#  Edit config (nano)
# ============================================================
echo ""
info "4/6 - Konfigurasi API Key..."
echo "  File: $SCRIPT_DIR/config.js"
echo "  amprem6ApiKey : komunitas (bisa ganti)"
echo "  amprem2ApiKey : WAJIB ISI kalau mau pakai Amprem2"
echo ""
read -rp "  Buka nano untuk edit config.js? [y/N]: " DO_EDIT
if [[ "$DO_EDIT" =~ ^[Yy]$ ]]; then
    nano "$SCRIPT_DIR/config.js"
fi

# ============================================================
#  Nginx config + SSL
# ============================================================
echo ""
info "5/6 - Setup Nginx + SSL..."

cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 30s;
        proxy_read_timeout 60s;
        proxy_send_timeout 30s;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf "$NGINX_CONF" "$NGINX_LINK"
nginx -t || fail "Nginx config error"
systemctl enable nginx
systemctl restart nginx
ok "Nginx aktif"

# ============================================================
#  SSL
# ============================================================
echo ""
info "6/6 - Setup SSL (Let's Encrypt)..."

# Cek DNS
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "")
DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null | head -1)

if [ -n "$DOMAIN_IP" ] && [ "$DOMAIN_IP" = "$PUBLIC_IP" ]; then
    ok "DNS ${DOMAIN} sudah pointing ke IP ini (${PUBLIC_IP})"

    echo ""
    read -rp "Pasang SSL sekarang? [Y/n]: " DO_SSL
    if [[ ! "$DO_SSL" =~ ^[Nn]$ ]]; then
        apt install -y certbot python3-certbot-nginx
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos \
            --register-unsafely-without-email --redirect

        # Auto-renew
        systemctl enable --now certbot-renew.timer 2>/dev/null || true
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | sort -u | crontab -
        ok "SSL aktif dan auto-renew sudah diatur."
    fi
else
    warn "DNS belum siap. Domain tidak resolve ke IP VPS ini."
    warn "Pastikan A record ${DOMAIN} -> ${PUBLIC_IP}"
    warn "SSL bisa dipasang manual nanti: sudo certbot --nginx -d ${DOMAIN}"
fi

# ============================================================
#  Jalankan server
# ============================================================
echo ""
info "Menjalankan server..."

# Cek apakah sudah ada process lama
if pgrep -f "node server.js" > /dev/null; then
    info "Menghentikan server lama..."
    pkill -f "node server.js"
    sleep 1
fi

cd "$SCRIPT_DIR"
nohup node server.js > /tmp/amprem.log 2>&1 &
sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ | grep -q "200"; then
    ok "Server jalan!"
else
    warn "Server mungkin belum sepenuhnya jalan, tunggu sebentar..."
    sleep 3
fi

# ============================================================
#  Done
# ============================================================
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  SELESAI!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "  Domain  : https://${DOMAIN}"
echo "  Lokal   : http://localhost:3000"
echo ""
echo "  Manage server:"
echo "    cat /tmp/amprem.log      # lihat log"
echo "    pkill -f 'node server'   # stop server"
echo "    cd $SCRIPT_DIR && node server.js  # start ulang"
echo ""
echo "  Edit config:"
echo "    nano $SCRIPT_DIR/config.js"
echo ""
echo "  Kalau belum bisa diakses, cek firewall:"
echo "    sudo ufw allow 80 && sudo ufw allow 443"
echo ""
echo -e "${GREEN}=========================================${NC}"
