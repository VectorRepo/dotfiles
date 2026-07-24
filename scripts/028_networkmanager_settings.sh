#!/usr/bin/env bash
# Disable NetworkManager Wi-Fi power saving permanently

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
CONF_FILE="/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"

GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m'

log() { printf "${GREEN}[018_wifi_powersave_off]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[018_wifi_powersave_off] [WARN]${NC} %s\n" "$*" >&2; }
err() { printf "${RED}[018_wifi_powersave_off] [ERROR]${NC} %s\n" "$*" >&2; }

# ==============================================================================
# MAIN LOGIC
# ==============================================================================

# 1. Root jogosultság ellenőrzése (mivel az Orchestrator 'S' módban hívja meg)
if [[ $EUID -ne 0 ]]; then
   err "This script must be run with root privileges (sudo)."
   exit 1
fi

log "Configuring NetworkManager Wi-Fi power save mode..."

# 2. Célkönyvtár meglétének ellenőrzése / létrehozása
CONF_DIR="$(dirname "$CONF_FILE")"
if [[ ! -d "$CONF_DIR" ]]; then
    log "Creating directory: $CONF_DIR"
    mkdir -p "$CONF_DIR"
fi

# 3. Konfigurációs fájl megírása
# wifi.powersave = 2 jelentése: 2 (Disable Wi-Fi power save)
log "Writing configuration to $CONF_FILE"
cat << 'EOF' > "$CONF_FILE"
[connection]
wifi.powersave = 2
EOF

# 4. Jogosultságok beállítása (root:root, 644)
chmod 644 "$CONF_FILE"
chown root:root "$CONF_FILE"

# 5. NetworkManager újraindítása (ha fut a service), hogy azonnal érvénybe lépjen
if systemctl is-active --quiet NetworkManager; then
    log "Restarting NetworkManager service to apply changes..."
    systemctl restart NetworkManager
else
    warn "NetworkManager service is not active. Changes will take effect upon start/reboot."
fi

log "Wi-Fi power save disabled successfully."
