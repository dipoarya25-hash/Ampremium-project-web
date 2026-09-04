#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Setup akses publik Amprem Web - KHUSUS TERMUX
# Tidak perlu root, tidak pakai systemd/nginx.
#
# Jalankan: bash setup-termux.sh
# ============================================================

set -e

APP_PORT=8080
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# ---------- Cek Termux ----------
if [ ! -d "/data/data/com.termux" ]; then
    warn "Script ini khusus Termux. Untuk VPS, pakai: sudo bash setup-nginx.sh"
fi

# ---------- Install dependencies ----------
install_deps() {
    info "Update dan install dependencies..."
    pkg update -y
    pkg install -y nodejs nano

    if ! command -v node &>/dev/null; then
        fail "Node.js gagal diinstall."
    fi
    ok "Node.js terinstall: $(node -v)"

    # Install npm dependencies
    cd "$SCRIPT_DIR"
    if [ ! -d "node_modules" ]; then
        info "Install npm packages..."
        npm install
    fi
    ok "npm dependencies OK."
}

# ---------- Install cloudflared ----------
install_cloudflared_termux() {
    if command -v cloudflared &>/dev/null; then
        ok "cloudflared sudah ada: $(cloudflared --version 2>&1 | head -1)"
        return 0
    fi

    info "Install cloudflared di Termux..."
    pkg install -y cloudflared 2>/dev/null || {
        # Kalau gagal via pkg, coba via binary
        local ARCH
        ARCH=$(uname -m)
        case "$ARCH" in
            aarch64|arm64) ARCH="arm64" ;;
            armv7l|armhf)  ARCH="arm" ;;
            x86_64|amd64)  ARCH="amd64" ;;
            *) fail "Arsitektur ${ARCH} tidak didukung." ;;
        esac
        local URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
        curl -sL "$URL" -o "$PREFIX/bin/cloudflared"
        chmod +x "$PREFIX/bin/cloudflared"
    }

    if ! cloudflared --version &>/dev/null; then
        fail "cloudflared gagal diinstall."
    fi
    ok "cloudflared terinstall."
}

# ---------- Cek IP lokal ----------
get_local_ip() {
    ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[0-9.]+' || \
    ifconfig 2>/dev/null | grep -oP 'inet \K[0-9.]+' | grep -v '127.0.0.1' | head -1 || \
    echo ""
}

# ---------- Jalankan server Node.js ----------
start_node() {
    # Kill server lama kalau ada
    pkill -f "node server.js" 2>/dev/null || true
    sleep 1

    cd "$SCRIPT_DIR"
    PORT=$APP_PORT node server.js &
    NODE_PID=$!
    sleep 2

    if kill -0 $NODE_PID 2>/dev/null; then
        ok "Node.js server jalan (PID: $NODE_PID) di port $APP_PORT"
        return 0
    else
        fail "Node.js server gagal start. Cek error di atas."
    fi
}

# ---------- Quick tunnel (tanpa login) ----------
run_quick_tunnel() {
    info "Menjalankan Cloudflare Quick Tunnel..."
    warn "URL random *.trycloudflare.com - BERUBAH tiap restart."
    echo ""
    info "Tekan Ctrl+C untuk stop."
    echo ""

    cloudflared tunnel --url http://localhost:${APP_PORT} --no-autoupdate
}

# ---------- Named tunnel ----------
run_named_tunnel() {
    echo ""
    read -rp "Masukkan domain (contoh: amprem.domain.com): " CF_DOMAIN
    CF_DOMAIN=$(echo "$CF_DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    if [ -z "$CF_DOMAIN" ]; then
        fail "Domain tidak boleh kosong."
    fi

    info "Login ke Cloudflare dulu..."
    cloudflared tunnel login

    local tunnel_name="amprem-web"
    cloudflared tunnel delete "$tunnel_name" 2>/dev/null || true
    cloudflared tunnel create "$tunnel_name"

    local TUNNEL_ID
    TUNNEL_ID=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}')
    if [ -z "$TUNNEL_ID" ]; then
        fail "Gagal membuat tunnel."
    fi

    local CF_DIR="$HOME/.cloudflared"
    mkdir -p "$CF_DIR"
    cat > "$CF_DIR/config.yml" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: ${CF_DIR}/${TUNNEL_ID}.json

ingress:
  - hostname: ${CF_DOMAIN}
    service: http://localhost:${APP_PORT}
  - service: http_status:404
EOF

    cloudflared tunnel route dns "$tunnel_name" "$CF_DOMAIN"

    ok "Tunnel siap!"
    echo ""
    echo -e "${GREEN}  URL: https://${CF_DOMAIN}${NC}"
    echo ""
    info "Menjalankan tunnel... (Ctrl+C untuk stop)"
    cloudflared tunnel run "$tunnel_name"
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
        echo ""
        echo "  1) nano"
        echo "  2) vi"
        echo "  3) cat (baca saja)"
        echo ""
        read -rp "  Pilih editor [1]: " EDITOR_CHOICE
        case "$EDITOR_CHOICE" in
            2) vim "$CONFIG_FILE" 2>/dev/null || vi "$CONFIG_FILE" ;;
            3) cat "$CONFIG_FILE" ;;
            *) nano "$CONFIG_FILE" ;;
        esac
        echo ""
        echo "  Config sudah disimpan."
    fi
fi

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  Amprem Web - Setup Termux${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

install_deps

echo ""
echo -e "${YELLOW}Pilih cara akses:${NC}"
echo "  1) Lokal saja   - akses dari HP ini di http://localhost:${APP_PORT}"
echo "  2) WiFi lokal   - akses dari perangkat lain di WiFi yang sama"
echo "  3) Cloudflare   - akses dari internet (Quick Tunnel, URL random)"
echo "  4) Cloudflare   - akses dari internet (Named Tunnel, URL permanen + domain)"
echo ""
read -rp "Pilih [1/2/3/4]: " MODE

case "$MODE" in
    1)
        start_node
        echo ""
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}  JALAN!${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo ""
        echo "  Buka browser di HP ini:"
        echo "    http://localhost:${APP_PORT}"
        echo ""
        echo "  Stop server: kill $NODE_PID"
        echo ""
        ;;

    2)
        start_node
        LOCAL_IP=$(get_local_ip)
        echo ""
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}  JALAN!${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo ""
        echo "  Dari HP ini:"
        echo "    http://localhost:${APP_PORT}"
        echo ""
        if [ -n "$LOCAL_IP" ]; then
            echo "  Dari perangkat lain (1 WiFi):"
            echo "    http://${LOCAL_IP}:${APP_PORT}"
        else
            warn "Tidak bisa deteksi IP lokal."
            echo "  Cek IP manual: ip addr | grep inet"
            echo "  Lalu akses: http://<IP_HP>:${APP_PORT}"
        fi
        echo ""
        echo "  Stop server: kill $NODE_PID"
        echo ""
        ;;

    3)
        install_cloudflared_termux
        start_node
        echo ""
        run_quick_tunnel
        ;;

    4)
        install_cloudflared_termux
        start_node
        echo ""
        run_named_tunnel
        ;;

    *)
        fail "Pilihan tidak valid."
        ;;
esac

echo -e "${GREEN}=========================================${NC}"
