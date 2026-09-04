#!/bin/bash
# ============================================================
# Amprem Web - Auto Setup
# SATU script untuk semua deployment.
# Jalankan: bash setup.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IS_TERMUX=false
[ -d "/data/data/com.termux" ] && IS_TERMUX=true

# ---------- Warna ----------
info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- Separator ----------
sep() { echo ""; echo -e "${BOLD}────────────────────────────────────────${NC}"; }

# ============================================================
#  BANNER
# ============================================================
banner() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ███████╗████████╗██████╗  ██████╗ "
    echo "  ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗"
    echo "  ██████╔╝█████╗     ██║   ██████╔╝██║   ██║"
    echo "  ██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║"
    echo "  ██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝"
    echo "  ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ "
    echo -e "${NC}"
    echo -e "  ${BOLD}Alight Motion Premium - Auto Setup${NC}"
    echo ""
}

# ============================================================
#  DETEKSI ENVIRONMENT
# ============================================================
detect_env() {
    if $IS_TERMUX; then
        info "Environment: Termux (HP Android)"
    else
        info "Environment: VPS/Linux"
    fi
}

# ============================================================
#  INSTALL DEPENDENCIES
# ============================================================
install_deps() {
    sep
    info "1/5 - Install dependencies..."

    if $IS_TERMUX; then
        pkg update -y -q
        pkg install -y nodejs git nano cloudflared 2>/dev/null || {
            pkg install -y nodejs git nano
        }
        ok "Node.js: $(node -v)"
    else
        # VPS - cek package manager
        if command -v apt &>/dev/null; then
            export DEBIAN_FRONTEND=noninteractive
            apt update -qq
            # Node.js
            if ! command -v node &>/dev/null; then
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>/dev/null || apt install -y nodejs
            fi
            # Tools
            apt install -y -qq git nano curl certbot python3-certbot-nginx 2>/dev/null || true
        elif command -v yum &>/dev/null; then
            yum install -y git nano curl
            if ! command -v node &>/dev/null; then
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
            fi
        elif command -v dnf &>/dev/null; then
            dnf install -y git nano curl
            if ! command -v node &>/dev/null; then
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
            fi
        fi
        ok "Node.js: $(node -v)"
    fi
}

# ============================================================
#  INSTALL PROJECT
# ============================================================
install_project() {
    sep
    info "2/5 - Install project..."

    cd "$SCRIPT_DIR"

    if [ -d "node_modules" ]; then
        ok "npm dependencies sudah ada"
    else
        npm install
        ok "npm dependencies terinstall"
    fi
}

# ============================================================
#  EDIT CONFIG
# ============================================================
edit_config() {
    sep
    info "3/5 - Konfigurasi API Key..."

    echo "  File: $SCRIPT_DIR/config.js"
    echo ""
    echo "  amprem6ApiKey : komunitas (SK-...)"
    echo "  amprem2ApiKey : WAJIB ISI kalau mau pakai Amprem2"
    echo ""

    # Tampilkan nilai sekarang
    AMP6=$(grep "amprem6ApiKey:" "$SCRIPT_DIR/config.js" 2>/dev/null | sed "s/.*'\([^']*\)'.*/\1/" | head -c 15)
    AMP2=$(grep "amprem2ApiKey:" "$SCRIPT_DIR/config.js" 2>/dev/null | sed "s/.*'\([^']*\)'.*/\1/")
    echo "  amprem6ApiKey : ${AMP6:-<kosong>}..."
    echo "  amprem2ApiKey : ${AMP2:-<kosong>}"
    echo ""
    read -rp "  Buka nano untuk edit config.js? [Y/n]: " DO_EDIT
    if [[ ! "$DO_EDIT" =~ ^[Nn]$ ]]; then
        nano "$SCRIPT_DIR/config.js"
        ok "Config disimpan!"
    fi
}

# ============================================================
#  SHOW DEPLOYMENT MENU
# ============================================================
show_menu() {
    sep
    info "4/5 - Pilih cara deployment..."

    echo ""
    if $IS_TERMUX; then
        echo -e "${YELLOW}  Pilih cara akses:${NC}"
        echo ""
        echo "    1) WiFi Lokal         - akses dari HP/laptop lain di WiFi sama"
        echo "    2) Cloudflare Quick    - URL internet gratis (*.trycloudflare.com)"
        echo "    3) Cloudflare Named    - URL internet permanen via domain di Cloudflare"
        echo "    4) Domain + Nginx     - https://domain.com via Nginx (butuh domain)"
        echo ""
        read -rp "  Pilih [1-4]: " PILIH

        case "$PILIH" in
            1) deploy_termux_wifi ;;
            2) deploy_termux_quick ;;
            3) deploy_termux_named ;;
            4) deploy_termux_domain ;;
            *) warn "Pilihan tidak valid."; show_menu ;;
        esac
    else
        echo -e "${YELLOW}  Pilih cara akses:${NC}"
        echo ""
        echo "    1) IP Only              - akses via http://IP_VPS (tanpa domain)"
        echo "    2) Domain + Nginx + SSL - https://domain.com (butuh domain)"
        echo "    3) Cloudflare Quick     - URL internet gratis (*.trycloudflare.com)"
        echo "    4) Cloudflare Named     - URL internet permanen via domain di Cloudflare"
        echo ""
        read -rp "  Pilih [1-4]: " PILIH

        case "$PILIH" in
            1) deploy_vps_ip ;;
            2) deploy_vps_domain ;;
            3) deploy_vps_quick ;;
            4) deploy_vps_named ;;
            *) warn "Pilihan tidak valid."; show_menu ;;
        esac
    fi
}

# ============================================================
#  DEPLOY: TERMUX - WIFI LOKAL
# ============================================================
deploy_termux_wifi() {
    sep
    info "Mode: WiFi Lokal"
    info "Akses dari perangkat lain di WiFi yang sama."

    pkill -f "node server" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    PORT=8080 nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 3

    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[0-9.]+' || \
               ifconfig 2>/dev/null | grep -oP 'inet \K[0-9.]+' | grep -v '127.0.0.1' | head -1 || \
               echo "")

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Dari HP ini:"
    echo "    http://localhost:8080"
    echo ""
    if [ -n "$LOCAL_IP" ]; then
        echo "  Dari HP/laptop lain (1 WiFi):"
        echo "    http://${LOCAL_IP}:8080"
        echo ""
        echo "  IP Lokal HP kamu: ${LOCAL_IP}"
    else
        echo "  Cek IP HP: ip addr"
        echo "  Lalu akses: http://IP_HP:8080"
    fi
    echo ""
    echo "  Stop server: pkill -f 'node server'"
    echo "  Lihat log: cat /tmp/amprem.log"
}

# ============================================================
#  DEPLOY: TERMUX - CLOUDFLARE QUICK TUNNEL
# ============================================================
deploy_termux_quick() {
    sep
    info "Mode: Cloudflare Quick Tunnel"
    info "URL berubah setiap kali restart."

    pkill -f "node server" 2>/dev/null || true
    pkill -f "cloudflared" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    PORT=8080 nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 2

    nohup cloudflared tunnel --url http://localhost:8080 > /tmp/amprem-tunnel.log 2>&1 &
    sleep 5

    TUNNEL_URL=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/amprem-tunnel.log 2>/dev/null | tail -1)

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    if [ -n "$TUNNEL_URL" ]; then
        echo "  URL PUBLIK:"
        echo -e "    ${GREEN}${BOLD}${TUNNEL_URL}${NC}"
        echo ""
    else
        echo "  URL belum muncul. Cek log: cat /tmp/amprem-tunnel.log"
        echo ""
    fi
    echo "  Stop: pkill -f 'node server' && pkill -f 'cloudflared'"
    echo "  Lihat log tunnel: tail -f /tmp/amprem-tunnel.log"
}

# ============================================================
#  DEPLOY: TERMUX - CLOUDFLARE NAMED TUNNEL
# ============================================================
deploy_termux_named() {
    sep
    info "Mode: Cloudflare Named Tunnel (Domain Permanen)"
    info "SSL otomatis dari Cloudflare. URL tidak berubah."

    echo ""
    read -rp "  Masukkan domain (contoh: amprem.example.com): " DOMAIN

    echo ""
    read -rp "  Masukkan domain (contoh: amprem.example.com): " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

    pkill -f "node server" 2>/dev/null || true
    pkill -f "cloudflared" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    PORT=8080 nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 2

    TUNNEL_NAME="amprem-web"
    cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true
    cloudflared tunnel create "$TUNNEL_NAME" > /dev/null 2>&1
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    [ -z "$TUNNEL_ID" ] && fail "Gagal buat tunnel. Login dulu: cloudflared tunnel login"

    CF_DIR="$HOME/.cloudflared"
    mkdir -p "$CF_DIR"
    cat > "$CF_DIR/config.yml" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: ${CF_DIR}/${TUNNEL_ID}.json
ingress:
  - hostname: ${DOMAIN}
    service: http://localhost:8080
  - service: http_status:404
EOF

    cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN" > /dev/null 2>&1
    nohup cloudflared tunnel run "$TUNNEL_NAME" > /tmp/amprem-tunnel.log 2>&1 &
    sleep 5

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Domain:"
    echo -e "    ${GREEN}${BOLD}https://${DOMAIN}${NC}"
    echo ""
    echo "  Stop: pkill -f 'node server' && pkill -f 'cloudflared'"
}

# ============================================================
#  DEPLOY: TERMUX - DOMAIN + NGINX (serve langsung)
# ============================================================
deploy_termux_domain() {
    sep
    info "Mode: Domain + Serve Langsung (Tanpa Nginx)"
    info "HTTPS via Cloudflare Proxy. Port: 8080."

    echo ""
    read -rp "  Masukkan domain (contoh: amprem.example.com): " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

    echo ""
    info "Setup Cloudflare DNS (CNAME -> proxied)..."
    echo ""
    echo "  Buka https://dash.cloudflare.com"
    echo "  Pergi ke DNS -> Records"
    echo "  Tambah record:"
    echo "    Type: CNAME"
    echo "    Name: subdomain (bagian sebelum titik)"
    echo "    Target: $(whoami)@$(hostname).termux.net"
    echo "    Proxy: ON (warna orange)"
    echo ""
    read -rp "  Tekan ENTER setelah DNS sudah ditambah..."

    pkill -f "node server" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    PORT=8080 nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 3

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Domain:"
    echo -e "    ${GREEN}${BOLD}https://${DOMAIN}${NC}"
    echo ""
    echo "  Stop: pkill -f 'node server'"
}

# ============================================================
#  DEPLOY: VPS - IP ONLY
# ============================================================
deploy_vps_ip() {
    sep
    info "Mode: IP Only (tanpa domain)"

    # Setup Nginx
    if command -v nginx &>/dev/null; then
        NGINX_CONF="/etc/nginx/sites-available/amprem"
        cat > "$NGINX_CONF" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
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
    }
}
EOF
        mkdir -p /etc/nginx/sites-enabled
        rm -f /etc/nginx/sites-enabled/default
        ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/amprem
        nginx -t && systemctl restart nginx
        ok "Nginx aktif"
    fi

    pkill -f "node server" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 3

    PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "IP_VPS_KAMU")

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Akses:"
    echo -e "    ${GREEN}http://${PUBLIC_IP}${NC}"
    echo ""
    echo "  Stop: pkill -f 'node server'"
    echo "  Lihat log: cat /tmp/amprem.log"
    echo ""
    echo "  Pastikan port 80 terbuka di firewall VPS!"
    echo "  sudo ufw allow 80"
}

# ============================================================
#  DEPLOY: VPS - DOMAIN + NGINX + SSL
# ============================================================
deploy_vps_domain() {
    sep
    info "Mode: Domain + Nginx + SSL"
    info "HTTPS otomatis via Let's Encrypt."

    echo ""
    read -rp "  Masukkan domain (contoh: amprem.example.com): " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

    NGINX_CONF="/etc/nginx/sites-available/amprem"
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
    }
}
EOF

    mkdir -p /etc/nginx/sites-enabled
    rm -f /etc/nginx/sites-enabled/default
    ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/amprem
    nginx -t || fail "Nginx config error"
    systemctl enable nginx
    systemctl restart nginx
    ok "Nginx aktif"

    pkill -f "node server" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 2

    # Cek DNS
    PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "")
    DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null | head -1)

    sep
    if [ -n "$DOMAIN_IP" ] && [ "$DOMAIN_IP" = "$PUBLIC_IP" ]; then
        ok "DNS sudah benar (${DOMAIN_IP})"
        echo ""
        read -rp "  Pasang SSL sekarang? [Y/n]: " DO_SSL
        if [[ ! "$DO_SSL" =~ ^[Nn]$ ]]; then
            certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos \
                --register-unsafely-without-email --redirect
            systemctl enable --now certbot-renew.timer 2>/dev/null || true
            (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | sort -u | crontab -
            ok "SSL aktif!"
        fi
    else
        warn "DNS belum siap. Domain belum pointing ke IP VPS ini."
        warn "Pastikan A record: ${DOMAIN} -> ${PUBLIC_IP}"
        warn "SSL bisa dipasang manual: sudo certbot --nginx -d ${DOMAIN}"
    fi

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Domain:"
    echo -e "    ${GREEN}${BOLD}https://${DOMAIN}${NC}"
    echo ""
    echo "  Stop: pkill -f 'node server'"
    echo "  Edit SSL: sudo certbot --nginx -d ${DOMAIN}"
}

# ============================================================
#  DEPLOY: VPS - CLOUDFLARE QUICK TUNNEL
# ============================================================
deploy_vps_quick() {
    sep
    info "Mode: Cloudflare Quick Tunnel"
    info "URL berubah setiap kali restart."

    # Install cloudflared
    if ! command -v cloudflared &>/dev/null; then
        ARCH=$(uname -m)
        case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; *) ARCH="arm" ;; esac
        curl -sL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -o /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi
    ok "cloudflared: $(cloudflared --version 2>&1 | head -1)"

    pkill -f "node server" 2>/dev/null || true
    pkill -f "cloudflared" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 2

    nohup cloudflared tunnel --url http://localhost:3000 > /tmp/amprem-tunnel.log 2>&1 &
    sleep 5

    TUNNEL_URL=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/amprem-tunnel.log 2>/dev/null | tail -1)

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    if [ -n "$TUNNEL_URL" ]; then
        echo "  URL PUBLIK:"
        echo -e "    ${GREEN}${BOLD}${TUNNEL_URL}${NC}"
        echo ""
    else
        echo "  Cek log: cat /tmp/amprem-tunnel.log"
        echo ""
    fi
    echo "  Stop: pkill -f 'node server' && pkill -f 'cloudflared'"
}

# ============================================================
#  DEPLOY: VPS - DOMAIN + CLOUDFLARE NAMED TUNNEL
# ============================================================
deploy_vps_named() {
    sep
    info "Mode: Cloudflare Named Tunnel (Domain Permanen)"
    info "SSL otomatis dari Cloudflare. URL tidak berubah."

    echo ""
    read -rp "  Masukkan domain (contoh: amprem.example.com): " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

    # Install cloudflared
    if ! command -v cloudflared &>/dev/null; then
        ARCH=$(uname -m)
        case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; *) ARCH="arm" ;; esac
        curl -sL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -o /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi

    echo ""
    read -rp "  Login Cloudflare sekarang? [Y/n]: " DO_LOGIN
    if [[ ! "$DO_LOGIN" =~ ^[Nn]$ ]]; then
        cloudflared tunnel login
    fi

    pkill -f "node server" 2>/dev/null || true
    pkill -f "cloudflared" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    nohup node server.js > /tmp/amprem.log 2>&1 &
    sleep 2

    TUNNEL_NAME="amprem-web"
    cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true
    cloudflared tunnel create "$TUNNEL_NAME" > /dev/null 2>&1
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    [ -z "$TUNNEL_ID" ] && fail "Gagal buat tunnel."

    CF_DIR="/etc/cloudflared"
    mkdir -p "$CF_DIR"
    cat > "$CF_DIR/config.yml" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: /root/.cloudflared/${TUNNEL_ID}.json
ingress:
  - hostname: ${DOMAIN}
    service: http://localhost:3000
  - service: http_status:404
EOF

    cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN" > /dev/null 2>&1
    nohup cloudflared tunnel run "$TUNNEL_NAME" > /tmp/amprem-tunnel.log 2>&1 &
    sleep 5

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Domain:"
    echo -e "    ${GREEN}${BOLD}https://${DOMAIN}${NC}"
    echo ""
    echo "  Stop: pkill -f 'node server' && pkill -f 'cloudflared'"
}

# ============================================================
#  DONE
# ============================================================
all_done() {
    sep
    echo -e "${GREEN}"
    echo "  ███████╗ ██████╗ █████╗ ██╗   ██╗██████╗ ██╗███╗   ██╗ ██████╗ "
    echo "  ██╔════╝██╔════╝██╔══██╗██║   ██║██╔══██╗██║████╗  ██║██╔════╝ "
    echo "  █████╗  ██║     ███████║██║   ██║██████╔╝██║██╔██╗ ██║██║  ███╗"
    echo "  ██╔══╝  ██║     ██╔══██║██║   ██║██╔══██╗██║██║╚██╗██║██║   ██║"
    echo "  ███████╗╚██████╗██║  ██║╚██████╔╝██║  ██║██║██║ ╚████║╚██████╔╝"
    echo "  ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    echo -e "${NC}"
    echo "  Edit config: nano $SCRIPT_DIR/config.js"
    echo "  GitHub: https://github.com/yowbxz/amprem-web"
    sep
}

# ============================================================
#  MAIN
# ============================================================
main() {
    banner
    detect_env
    install_deps
    install_project
    edit_config
    show_menu
    all_done
}

main
