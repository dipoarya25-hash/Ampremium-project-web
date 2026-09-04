#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Setup Amprem Web di Termux dengan Domain
# Hasil: https://domain.com (via Cloudflare Tunnel)
# Jalankan: bash setup-termux-domain.sh
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PORT=8080

# ============================================================
#  Tanya domain
# ============================================================
echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  Termux + Domain Setup${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
read -rp "Masukkan domain (contoh: amprem.example.com): " DOMAIN
DOMAIN=$(echo "$DOMAIN" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
[ -z "$DOMAIN" ] && fail "Domain tidak boleh kosong."

# ============================================================
#  Tanya subdomain
# ============================================================
echo ""
read -rp "Login ke Cloudflare dulu. Lanjut? [y/N]: " DO_LOGIN
[[ ! "$DO_LOGIN" =~ ^[Yy]$ ]] && fail "Dibatalkan."

# ============================================================
#  Install dependencies
# ============================================================
echo ""
info "1/5 - Update Termux..."
pkg update -y

echo ""
info "2/5 - Install Node.js & nano..."
pkg install nodejs nano -y
ok "Node.js: $(node -v)"

# ============================================================
#  Install project
# ============================================================
echo ""
info "3/5 - Install project..."
cd "$SCRIPT_DIR"
if [ ! -d "node_modules" ]; then
    npm install
fi
ok "npm dependencies terinstall"

# ============================================================
#  Edit config
# ============================================================
echo ""
info "4/5 - Konfigurasi API Key..."
echo "  File: $SCRIPT_DIR/config.js"
echo "  amprem6ApiKey : komunitas (bisa ganti)"
echo "  amprem2ApiKey : WAJIB ISI kalau mau pakai Amprem2"
echo ""
read -rp "  Buka nano untuk edit config.js? [y/N]: " DO_EDIT
if [[ "$DO_EDIT" =~ ^[Yy]$ ]]; then
    nano "$SCRIPT_DIR/config.js"
fi

# ============================================================
#  Install cloudflared
# ============================================================
echo ""
info "5/5 - Install Cloudflare Tunnel..."
pkg install cloudflared -y 2>/dev/null || {
    # Fallback: download binary
    ARCH=$(uname -m)
    case "$ARCH" in
        aarch64|arm64) ARCH="arm64" ;;
        armv7l|armhf)  ARCH="arm" ;;
        x86_64|amd64)  ARCH="amd64" ;;
        *) fail "Arsitektur ${ARCH} tidak didukung." ;;
    esac
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
    curl -sL "$URL" -o "$PREFIX/bin/cloudflared"
    chmod +x "$PREFIX/bin/cloudflared"
}
ok "cloudflared: $(cloudflared --version 2>&1 | head -1)"

# ============================================================
#  Login Cloudflare
# ============================================================
echo ""
info "Login ke Cloudflare..."
echo "  Browser akan terbuka. Login dan pilih domain."
echo "  Tekan ENTER setelah selesai login."
read -rp ""
cloudflared tunnel login

# ============================================================
#  Buat tunnel
# ============================================================
echo ""
info "Buat tunnel..."
TUNNEL_NAME="amprem-web"
cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true
cloudflared tunnel create "$TUNNEL_NAME"

TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
[ -z "$TUNNEL_ID" ] && fail "Gagal membuat tunnel."

CF_DIR="$HOME/.cloudflared"
mkdir -p "$CF_DIR"
cat > "$CF_DIR/config.yml" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: ${CF_DIR}/${TUNNEL_ID}.json

ingress:
  - hostname: ${DOMAIN}
    service: http://localhost:${APP_PORT}
  - service: http_status:404
EOF

cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN"
ok "DNS record dibuat untuk ${DOMAIN}"

# ============================================================
#  Jalankan server
# ============================================================
echo ""
info "Menjalankan server..."

pkill -f "node server.js" 2>/dev/null || true
sleep 1

cd "$SCRIPT_DIR"
PORT=$APP_PORT nohup node server.js > /tmp/amprem-termux.log 2>&1 &
sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT}/ | grep -q "200"; then
    ok "Server jalan di port ${APP_PORT}"
else
    warn "Server belum responsif, tapi mungkin masih starting..."
    sleep 2
fi

# ============================================================
#  Jalankan tunnel
# ============================================================
echo ""
info "Menjalankan Cloudflare Tunnel..."
nohup cloudflared tunnel run "$TUNNEL_NAME" > /tmp/amprem-tunnel.log 2>&1 &
sleep 3

# ============================================================
#  Done
# ============================================================
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  SELESAI!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "  Domain  : https://${DOMAIN}"
echo "  Lokal   : http://localhost:${APP_PORT}"
echo ""
echo "  Stop semua:"
echo "    pkill -f 'node server'"
echo "    pkill -f 'cloudflared'"
echo ""
echo "  Start ulang:"
echo "    cd $SCRIPT_DIR && PORT=$APP_PORT node server.js &"
echo "    cloudflared tunnel run $TUNNEL_NAME &"
echo ""
echo "  Edit config:"
echo "    nano $SCRIPT_DIR/config.js"
echo ""
echo "  Log:"
echo "    cat /tmp/amprem-termux.log   # server log"
echo "    cat /tmp/amprem-tunnel.log   # tunnel log"
echo ""
echo -e "${GREEN}=========================================${NC}"
