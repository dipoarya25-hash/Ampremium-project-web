#!/bin/bash
# ============================================================
# Edit config.js secara interaktif
# Jalankan: bash config.sh
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.js"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

# ---------- Baca nilai config sekarang ----------
read_config() {
    AMPREM6_KEY=$(grep "amprem6ApiKey:" "$CONFIG_FILE" | sed "s/.*amprem6ApiKey:.*'\([^']*\)'.*/\1/")
    AMPREM2_KEY=$(grep "amprem2ApiKey:" "$CONFIG_FILE" | sed "s/.*amprem2ApiKey:.*'\([^']*\)'.*/\1/")
}

# ---------- Tampilkan menu ----------
show_menu() {
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  Edit Config - Amprem Web${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    echo "  File: $CONFIG_FILE"
    echo ""
    echo "  1) amprem6ApiKey : ${AMPREM6_KEY:0:15}..."
    echo "  2) amprem2ApiKey : ${AMPREM2_KEY:-<kosong>}"
    echo ""
    echo "  0) Keluar"
    echo ""
}

# ---------- Update config ----------
update_key() {
    local key_name="$1"
    local current_val="$2"
    local new_val

    echo ""
    echo -e "${YELLOW}[ ${key_name} ]${NC}"
    echo "  Nilai sekarang: ${current_val:-<kosong>}"
    echo "  Tekan ENTER untuk skip / tidak diubah"
    echo -n "  Masukkan nilai baru: "
    read new_val

    if [ -z "$new_val" ]; then
        warn "Dilewati. Nilai tetap: ${current_val:-<kosong>}"
        return
    fi

    # Escape special chars in value
    local escaped_val
    escaped_val=$(echo "$new_val" | sed "s/'/\\\\'/g")

    sed -i "s/\(${key_name}:.*'\)[^']*\('.*\)/\1${escaped_val}\2/" "$CONFIG_FILE"

    ok "Berhasil diupdate!"
}

# ==========================================================
#  MAIN
# ==========================================================

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} config.js tidak ditemukan di $CONFIG_FILE"
    exit 1
fi

# Parsing config dulu
read_config

while true; do
    read_config  # refresh
    show_menu
    read -rp "Pilih [0-2]: " PILIH

    case "$PILIH" in
        1) update_key "amprem6ApiKey" "$AMPREM6_KEY" ;;
        2) update_key "amprem2ApiKey" "$AMPREM2_KEY" ;;
        0|"")
            echo ""
            ok "Selesai."
            exit 0
            ;;
        *) warn "Pilihan tidak valid." ;;
    esac
done
