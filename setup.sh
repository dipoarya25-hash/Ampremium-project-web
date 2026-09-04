#!/bin/bash
# ============================================================
# Amprem Web - Setup & Management
# Semua dalam SATU script.
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

# ---------- Helpers ----------
info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
sep()   { echo ""; echo -e "${BOLD}────────────────────────────────────────${NC}"; }

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
    echo -e "  ${BOLD}Alight Motion Premium - Setup & Management${NC}"
    echo ""
}

# ============================================================
#  GET LOCAL IP
# ============================================================
get_local_ip() {
    ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[0-9.]+' || \
    ifconfig 2>/dev/null | grep -oP 'inet \K[0-9.]+' | grep -v '127.0.0.1' | head -1 || \
    echo ""
}

# ============================================================
#  GET PUBLIC IP
# ============================================================
get_public_ip() {
    curl -s --max-time 5 ifconfig.me 2>/dev/null || \
    curl -s --max-time 5 ipinfo.io/ip 2>/dev/null || \
    echo ""
}

# ============================================================
#  CHECK STATUS
# ============================================================
check_status() {
    sep
    info "Status Server"

    # Node server
    if pgrep -f "server.js" > /dev/null; then
        local PID=$(pgrep -f "server.js" | head -1)
        # ss tidak ada di Termux, coba lsof atau netstat
        local PORT
        if command -v ss &>/dev/null; then
            PORT=$(ss -tlnp 2>/dev/null | grep "$PID" | grep -oP ':\K[0-9]+' | head -1 || echo "?")
        elif command -v netstat &>/dev/null; then
            PORT=$(netstat -tlnp 2>/dev/null | grep "$PID" | grep -oP ':\K[0-9]+' | head -1 || echo "?")
        else
            PORT="?"
        fi
        local UPTIME=$(ps -o etime= -p "$PID" 2>/dev/null | xargs || echo "?")
        echo "  ${GREEN}[ONLINE]${NC}  Node.js server - PID $PID, Port ${PORT:-?}, Uptime: $UPTIME"
    else
        echo "  ${RED}[OFFLINE]${NC}  Node.js server tidak jalan"
    fi

    # Tunnel
    if pgrep -f "cloudflared" > /dev/null; then
        local TUNNEL_PID=$(pgrep -f "cloudflared" | head -1)
        local TUNNEL_URL=$(grep -oP 'https://[a-z0-9-]+\.(trycloudflare\.com|cloudflared\.com)' /tmp/amprem-tunnel.log 2>/dev/null | tail -1 || echo "?")
        echo "  ${GREEN}[ONLINE]${NC}  Cloudflare Tunnel - PID $TUNNEL_PID"
        if [ "$TUNNEL_URL" != "?" ]; then
            echo "              URL: $TUNNEL_URL"
        fi
    elif pgrep -f "ngrok" > /dev/null; then
        local NGROK_PID=$(pgrep -f "ngrok" | head -1)
        echo "  ${GREEN}[ONLINE]${NC}  Ngrok - PID $NGROK_PID"
        local NGROK_URL=$(grep -oP 'https://[0-9a-f]+\.ngrok\.io' /tmp/amprem-ngrok.log 2>/dev/null | tail -1 || echo "?")
        if [ "$NGROK_URL" != "?" ]; then
            echo "              URL: $NGROK_URL"
        fi
    elif pgrep -f "localtunnel" > /dev/null; then
        echo "  ${GREEN}[ONLINE]${NC}  LocalTunnel aktif"
        local LT_URL=$(grep -oP 'https://[a-z0-9-]+\.l\.tunnel\.cloud\.l\.google\.com' /tmp/amprem-lt.log 2>/dev/null | tail -1 || echo "?")
        if [ "$LT_URL" != "?" ]; then
            echo "              URL: $LT_URL"
        fi
    elif pgrep -f "pagekite" > /dev/null; then
        echo "  ${GREEN}[ONLINE]${NC}  Pagekite aktif"
    elif pgrep -f "serveo" > /dev/null; then
        echo "  ${GREEN}[ONLINE]${NC}  Serveo SSH Tunnel aktif"
    else
        echo "  ${YELLOW}[NONE]${NC}   Tidak ada tunnel aktif"
    fi

    # Nginx (VPS only)
    if ! $IS_TERMUX && command -v nginx &>/dev/null; then
        if systemctl is-active --quiet nginx 2>/dev/null; then
            echo "  ${GREEN}[ONLINE]${NC}  Nginx reverse proxy aktif"
        else
            echo "  ${YELLOW}[STOPPED]${NC} Nginx tidak aktif"
        fi
    fi

    echo ""
    local LOCAL_IP=$(get_local_ip)
    local PUBLIC_IP=$(get_public_ip)
    echo "  IP Lokal  : ${LOCAL_IP:-<tidak terdeteksi>}"
    echo "  IP Publik : ${PUBLIC_IP:-<tidak terdeteksi>}"
    echo ""
    echo "  Akses lokal: http://localhost:3000"
    if [ -n "$LOCAL_IP" ]; then
        echo "  Akses WiFi: http://${LOCAL_IP}:3000"
    fi
}

# ============================================================
#  STOP ALL
# ============================================================
stop_all() {
    sep
    info "Menghentikan semua service..."
    mkdir -p /tmp

    pkill -f "node server.js" 2>/dev/null && ok "Node.js dihentikan" || warn "Node.js tidak jalan"
    pkill -f "cloudflared" 2>/dev/null && ok "Cloudflare dihentikan" || warn "Cloudflare tidak jalan"
    pkill -f "ngrok" 2>/dev/null && ok "Ngrok dihentikan" || warn "Ngrok tidak jalan"
    pkill -f "localtunnel" 2>/dev/null && ok "LocalTunnel dihentikan" || warn "LocalTunnel tidak jalan"
    pkill -f "pagekite" 2>/dev/null && ok "Pagekite dihentikan" || warn "Pagekite tidak jalan"
    pkill -f "serveo" 2>/dev/null && ok "Serveo dihentikan" || warn "Serveo tidak jalan"
    ok "Semua service dihentikan."
}

# ============================================================
#  START SERVER
# ============================================================
start_server() {
    stop_all
    sleep 1

    cd "$SCRIPT_DIR"

    # Ensure log dir exists
    mkdir -p /tmp

    local PORT=${1:-3000}

    # Cari path node secara eksplisit
    local NODE_BIN
    if $IS_TERMUX; then
        NODE_BIN="$PREFIX/bin/node"
    else
        NODE_BIN="$(command -v node)"
    fi

    if [ -z "$NODE_BIN" ] || [ ! -x "$NODE_BIN" ]; then
        warn "Node.js tidak ditemukan di PATH. Jalankan 'I' di menu untuk install."
        return 1
    fi

    # Jalankan server dengan nohup + explicit path + stderr capture
    cd "$SCRIPT_DIR"
    PORT=$PORT HOME=$HOME PATH="$PREFIX/bin:$PATH" nohup "$NODE_BIN" server.js > /tmp/amprem.log 2>&1 &

    local SERVER_PID=$!
    sleep 3

    # Cek apakah process masih hidup
    if kill -0 $SERVER_PID 2>/dev/null; then
        ok "Server jalan (PID: $SERVER_PID) di port $PORT"
    else
        warn "Server gagal start. Cek error:"
        echo ""
        cat /tmp/amprem.log
        echo ""
        return 1
    fi
}

# ============================================================
#  INSTALL DEPS
# ============================================================
install_deps() {
    sep
    info "Install Dependencies..."

    if $IS_TERMUX; then
        pkg update -y -q
        pkg install -y nodejs git nano curl wget openssh 2>/dev/null
        # cloudflared via pkg
        pkg install cloudflared -y 2>/dev/null || {
            local ARCH
            ARCH=$(uname -m)
            case "$ARCH" in aarch64|arm64) ARCH="arm64" ;; armv7l|armhf) ARCH="arm" ;; x86_64|amd64) ARCH="amd64" ;; esac
            curl -sL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -o "$PREFIX/bin/cloudflared"
            chmod +x "$PREFIX/bin/cloudflared"
        }
        # localtunnel
        npm install -g localtunnel 2>/dev/null || true
        ok "Dependencies Termux terinstall"
    else
        if command -v apt &>/dev/null; then
            export DEBIAN_FRONTEND=noninteractive
            apt update -qq
            apt install -y -qq git nano curl wget openssh-client
            if ! command -v node &>/dev/null; then
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>/dev/null || apt install -y nodejs
            fi
            apt install -y -qq nginx certbot python3-certbot-nginx 2>/dev/null || true
        elif command -v yum &>/dev/null; then
            yum install -y git nano curl wget openssh-clients
            if ! command -v node &>/dev/null; then
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
            fi
        fi
        # cloudflared
        if ! command -v cloudflared &>/dev/null; then
            local ARCH
            ARCH=$(uname -m)
            case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; *) ARCH="arm" ;; esac
            curl -sL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -o /usr/local/bin/cloudflared
            chmod +x /usr/local/bin/cloudflared
        fi
        # localtunnel
        npm install -g localtunnel 2>/dev/null || true
        ok "Dependencies VPS terinstall"
    fi

    ok "Node.js: $(node -v)"
}

# ============================================================
#  INSTALL PROJECT
# ============================================================
install_project() {
    sep
    info "Install Project..."
    cd "$SCRIPT_DIR"

    if [ ! -d "node_modules" ]; then
        npm install
    fi

    # Cek config.js ada atau belum
    if [ ! -f "config.js" ]; then
        warn "config.js tidak ditemukan!"
    else
        local AMP6=$(grep "amprem6ApiKey:" config.js 2>/dev/null | sed "s/.*'\([^']*\)'.*/\1/" | head -c 15)
        local AMP2=$(grep "amprem2ApiKey:" config.js 2>/dev/null | sed "s/.*'\([^']*\)'.*/\1/")
        echo ""
        echo "  Config sekarang:"
        echo "    amprem6ApiKey : ${AMP6:-<kosong>}..."
        echo "    amprem2ApiKey : ${AMP2:-<kosong>}"
    fi

    ok "Project siap."
}

# ============================================================
#  EDIT CONFIG
# ============================================================
edit_config() {
    sep
    info "Edit Config"
    echo "  File: $SCRIPT_DIR/config.js"
    echo ""
    read -rp "  Buka nano untuk edit? [Y/n]: " DO_EDIT
    if [[ ! "$DO_EDIT" =~ ^[Nn]$ ]]; then
        nano "$SCRIPT_DIR/config.js"
        ok "Config disimpan!"
    fi
}

# ============================================================
#  DEPLOY MENU
# ============================================================
deploy_menu() {
    sep
    info "Pilih Cara Deployment"

    echo ""
    if $IS_TERMUX; then
        echo -e "${YELLOW}  Termux -HP Android-${NC}"
        echo ""
        echo "  AKSES LOKAL:"
        echo "    1) Localhost         - http://localhost:8080 (HP ini saja)"
        echo "    2) WiFi Lokal        - http://IP_HP:8080 (HP/laptop lain 1 WiFi)"
        echo ""
        echo "  TUNNEL INTERNET:"
        echo "    3) Ngrok              - URL internet gratis (butuh akun ngrok.com)"
        echo "    4) Cloudflare Quick  - URL *.trycloudflare.com (gratis, URL berubah)"
        echo "    5) Cloudflare Named  - https://domain.com (permanen, butuh Cloudflare)"
        echo "    6) LocalTunnel       - URL *.l.tunnel.cloud.l.google.com (gratis)"
        echo "    7) Pagekite         - URL *.pagekite.me (gratis, butuh akun)"
        echo "    8) Serveo           - URL subdomain.serveo.net (gratis via SSH)"
        echo ""
        echo "  DOMAIN:"
        echo "    9) Domain + Cloudflare Proxy - https://domain.com (serve langsung)"
        echo ""
        echo "  KELOLA:"
        echo "    S) Status           - Cek service yang jalan"
        echo "    R) Restart Server   - Restart Node.js server"
        echo "    X) Stop Semua      - Hentikan semua service"
        echo "    E) Edit Config     - Edit config.js"
        echo "    0) Kembali"
        echo ""
        read -rp "  Pilih [1-9/S/R/X/E/0]: " PILIH

        case "$PILIH" in
            1) deploy_localhost ;;
            2) deploy_wifi ;;
            3) deploy_ngrok ;;
            4) deploy_cf_quick ;;
            5) deploy_cf_named ;;
            6) deploy_localtunnel ;;
            7) deploy_pagekite ;;
            8) deploy_serveo ;;
            9) deploy_domain ;;
            S|s) check_status; deploy_menu ;;
            R|r) start_server 8080; deploy_menu ;;
            X|x) stop_all; deploy_menu ;;
            E|e) edit_config; deploy_menu ;;
            0|*) return ;;
        esac
    else
        echo -e "${YELLOW}  VPS -Server/Linux-${NC}"
        echo ""
        echo "  IP ONLY:"
        echo "    1) IP + Nginx        - http://IP_VPS (reverse proxy)"
        echo ""
        echo "  DOMAIN:"
        echo "    2) Domain + Nginx + SSL - https://domain.com (Let's Encrypt)"
        echo "    3) Domain + Cloudflare  - https://domain.com (via tunnel)"
        echo ""
        echo "  TUNNEL INTERNET:"
        echo "    4) Ngrok              - URL internet gratis (butuh akun ngrok.com)"
        echo "    5) Cloudflare Quick  - URL *.trycloudflare.com (gratis)"
        echo "    6) Cloudflare Named  - https://domain.com (permanen)"
        echo "    7) LocalTunnel       - URL *.l.tunnel.cloud.l.google.com"
        echo "    8) Serveo           - URL subdomain.serveo.net (via SSH)"
        echo ""
        echo "  KELOLA:"
        echo "    S) Status           - Cek service yang jalan"
        echo "    R) Restart Server   - Restart Node.js server"
        echo "    X) Stop Semua      - Hentikan semua service"
        echo "    E) Edit Config     - Edit config.js"
        echo "    N) Nginx Status    - Cek Nginx"
        echo "    0) Kembali"
        echo ""
        read -rp "  Pilih [1-8/S/R/X/E/N/0]: " PILIH

        case "$PILIH" in
            1) deploy_vps_ip ;;
            2) deploy_vps_domain ;;
            3) deploy_vps_cf_domain ;;
            4) deploy_ngrok ;;
            5) deploy_cf_quick ;;
            6) deploy_cf_named ;;
            7) deploy_localtunnel ;;
            8) deploy_serveo ;;
            S|s) check_status; deploy_menu ;;
            R|r) start_server 3000; deploy_menu ;;
            X|x) stop_all; deploy_menu ;;
            E|e) edit_config; deploy_menu ;;
            N|n) nginx_status; deploy_menu ;;
            0|*) return ;;
            *) warn "Pilihan tidak valid."; deploy_menu ;;
        esac
    fi

    deploy_menu
}

# ============================================================
#  NGINX STATUS
# ============================================================
nginx_status() {
    sep
    info "Nginx Status"
    if ! command -v nginx &>/dev/null; then
        echo "  Nginx tidak terinstall."
        return
    fi
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo "  ${GREEN}[ONLINE]${NC} Nginx aktif"
        echo "  Config: /etc/nginx/sites-available/amprem"
        nginx -t 2>&1 && ok "Config valid" || warn "Config error"
    else
        echo "  ${RED}[OFFLINE]${NC} Nginx tidak aktif"
    fi
}

# ============================================================
#  DEPLOY: LOCALHOST (TERMUX)
# ============================================================
deploy_localhost() {
    sep
    info "Mode: Localhost (HP ini saja)"
    start_server 8080
    local LOCAL_IP=$(get_local_ip)
    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Akses di HP ini:"
    echo "    http://localhost:8080"
    echo "    http://${LOCAL_IP:-localhost}:8080"
    echo ""
    echo "  Log: cat /tmp/amprem.log"
    echo "  Stop: pkill -f 'node server'"
}

# ============================================================
#  DEPLOY: WIFI LOKAL (TERMUX)
# ============================================================
deploy_wifi() {
    sep
    info "Mode: WiFi Lokal (HP/laptop lain di WiFi sama)"
    start_server 8080
    local LOCAL_IP=$(get_local_ip)
    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Dari HP ini:"
    echo "    http://localhost:8080"
    echo ""
    if [ -n "$LOCAL_IP" ]; then
        echo "  Dari HP/laptop lain (1 WiFi):"
        echo -e "    ${GREEN}http://${LOCAL_IP}:8080${NC}"
        echo ""
        echo "  IP Lokal HP kamu: ${LOCAL_IP}"
    else
        echo "  Cek IP: ip addr"
        echo "  Lalu akses: http://IP_HP:8080"
    fi
    echo ""
    echo "  Stop: pkill -f 'node server'"
}

# ============================================================
#  DEPLOY: NGROK
# ============================================================
deploy_ngrok() {
    sep
    info "Mode: Ngrok"
    echo "  Butuh akun di https://ngrok.com"
    echo "  1. Daftar gratis di ngrok.com"
    echo "  2. Copy authtoken dari dashboard"
    echo "  3. Paste di bawah"
    echo ""

    # Install ngrok
    local NGROK_BIN
    if $IS_TERMUX; then
        NGROK_BIN="$PREFIX/bin/ngrok"
    else
        NGROK_BIN="$(command -v ngrok)"
    fi

    if [ -z "$NGROK_BIN" ] || [ ! -x "$NGROK_BIN" ]; then
        info "Install Ngrok..."
        if $IS_TERMUX; then
            pkg install wget -y
            # Termux ARM64
            wget -q "https://github.com/ngrok/ngrok/releases/latest/download/ngrok-v3-stable-linux-arm64.tgz" -O /tmp/ngrok.tgz 2>/dev/null || \
            wget -q "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz" -O /tmp/ngrok.tgz
            tar -xzf /tmp/ngrok.tgz -C "$PREFIX/bin/"
            chmod +x "$PREFIX/bin/ngrok"
            NGROK_BIN="$PREFIX/bin/ngrok"
        else
            wget -q "https://github.com/ngrok/ngrok/releases/latest/download/ngrok-v3-stable-linux-amd64.tgz" -O /tmp/ngrok.tgz 2>/dev/null || \
            wget -q "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" -O /tmp/ngrok.tgz
            tar -xzf /tmp/ngrok.tgz -C /usr/local/bin/
            chmod +x /usr/local/bin/ngrok
            NGROK_BIN="/usr/local/bin/ngrok"
        fi
    fi

    echo ""
    read -rp "  Masukkan Ngrok Authtoken: " NGROK_TOKEN
    [ -z "$NGROK_TOKEN" ] && fail "Authtoken tidak boleh kosong."

    mkdir -p ~/.config/ngrok
    cat > ~/.config/ngrok/ngrok.yml <<EOF
authtoken: ${NGROK_TOKEN}
region: ap
EOF

    start_server 8080

    pkill -f "ngrok" 2>/dev/null || true
    mkdir -p /tmp

    if $IS_TERMUX; then
        PATH="$PREFIX/bin:$PATH" "$NGROK_BIN" http 8080 > /tmp/amprem-ngrok.log 2>&1 &
    else
        "$NGROK_BIN" http 8080 > /tmp/amprem-ngrok.log 2>&1 &
    fi
    sleep 5

    local NGROK_URL=$(grep -oP 'https://[0-9a-f]+\.ngrok\.io' /tmp/amprem-ngrok.log 2>/dev/null | tail -1)

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    if [ -n "$NGROK_URL" ]; then
        echo "  URL PUBLIK:"
        echo -e "    ${GREEN}${BOLD}${NGROK_URL}${NC}"
    else
        echo "  URL belum muncul. Cek: cat /tmp/amprem-ngrok.log"
        echo "  Dashboard: https://dashboard.ngrok.com"
    fi
    echo ""
    echo "  Stop: pkill -f 'ngrok'"
}

# ============================================================
#  DEPLOY: CLOUDFLARE QUICK TUNNEL
# ============================================================
deploy_cf_quick() {
    sep
    info "Mode: Cloudflare Quick Tunnel"
    info "URL berubah setiap kali restart."

    if ! command -v cloudflared &>/dev/null; then
        fail "cloudflared belum terinstall. Install dulu."
    fi

    start_server 8080

    pkill -f "cloudflared" 2>/dev/null || true
    nohup cloudflared tunnel --url http://localhost:8080 > /tmp/amprem-tunnel.log 2>&1 &
    sleep 5

    local TUNNEL_URL=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/amprem-tunnel.log 2>/dev/null | tail -1)

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    if [ -n "$TUNNEL_URL" ]; then
        echo "  URL PUBLIK:"
        echo -e "    ${GREEN}${BOLD}${TUNNEL_URL}${NC}"
    else
        echo "  URL belum muncul."
        echo "  Cek: cat /tmp/amprem-tunnel.log"
        echo "  Tunggu 10 detik, lalu:"
        echo "    grep trycloudflare /tmp/amprem-tunnel.log"
    fi
    echo ""
    echo "  Stop: pkill -f 'cloudflared'"
}

# ============================================================
#  DEPLOY: CLOUDFLARE NAMED TUNNEL (DOMAIN)
# ============================================================
deploy_cf_named() {
    sep
    info "Mode: Cloudflare Named Tunnel (Domain Permanen)"
    info "SSL otomatis dari Cloudflare."

    if ! command -v cloudflared &>/dev/null; then
        fail "cloudflared belum terinstall."
    fi

    echo ""
    read -rp "  Masukkan domain (contoh: amprem.example.com): " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

    echo ""
    info "Login ke Cloudflare..."
    cloudflared tunnel login || warn "Login dibatalkan atau gagal."

    start_server 8080

    local TUNNEL_NAME="amprem-web"
    pkill -f "cloudflared" 2>/dev/null || true
    cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true
    cloudflared tunnel create "$TUNNEL_NAME" > /dev/null 2>&1

    local TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    [ -z "$TUNNEL_ID" ] && fail "Gagal buat tunnel. Pastikan sudah login."

    if $IS_TERMUX; then
        local CF_DIR="$HOME/.cloudflared"
    else
        local CF_DIR="/etc/cloudflared"
    fi
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
    echo "  Catatan: DNS CNAME mungkin perlu beberapa menit untuk propagasi."
    echo "  Stop: pkill -f 'cloudflared'"
}

# ============================================================
#  DEPLOY: LOCALTUNNEL
# ============================================================
deploy_localtunnel() {
    sep
    info "Mode: LocalTunnel"
    info "URL gratis, tanpa akun."

    # Cari lt path
    local LT_BIN
    if $IS_TERMUX; then
        LT_BIN="$PREFIX/bin/lt"
    else
        LT_BIN="$(command -v lt)"
    fi

    if [ -z "$LT_BIN" ] || [ ! -x "$LT_BIN" ]; then
        info "Install LocalTunnel..."
        if $IS_TERMUX; then
            npm install -g localtunnel 2>&1 | tail -3
            LT_BIN="$PREFIX/bin/lt"
        else
            npm install -g localtunnel 2>&1 | tail -3
            LT_BIN="$(command -v lt)"
        fi
    fi

    if [ -z "$LT_BIN" ] || [ ! -x "$LT_BIN" ]; then
        warn "LocalTunnel gagal install. Cek: npm install -g localtunnel"
    fi

    mkdir -p /tmp
    start_server 8080

    $IS_TERMUX && local LT_ENV="PATH=$PREFIX/bin:$PATH" || local LT_ENV=""

    eval "$LT_ENV $LT_BIN --port 8080" > /tmp/amprem-lt.log 2>&1 &
    sleep 10

    # Cari URL dari log
    local LT_URL
    LT_URL=$(grep -oP 'https://[a-z0-9-]+\.l\.tunnel\.cloud\.l\.google\.com' /tmp/amprem-lt.log 2>/dev/null | tail -1)

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    if [ -n "$LT_URL" ]; then
        echo "  URL PUBLIK:"
        echo -e "    ${GREEN}${BOLD}${LT_URL}${NC}"
        echo ""
        echo "  NOTE: Buka URL ini di browser SEKALI untuk bypass captcha."
        echo "  NOTE: URL berubah setiap sesi."
    else
        echo "  URL belum muncul. Cek: cat /tmp/amprem-lt.log"
    fi
    echo ""
    echo "  Stop: pkill -f 'localtunnel'"
}

# ============================================================
#  DEPLOY: PAGEKITE
# ============================================================
deploy_pagekite() {
    sep
    info "Mode: Pagekite"
    echo "  Butuh akun di https://pagekite.net"
    echo "  1. Daftar gratis di pagekite.net"
    echo "  2. Copy secret"
    echo ""

    # Install pagekite
    if ! command -v pagekite &>/dev/null; then
        info "Install Pagekite..."
        if $IS_TERMUX; then
            pip install pagekite 2>&1 | tail -3 || pip3 install pagekite 2>&1 | tail -3
        else
            pip install pagekite 2>&1 | tail -3 || pip3 install pagekite 2>&1 | tail -3
        fi
    fi

    local PK_BIN
    if $IS_TERMUX; then
        PK_BIN="$PREFIX/bin/pagekite"
    else
        PK_BIN="$(command -v pagekite)"
    fi

    if [ -z "$PK_BIN" ] || [ ! -x "$PK_BIN" ]; then
        fail "Pagekite gagal install. Cek: pip install pagekite"
    fi

    echo ""
    read -rp "  Masukkan Pagekite USERNAME/SECRET (format: username:secret): " PK_CFG
    [ -z "$PK_CFG" ] && fail "Config tidak boleh kosong."

    start_server 8080

    mkdir -p /tmp
    pkill -f "pagekite" 2>/dev/null || true

    if $IS_TERMUX; then
        PATH="$PREFIX/bin:$PATH" "$PK_BIN" 8080 :8080 $PK_CFG > /tmp/amprem-pk.log 2>&1 &
    else
        "$PK_BIN" 8080 :8080 $PK_CFG > /tmp/amprem-pk.log 2>&1 &
    fi
    sleep 5

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Cek URL di: cat /tmp/amprem-pk.log"
    echo "  Stop: pkill -f 'pagekite'"
}

# ============================================================
#  DEPLOY: SERVEO
# ============================================================
deploy_serveo() {
    sep
    info "Mode: Serveo SSH Tunnel"
    echo "  Gratis via SSH reverse tunnel. Tanpa akun."

    # Cek ssh ada
    local SSH_BIN
    if $IS_TERMUX; then
        SSH_BIN="$PREFIX/bin/ssh"
    else
        SSH_BIN="$(command -v ssh)"
    fi

    if [ -z "$SSH_BIN" ] || [ ! -x "$SSH_BIN" ]; then
        info "Install SSH..."
        if $IS_TERMUX; then
            pkg install openssh -y
            SSH_BIN="$PREFIX/bin/ssh"
        else
            apt install -y openssh-client 2>/dev/null || yum install -y openssh-clients
            SSH_BIN="$(command -v ssh)"
        fi
    fi

    start_server 8080

    mkdir -p /tmp
    pkill -f "serveo" 2>/dev/null || true

    echo ""
    read -rp "  Masukkan subdomain (kosongkan untuk random): " SERVEO_SUBDOMAIN
    local SERVEO_CMD
    if [ -n "$SERVEO_SUBDOMAIN" ]; then
        SERVEO_CMD="$SSH_BIN -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:8080 serveo.net -R ${SERVEO_SUBDOMAIN}:80:localhost:8080"
    else
        SERVEO_CMD="$SSH_BIN -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:8080 serveo.net"
    fi

    setsid $SERVEO_CMD > /tmp/amprem-serveo.log 2>&1 &
    sleep 8

    local SERVEO_URL=$(grep -oP 'https://[a-zA-Z0-9-]+\.serveo\.net' /tmp/amprem-serveo.log 2>/dev/null | tail -1)

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    if [ -n "$SERVEO_URL" ]; then
        echo "  URL PUBLIK:"
        echo -e "    ${GREEN}${BOLD}${SERVEO_URL}${NC}"
    else
        echo "  Cek log: cat /tmp/amprem-serveo.log"
        echo "  Serveo perlu SSH connection. Pastikan koneksi internet aktif."
    fi
    echo ""
    echo "  Stop: pkill -f 'serveo'"
}

# ============================================================
#  DEPLOY: DOMAIN + CLOUDFLARE PROXY (TERMUX)
# ============================================================
deploy_domain() {
    sep
    info "Mode: Domain + Cloudflare Proxy (Serve Langsung)"
    echo "  HTTPS via Cloudflare Proxy (orange cloud)."
    echo ""
    echo "  Cara setup:"
    echo "  1. Buka https://dash.cloudflare.com"
    echo "  2. Pilih domain kamu"
    echo "  3. DNS -> Add Record:"
    echo "     Type: A"
    echo "     Name: subdomain (nama sebelum titik)"
    echo "     IPv4: IP HP kamu"
    echo "     Proxy: ON (warna ORANGE/cloud)"
    echo ""
    local PUBLIC_IP=$(get_public_ip)
    echo "  IP Publik HP kamu: ${PUBLIC_IP:-<tidak terdeteksi>}"
    echo "  (Kalau tidak terdeteksi, cek: curl ifconfig.me)"
    echo ""

    local CF_DOMAIN
    read -rp "  Masukkan domain (contoh: amprem.example.com): " CF_DOMAIN
    CF_DOMAIN=$(echo "$CF_DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$CF_DOMAIN" ] && fail "Domain tidak boleh kosong."

    echo ""
    info "Pastikan DNS record sudah ditambah dengan Proxy ON."
    read -rp "  Sudah ditambah? [Y/n]: " CONFIRM
    [[ "$CONFIRM" =~ ^[Nn]$ ]] && fail "Dibatalkan."

    start_server 8080

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Domain:"
    echo -e "    ${GREEN}${BOLD}https://${CF_DOMAIN}${NC}"
    echo ""
    echo "  Catatan: HTTPS otomatis dari Cloudflare."
    echo "  IP HP kamu mungkin berubah - kalau tidak bisa diakses, update DNS A record."
    echo "  Stop: pkill -f 'node server'"
}

# ============================================================
#  DEPLOY: VPS IP + NGINX
# ============================================================
deploy_vps_ip() {
    sep
    info "Mode: VPS IP + Nginx Reverse Proxy"

    if ! command -v nginx &>/dev/null; then
        info "Install Nginx..."
        apt update -qq && apt install -y nginx
    fi

    local NGINX_CONF="/etc/nginx/sites-available/amprem"
    cat > "$NGINX_CONF" <<'EOF'
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

    start_server 3000

    local PUBLIC_IP=$(get_public_ip)

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Akses:"
    echo -e "    ${GREEN}http://${PUBLIC_IP}${NC}"
    echo ""
    echo "  Pastikan port 80 terbuka di firewall VPS:"
    echo "    sudo ufw allow 80"
    echo ""
    echo "  Manage:"
    echo "    sudo systemctl restart nginx   # restart Nginx"
    echo "    sudo systemctl status nginx    # cek status Nginx"
    echo "    cat /tmp/amprem.log           # log server"
}

# ============================================================
#  DEPLOY: VPS DOMAIN + NGINX + SSL
# ============================================================
deploy_vps_domain() {
    sep
    info "Mode: VPS Domain + Nginx + SSL"

    echo ""
    read -rp "  Masukkan domain: " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

    if ! command -v nginx &>/dev/null; then
        apt update -qq && apt install -y nginx
    fi

    local NGINX_CONF="/etc/nginx/sites-available/amprem"
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

    start_server 3000

    local PUBLIC_IP=$(get_public_ip)
    local DOMAIN_IP=$(dig +short "$DOMAIN" 2>/dev/null | head -1)

    sep
    if [ -n "$DOMAIN_IP" ] && [ "$DOMAIN_IP" = "$PUBLIC_IP" ]; then
        ok "DNS benar ($DOMAIN_IP)"
    else
        warn "DNS belum tepat. Domain resolve ke: ${DOMAIN_IP:-<kosong>}"
        warn "IP VPS: ${PUBLIC_IP:-<kosong>}"
        warn "Pastikan A record domain -> ${PUBLIC_IP}"
    fi

    echo ""
    read -rp "  Pasang SSL sekarang? [Y/n]: " DO_SSL
    if [[ ! "$DO_SSL" =~ ^[Nn]$ ]]; then
        if ! command -v certbot &>/dev/null; then
            apt install -y certbot python3-certbot-nginx
        fi
        certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos \
            --register-unsafely-without-email --redirect
        systemctl enable --now certbot-renew.timer 2>/dev/null || true
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | sort -u | crontab -
        ok "SSL aktif!"
    fi

    sep
    echo -e "${GREEN}  BERHASIL JALAN!${NC}"
    echo ""
    echo "  Domain:"
    echo -e "    ${GREEN}${BOLD}https://${DOMAIN}${NC}"
    echo ""
    echo "  Stop: pkill -f 'node server'"
}

# ============================================================
#  DEPLOY: VPS DOMAIN + CLOUDFLARE TUNNEL
# ============================================================
deploy_vps_cf_domain() {
    sep
    info "Mode: VPS Domain + Cloudflare Tunnel"

    echo ""
    read -rp "  Masukkan domain: " DOMAIN
    DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    [ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

    if ! command -v cloudflared &>/dev/null; then
        local ARCH=$(uname -m)
        case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; *) ARCH="arm" ;; esac
        curl -sL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -o /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi

    echo ""
    info "Login ke Cloudflare..."
    cloudflared tunnel login || warn "Login dibatalkan."

    start_server 3000

    local TUNNEL_NAME="amprem-web"
    pkill -f "cloudflared" 2>/dev/null || true
    cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true
    cloudflared tunnel create "$TUNNEL_NAME" > /dev/null 2>&1

    local TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    [ -z "$TUNNEL_ID" ] && fail "Gagal buat tunnel."

    mkdir -p /etc/cloudflared
    cat > /etc/cloudflared/config.yml <<EOF
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
    echo "  Stop: pkill -f 'cloudflared'"
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
    echo "  GitHub: https://github.com/yowbxz/amprem-web"
    sep
}

# ============================================================
#  MAIN MENU
# ============================================================
main_menu() {
    sep
    info "Menu Utama"
    echo ""
    echo "    I) Install         - Install semua dependencies"
    echo "    P) Project        - Install npm project"
    echo "    D) Deployment     - Pilih cara akses internet"
    echo "    C) Cek Status     - Lihat service yang jalan"
    echo "    R) Restart       - Restart server"
    echo "    X) Stop Semua    - Hentikan semua service"
    echo "    E) Edit Config   - Edit config.js"
    echo "    0) Keluar"
    echo ""
    read -rp "  Pilih: " PILIH

    case "$PILIH" in
        I|i) install_deps; main_menu ;;
        P|p) install_project; main_menu ;;
        D|d) deploy_menu ;;
        C|c) check_status; main_menu ;;
        R|r) start_server 8080; main_menu ;;
        X|x) stop_all; main_menu ;;
        E|e) edit_config; main_menu ;;
        0|*) all_done; exit 0 ;;
        *) warn "Pilihan tidak valid."; main_menu ;;
    esac
}

# ============================================================
#  RUN
# ============================================================
banner
echo "  Environment: $([ $IS_TERMUX = true ] && echo "Termux (HP Android)" || echo "VPS (Linux)")"
echo "  Project: $SCRIPT_DIR"
echo ""
main_menu
