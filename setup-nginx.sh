#!/bin/bash
# ============================================================
# Setup akses publik untuk Amprem Web
# 3 opsi:
#   1) Tanpa domain  - Nginx reverse proxy, akses via IP
#   2) Pakai domain  - Nginx + SSL (Let's Encrypt)
#   3) Cloudflare Tunnel - tanpa domain sendiri, dapat URL gratis
# Jalankan sebagai root: sudo bash setup-nginx.sh
# ============================================================

set -e

APP_PORT=3000
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGINX_CONF="/etc/nginx/sites-available/amprem"
NGINX_LINK="/etc/nginx/sites-enabled/amprem"

# ---------- Warna ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- Cek root ----------
if [ "$EUID" -ne 0 ]; then
    fail "Jalankan pakai sudo: sudo bash setup-nginx.sh"
fi

# ============================================================
#  NGINX FUNCTIONS
# ============================================================

install_nginx() {
    if command -v nginx &>/dev/null; then
        ok "Nginx sudah terinstall: $(nginx -v 2>&1)"
    else
        info "Install Nginx..."
        if command -v apt &>/dev/null; then
            apt update -qq && apt install -y -qq nginx nano
        elif command -v yum &>/dev/null; then
            yum install -y nginx nano
        elif command -v dnf &>/dev/null; then
            dnf install -y nginx nano
        elif command -v pacman &>/dev/null; then
            pacman -Sy --noconfirm nginx nano
        else
            fail "Package manager tidak dikenali. Install nginx manual dulu."
        fi
        ok "Nginx terinstall."
    fi
}

setup_sites_dir() {
    if [ ! -d "/etc/nginx/sites-available" ]; then
        mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
        if ! grep -q "sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
            sed -i '/http\s*{/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
        fi
    fi
}

gen_config_ip() {
    cat > "$NGINX_CONF" <<'CONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 30s;
        proxy_read_timeout 60s;
        proxy_send_timeout 30s;
    }
}
CONF
}

gen_config_domain() {
    local domain="$1"
    cat > "$NGINX_CONF" <<CONF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};

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
CONF
}

setup_ssl() {
    local domain="$1"

    info "Install Certbot untuk SSL gratis (Let's Encrypt)..."
    if command -v apt &>/dev/null; then
        apt install -y -qq certbot python3-certbot-nginx
    elif command -v yum &>/dev/null; then
        yum install -y certbot python3-certbot-nginx
    elif command -v dnf &>/dev/null; then
        dnf install -y certbot python3-certbot-nginx
    else
        warn "Certbot tidak bisa diinstall otomatis. Install manual:"
        warn "  https://certbot.eff.org/"
        return 1
    fi

    info "Request sertifikat SSL untuk ${domain}..."
    certbot --nginx -d "$domain" --non-interactive --agree-tos \
        --register-unsafely-without-email --redirect

    if [ $? -eq 0 ]; then
        ok "SSL aktif! Situs bisa diakses via https://${domain}"
        # Setup auto-renew
        if command -v systemctl &>/dev/null; then
            systemctl enable --now certbot-renew.timer 2>/dev/null || true
        fi
        if ! systemctl is-active certbot-renew.timer &>/dev/null 2>&1; then
            (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | sort -u | crontab -
            ok "Auto-renew SSL via cron (jam 3 pagi tiap hari)."
        fi
    else
        warn "SSL gagal. Kemungkinan domain belum diarahkan ke IP VPS ini."
        warn "Situs tetap bisa diakses via http://${domain} (tanpa SSL)."
        return 1
    fi
}

activate_nginx() {
    rm -f /etc/nginx/sites-enabled/default
    ln -sf "$NGINX_CONF" "$NGINX_LINK"

    info "Test config Nginx..."
    nginx -t || fail "Config Nginx error! Cek /etc/nginx/sites-available/amprem"

    systemctl enable nginx
    systemctl restart nginx
    ok "Nginx aktif dan jalan."
}

check_domain_dns() {
    local domain="$1"
    local public_ip
    public_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 ipinfo.io/ip 2>/dev/null || echo "")

    if [ -z "$public_ip" ]; then
        warn "Tidak bisa deteksi IP publik VPS."
        return 0
    fi

    local domain_ip
    domain_ip=$(dig +short "$domain" 2>/dev/null | head -1)

    if [ -z "$domain_ip" ]; then
        warn "Domain ${domain} belum resolve ke IP manapun."
        warn "Pastikan DNS A record sudah diarahkan ke: ${public_ip}"
        return 1
    elif [ "$domain_ip" != "$public_ip" ]; then
        warn "Domain ${domain} resolve ke ${domain_ip}, tapi IP VPS ini: ${public_ip}"
        warn "Pastikan DNS A record diarahkan ke: ${public_ip}"
        return 1
    else
        ok "Domain ${domain} sudah mengarah ke IP VPS ini (${public_ip})."
        return 0
    fi
}

# ============================================================
#  CLOUDFLARE TUNNEL FUNCTIONS
# ============================================================

install_cloudflared() {
    if command -v cloudflared &>/dev/null; then
        ok "cloudflared sudah terinstall: $(cloudflared --version 2>&1 | head -1)"
        return 0
    fi

    info "Install cloudflared..."
    local ARCH
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        armv7l|armhf)  ARCH="arm" ;;
        *) fail "Arsitektur ${ARCH} tidak didukung cloudflared." ;;
    esac

    local URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"

    if command -v apt &>/dev/null; then
        # Coba via .deb dulu (lebih bersih)
        local DEB_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb"
        curl -sL "$DEB_URL" -o /tmp/cloudflared.deb && dpkg -i /tmp/cloudflared.deb && rm -f /tmp/cloudflared.deb && return 0
    fi

    # Fallback: download binary langsung
    curl -sL "$URL" -o /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared

    if ! cloudflared --version &>/dev/null; then
        fail "cloudflared gagal diinstall. Coba install manual: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
    fi
    ok "cloudflared terinstall."
}

setup_cloudflare_quick() {
    # Mode cepat: tanpa login, dapat URL random *.trycloudflare.com
    info "Menjalankan Cloudflare Quick Tunnel..."
    info "Kamu akan mendapat URL publik gratis (*.trycloudflare.com)"
    warn "URL ini BERUBAH setiap kali tunnel di-restart."
    warn "Untuk URL permanen, pakai opsi 2 (domain) atau login cloudflared."
    echo ""

    # Buat systemd service
    cat > /etc/systemd/system/cloudflared-quick.service <<EOF
[Unit]
Description=Cloudflare Quick Tunnel untuk Amprem Web
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$(command -v cloudflared) tunnel --url http://localhost:${APP_PORT} --no-autoupdate
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable cloudflared-quick
    systemctl restart cloudflared-quick

    ok "Cloudflare Quick Tunnel service aktif."
    echo ""
    info "Tunggu beberapa detik, lalu cek URL dengan:"
    echo "    journalctl -u cloudflared-quick --no-pager -n 20"
    echo ""
    info "Atau jalankan manual untuk lihat URL langsung:"
    echo "    cloudflared tunnel --url http://localhost:${APP_PORT}"
    echo ""

    # Tunggu dan coba ambil URL dari log
    sleep 5
    local TUNNEL_URL
    TUNNEL_URL=$(journalctl -u cloudflared-quick --no-pager -n 30 2>/dev/null | grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1)

    if [ -n "$TUNNEL_URL" ]; then
        echo ""
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}  URL PUBLIK KAMU:${NC}"
        echo -e "${GREEN}  ${TUNNEL_URL}${NC}"
        echo -e "${GREEN}=========================================${NC}"
    else
        warn "URL belum muncul di log. Tunggu sebentar lalu cek manual:"
        echo "    journalctl -u cloudflared-quick -f"
    fi
}

setup_cloudflare_named() {
    # Mode permanen: login ke Cloudflare, buat named tunnel
    local tunnel_name="amprem-web"

    info "Mode Cloudflare Tunnel permanen (dengan login)."
    echo ""
    echo "  Kamu perlu:"
    echo "  1. Punya akun Cloudflare (gratis)"
    echo "  2. Domain yang sudah di-manage di Cloudflare DNS"
    echo ""
    read -rp "Lanjut login ke Cloudflare? [y/N]: " DO_LOGIN
    if [[ ! "$DO_LOGIN" =~ ^[Yy]$ ]]; then
        warn "Dibatalkan."
        return 1
    fi

    info "Buka browser dan login..."
    cloudflared tunnel login

    echo ""
    read -rp "Masukkan subdomain untuk tunnel (contoh: amprem.domain.com): " CF_DOMAIN
    CF_DOMAIN=$(echo "$CF_DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    if [ -z "$CF_DOMAIN" ]; then
        fail "Domain tidak boleh kosong."
    fi

    _create_named_tunnel "$tunnel_name" "$CF_DOMAIN"
}

# Fungsi dipanggil dari opsi 2b (domain sudah diketahui)
setup_cloudflare_named_with_domain() {
    local domain="$1"
    local tunnel_name="amprem-web"

    info "Mode: Domain via Cloudflare Tunnel (${domain})"
    echo ""
    echo "  Kamu perlu:"
    echo "  1. Punya akun Cloudflare (gratis)"
    echo "  2. Domain '${domain}' sudah di-manage di Cloudflare DNS"
    echo ""
    read -rp "Lanjut login ke Cloudflare? [y/N]: " DO_LOGIN
    if [[ ! "$DO_LOGIN" =~ ^[Yy]$ ]]; then
        warn "Dibatalkan."
        return 1
    fi

    info "Buka browser dan login..."
    cloudflared tunnel login

    _create_named_tunnel "$tunnel_name" "$domain"
}

# Internal: buat named tunnel + DNS route + systemd service
_create_named_tunnel() {
    local tunnel_name="$1"
    local cf_domain="$2"

    info "Buat tunnel '${tunnel_name}'..."
    # Hapus tunnel lama kalau ada
    cloudflared tunnel delete "$tunnel_name" 2>/dev/null || true
    cloudflared tunnel create "$tunnel_name"

    # Ambil tunnel ID
    local TUNNEL_ID
    TUNNEL_ID=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')
    if [ -z "$TUNNEL_ID" ]; then
        fail "Gagal membuat tunnel."
    fi

    # Buat config file
    local CF_CONFIG="/etc/cloudflared/config.yml"
    mkdir -p /etc/cloudflared
    cat > "$CF_CONFIG" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: /root/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${cf_domain}
    service: http://localhost:${APP_PORT}
  - service: http_status:404
EOF

    info "Setup DNS record untuk ${cf_domain}..."
    cloudflared tunnel route dns "$tunnel_name" "$cf_domain"

    # Install sebagai service
    cloudflared service install 2>/dev/null || true
    systemctl enable cloudflared
    systemctl restart cloudflared

    ok "Cloudflare Tunnel permanen aktif!"
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}  URL PERMANEN:${NC}"
    echo -e "${GREEN}  https://${cf_domain}${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "  SSL otomatis dari Cloudflare (gak perlu Certbot)."
    echo "  Tunnel jalan sebagai service, auto-start saat boot."
}

# ============================================================
#  MAIN
# ============================================================

# ---------- Edit config dulu ----------
CONFIG_FILE="$SCRIPT_DIR/config.js"
if [ -f "$CONFIG_FILE" ]; then
    AMPREM6=$(grep "amprem6ApiKey:" "$CONFIG_FILE" 2>/dev/null | sed "s/.*'\([^']*\)'.*/\1/" | head -c 15)
    AMPREM2=$(grep "amprem2ApiKey:" "$CONFIG_FILE" 2>/dev/null | sed "s/.*'\([^']*\)'.*/\1/")

    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  Konfigurasi API Key${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    echo "  amprem6ApiKey : ${AMPREM6:-<tidak diatur>}..."
    echo "  amprem2ApiKey : ${AMPREM2:-<kosong - wajib diisi kalau pakai Amprem2>}"
    echo ""
    read -rp "  Edit config sekarang? [y/N]: " DO_CONFIG
    if [[ "$DO_CONFIG" =~ ^[Yy]$ ]]; then
        if command -v nano &>/dev/null; then
            nano "$CONFIG_FILE"
        elif command -v vim &>/dev/null; then
            vim "$CONFIG_FILE"
        elif command -v vi &>/dev/null; then
            vi "$CONFIG_FILE"
        else
            cat "$CONFIG_FILE"
            echo ""
            echo "  Edit manual file: $CONFIG_FILE"
            echo "  Lalu lanjutkan script ini."
            read -rp "  Tekan ENTER untuk lanjut..."
        fi
    fi
fi

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  Amprem Web - Setup Akses Publik${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "${YELLOW}Pilih mode:${NC}"
echo "  1) Tanpa domain     - Nginx reverse proxy, akses via http://<IP_VPS>"
echo "  2) Pakai domain     - Nginx + SSL gratis (Let's Encrypt)"
echo "  3) Cloudflare Tunnel - gratis, dapat URL publik tanpa perlu domain/IP publik"
echo ""
read -rp "Pilih [1/2/3]: " MODE

case "$MODE" in
    # ----------------------------------------------------------
    #  OPSI 1: IP ONLY
    # ----------------------------------------------------------
    1)
        install_nginx
        setup_sites_dir

        info "Mode: Tanpa domain (IP only)"
        gen_config_ip
        activate_nginx

        PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 ipinfo.io/ip 2>/dev/null || echo "<IP_VPS>")

        echo ""
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}  SELESAI!${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo ""
        echo "  Pastikan Node.js server jalan:"
        echo "    cd ${SCRIPT_DIR} && npm start"
        echo ""
        echo "  Akses dari browser:"
        echo "    http://${PUBLIC_IP}"
        echo ""
        echo "  Kalau gak bisa diakses, pastikan:"
        echo "    1. Port 80 terbuka di firewall"
        echo "    2. Node.js server jalan di port ${APP_PORT}"
        echo ""
        echo "  Buka firewall:"
        echo "    sudo ufw allow 80"
        echo ""
        ;;

    # ----------------------------------------------------------
    #  OPSI 2: PAKAI DOMAIN
    # ----------------------------------------------------------
    2)
        echo ""
        read -rp "Masukkan domain (contoh: amprem.example.com): " DOMAIN
        DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

        if [ -z "$DOMAIN" ]; then
            fail "Domain tidak boleh kosong."
        fi

        echo ""
        echo -e "${YELLOW}Sambungkan domain lewat:${NC}"
        echo "  a) Nginx langsung  - domain A record ke IP VPS, Nginx handle HTTP/HTTPS"
        echo "  b) Cloudflare Tunnel - domain di Cloudflare, tunnel ke server (gak perlu buka port/IP publik)"
        echo ""
        read -rp "Pilih [a/b]: " DOMAIN_MODE

        case "$DOMAIN_MODE" in
            [bB])
                # --- Domain via Cloudflare Tunnel ---
                install_cloudflared
                setup_cloudflare_named_with_domain "$DOMAIN"

                echo ""
                echo -e "${GREEN}=========================================${NC}"
                echo -e "${GREEN}  SELESAI!${NC}"
                echo -e "${GREEN}=========================================${NC}"
                echo ""
                echo "  Pastikan Node.js server jalan:"
                echo "    cd ${SCRIPT_DIR} && npm start"
                echo ""
                echo "  Akses dari browser:"
                echo "    https://${DOMAIN}"
                echo ""
                echo "  SSL otomatis dari Cloudflare (gak perlu Certbot)."
                echo "  Tunnel jalan sebagai service, auto-start saat boot."
                echo ""
                echo "  Manage tunnel:"
                echo "    systemctl status cloudflared"
                echo "    journalctl -u cloudflared -f"
                echo ""
                ;;
            *)
                # --- Domain via Nginx langsung ---
                install_nginx
                setup_sites_dir

                info "Mode: Domain via Nginx (${DOMAIN})"
                gen_config_domain "$DOMAIN"
                activate_nginx

                # Cek DNS & tawarkan SSL
                echo ""
                if check_domain_dns "$DOMAIN"; then
                    echo ""
                    read -rp "Mau pasang SSL gratis (HTTPS) sekarang? [y/N]: " DO_SSL
                    if [[ "$DO_SSL" =~ ^[Yy]$ ]]; then
                        setup_ssl "$DOMAIN"
                        systemctl reload nginx
                    fi
                else
                    warn "SSL dilewati karena DNS belum siap."
                    warn "Kalau DNS sudah benar, jalankan manual:"
                    warn "  sudo certbot --nginx -d ${DOMAIN}"
                fi

                echo ""
                echo -e "${GREEN}=========================================${NC}"
                echo -e "${GREEN}  SELESAI!${NC}"
                echo -e "${GREEN}=========================================${NC}"
                echo ""
                echo "  Pastikan Node.js server jalan:"
                echo "    cd ${SCRIPT_DIR} && npm start"
                echo ""
                echo "  Akses dari browser:"
                echo "    http://${DOMAIN}"
                if certbot certificates -d "$DOMAIN" 2>/dev/null | grep -q "Certificate Name"; then
                    echo "    https://${DOMAIN} (SSL aktif)"
                fi
                echo ""
                echo "  Kalau gak bisa diakses, pastikan:"
                echo "    1. Port 80 dan 443 terbuka di firewall"
                echo "    2. Node.js server jalan di port ${APP_PORT}"
                echo ""
                echo "  Buka firewall:"
                echo "    sudo ufw allow 80 && sudo ufw allow 443"
                echo ""
                ;;
        esac
        ;;

    # ----------------------------------------------------------
    #  OPSI 3: CLOUDFLARE TUNNEL
    # ----------------------------------------------------------
    3)
        install_cloudflared

        echo ""
        echo -e "${YELLOW}Sub-opsi Cloudflare Tunnel:${NC}"
        echo "  a) Quick Tunnel  - langsung jalan, dapat URL *.trycloudflare.com (berubah tiap restart)"
        echo "  b) Named Tunnel  - URL permanen via domain di Cloudflare (perlu login + domain)"
        echo ""
        read -rp "Pilih [a/b]: " CF_MODE

        case "$CF_MODE" in
            [bB])
                setup_cloudflare_named
                ;;
            *)
                setup_cloudflare_quick
                ;;
        esac

        echo ""
        echo "  Pastikan Node.js server jalan:"
        echo "    cd ${SCRIPT_DIR} && npm start"
        echo ""
        echo "  Manage tunnel:"
        echo "    systemctl status cloudflared-quick   # cek status (quick)"
        echo "    systemctl status cloudflared         # cek status (named)"
        echo "    journalctl -u cloudflared-quick -f   # lihat log realtime"
        echo ""
        ;;

    *)
        fail "Pilihan tidak valid. Jalankan ulang dan pilih 1, 2, atau 3."
        ;;
esac

echo -e "${GREEN}=========================================${NC}"
