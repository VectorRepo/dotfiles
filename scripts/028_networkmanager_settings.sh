
#!/usr/bin/env bash

# This script configures NetworkManager to prevent Wi-Fi disconnections (WPS & Power Saving).
# --------------------------------------------------------------------------
# Arch Linux / Niri - Elite System Installer
# --------------------------------------------------------------------------

# --- 1. ENGINE & PRIVILEGES ---

if [[ $EUID -ne 0 ]]; then
    printf "Elevating privileges...\n"
    exec sudo "$0" "$@"
fi

set -u
set -o pipefail

BOLD=$(tput bold 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")

NM_CONF="/etc/NetworkManager/NetworkManager.conf"
NM_CONF_DIR="/etc/NetworkManager/conf.d"

printf "${BOLD}${CYAN}:: Configuring NetworkManager Stablity Fixes...${RESET}\n"

# --- 2. MAIN CONFIGURATION (NetworkManager.conf) ---

if [[ ! -f "$NM_CONF" ]]; then
    printf " ${YELLOW}[!] %s not found. Creating a blank one.${RESET}\n" "$NM_CONF"
    mkdir -p "$(dirname "$NM_CONF")"
    touch "$NM_CONF"
fi

# Elmentjük az eredeti fájlt biztonsági mentésként, ha még nem létezik mentés
if [[ ! -f "${NM_CONF}.bak" ]]; then
    cp "$NM_CONF" "${NM_CONF}.bak"
    printf " ${GREEN}[+] Created backup of NetworkManager.conf${RESET}\n"
fi

# Funkció az INI szekciók és kulcsok intelligens frissítésére/hozzáadására
update_nm_conf() {
    local section="$1"
    local key="$2"
    local value="$3"

    # Ha a szekció nem létezik, hozzuk létre a fájl végén
    if ! grep -q "^\[${section}\]" "$NM_CONF"; then
        echo -e "\n[${section}]" >> "$NM_CONF"
    fi

    # Ha a kulcs létezik a szekció alatt, frissítjük, ha nem, beszúrjuk alá
    if sed -n "/^\[${section}\]/,/^\[/p" "$NM_CONF" | grep -q "^${key}="; then
        # Trükk: Csak az adott szekción belüli kulcsot cseréljük
        sed -i "/^\[${section}\]/,/^\[/ {s/^${key}=.*/${key}=${value}/}" "$NM_CONF"
    else
        # Beszúrjuk a kulcs-értéket közvetlenül a szekció fejléc alá
        sed -i "/^\[${section}\]/a ${key}=${value}" "$NM_CONF"
    fi
}

# Beállítjuk a WPS letiltását és a wpa_supplicant backendet
printf " ${CYAN}[*] Patching WPS and backend settings...${RESET}\n"
update_nm_conf "device" "wifi.backend" "wpa_supplicant"
update_nm_conf "device-wps" "wifi.wps" "no"

# --- 3. SUB-CONFIGURATIONS (conf.d) ---

mkdir -p "$NM_CONF_DIR"

# 99-custom-wifi.conf létrehozása (MAC randomizáció és bgscan finomhangolás)
printf " ${CYAN}[*] Creating Wi-Fi optimization profiles in conf.d...${RESET}\n"

cat << 'EOF' > "${NM_CONF_DIR}/99-custom-wifi.conf"
[device]
wifi.scan-rand-mac-address=no

[connection]
wifi.cloned-mac-address=preserve

[wifi]
bgscan=simple:30:-45:300
EOF

# 00-powersave.conf létrehozása (Wi-Fi energiatakarékosság teljes kikapcsolása)
cat << 'EOF' > "${NM_CONF_DIR}/00-powersave.conf"
[connection]
wifi.powersave = 2
EOF

printf " ${GREEN}[+] Stability configuration files written successfully.${RESET}\n"

# --- 4. RELOAD & VERIFY ---

printf " ${CYAN}[*] Restarting NetworkManager to apply changes...${RESET}\n"

if systemctl is-active --quiet NetworkManager; then
    if systemctl restart NetworkManager; then
        printf "${GREEN} [OK] NetworkManager restarted and changes applied.${RESET}\n"
    else
        printf "${RED} [X] Failed to restart NetworkManager!${RESET}\n"
    fi
else
    printf "${YELLOW} [!] NetworkManager is not running currently. Configuration will load on next boot.${RESET}\n"
fi

printf "\n${BOLD}${GREEN}:: NETWORK CONFIGISTRATION COMPLETE ::${RESET}\n"
