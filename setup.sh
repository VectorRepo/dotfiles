#!/bin/bash

echo "Starting setup..."

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Copying files to HOME..."

# Biztosítsuk, hogy a célmappák léteznek
mkdir -p ~/scripts
mkdir -p ~/.config
mkdir -p ~/.local
mkdir -p ~/Pictures

# Fájlok és mappák másolása
rsync -av --progress "$DOTFILES_DIR"/ORCHESTRA.sh ~/ORCHESTRA.sh
rsync -av --progress "$DOTFILES_DIR"/scripts/ ~/scripts/
rsync -av --progress "$DOTFILES_DIR"/.config/ ~/.config/
rsync -av --progress "$DOTFILES_DIR"/.local/ ~/.local/
rsync -av --progress "$DOTFILES_DIR"/.zshrc ~/.zshrc
rsync -av --progress "$DOTFILES_DIR"/.zprofile ~/.zprofile
rsync -av --progress "$DOTFILES_DIR"/Pictures/ ~/Pictures/

# =====================================================================
# VÁLTOZÓK DEFINIÁLÁSA
# =====================================================================
WOFI_STYLE="$HOME/.config/wofi/style.css"
NIRI_AUTOSTART="$HOME/.config/niri/main/autostart.kdl"
NIRI_ENV="$HOME/.config/niri/main/environment.kdl"
NIRI_MONITOR="$HOME/.config/niri/main/monitor.kdl"
NIRI_MAIN_CONFIG="$HOME/.config/niri/config.kdl"
RUST_SHELL_SETTINGS="$HOME/.config/rust-shell/settings.json"

# =====================================================================
# 1. FELHASZNÁLÓNÉV TESTRESZABÁSA (adam -> aktuális felhasználó)
# =====================================================================
# Wofi CSS útvonalak frissítése
if [ -f "$WOFI_STYLE" ]; then
    echo "Updating Wofi paths for user: $USER..."
    sed -i "s|/home/USERNAME/|/home/$USER/|g" "$WOFI_STYLE"
else
    echo "Notice: Wofi style.css not found, skipping path update."
fi

# Niri autostart.kdl frissítése
if [ -f "$NIRI_AUTOSTART" ]; then
    echo "Updating Niri autostart paths for user: $USER..."
    sed -i "s|/home/USERNAME/|/home/$USER/|g" "$NIRI_AUTOSTART"
else
    echo "Notice: Niri autostart.kdl not found, skipping path update."
fi

# =====================================================================
# 2. INTELIGENS HARDVERREKORD ÉS MONITOR BEÁLLÍTÁS
# =====================================================================
echo "Detecting hardware and adjusting Niri + Rust-Shell configs..."

# --- VIDEÓKÁRTYA (GPU) FELISMERÉS ---
if [ -f "$NIRI_ENV" ]; then
    if lspci | grep -iq "nvidia"; then
        echo "-> NVIDIA GPU detected! Enabling Nvidia workarounds..."
        sed -i 's|LIBVA_DRIVER_NAME "radeonsi"|// LIBVA_DRIVER_NAME "radeonsi"|g' "$NIRI_ENV"
        sed -i 's|// NVIDIA:            __GLX_VENDOR_LIBRARY_NAME "nvidia"|__GLX_VENDOR_LIBRARY_NAME "nvidia"|g' "$NIRI_ENV"
        sed -i 's|// NVIDIA GBM:        GBM_BACKEND "nvidia-drm"|GBM_BACKEND "nvidia-drm"|g' "$NIRI_ENV"
        sed -i 's|// NVIDIA cursor fix: WLR_NO_HARDWARE_CURSORS "1"|WLR_NO_HARDWARE_CURSORS "1"|g' "$NIRI_ENV"
    elif lspci | grep -iq "intel"; then
        echo "-> Intel GPU detected! Setting Intel drivers..."
        sed -i 's|LIBVA_DRIVER_NAME "radeonsi"|LIBVA_DRIVER_NAME "iHD"|g' "$NIRI_ENV"
    else
        echo "-> AMD or Generic GPU detected. Leaving default (radeonsi)."
    fi
fi

# --- MONITOR ÉS HZ AUTOMATIKUS MEGHATÁROZÁSA (Precíziós verzió) ---
echo "Querying active displays..."

DETECTED_MONITOR=""
MAX_HZ=""

# 1. Megpróbáljuk a futó Niri-ből kiszedni az élő adatokat
if command -v niri &>/dev/null && niri msg outputs &>/dev/null; then
    DETECTED_MONITOR=$(niri msg outputs | grep -E '^Output ' | head -n 1 | awk '{print $NF}' | tr -d '()')
    MAX_HZ=$(niri msg outputs | awk -v mon="($DETECTED_MONITOR)" '
        $0 ~ mon {p=1; next} 
        /^Output / {p=0} 
        p && /@[0-9]/ {print $0}' | awk -F'@' '{print $2}' | awk '{print $1}' | sort -nr | head -n 1 | cut -d'.' -f1)
fi

# 2. Ha a Niri nem fut, megnézzük a sysfs-t, de CSAK a connected (aktív) monitorokat keresve!
if [ -z "$DETECTED_MONITOR" ]; then
    for d in /sys/class/drm/card*-[A-Za-z0-9]*; do
        if [ -f "$d/status" ] && grep -q '^connected' "$d/status"; then
            # Letisztítjuk a cardX előtagot az elejéről, megkapva a pontos nevet (pl: eDP-2 vagy HDMI-A-1)
            DETECTED_MONITOR=$(basename "$d" | sed 's/^card[0-9]\+-//')
            break
        fi
    done
fi

# 3. Biztonsági mentőöv (Fallback), ha minden kötél szakad
if [ -z "$DETECTED_MONITOR" ]; then
    DETECTED_MONITOR="HDMI-A-1"
fi

# 4. Intelligens Hz meghatározás, ha szoftveresen nem sikerült (pl. tiszta TTY-ból telepítéskor)
if [ -z "$MAX_HZ" ] || [ "$MAX_HZ" -lt 60 ]; then
    if [[ "$DETECTED_MONITOR" == *"eDP"* ]]; then
        MAX_HZ="144" # Laptop kijelzőnek (eDP-2) 144Hz
    elif [ "$DETECTED_MONITOR" = "HDMI-A-1" ]; then
        MAX_HZ="120" # A te külső monitorod alapértelmezett értéke
    else
        MAX_HZ="60"  # Minden más ismeretlen monitorra biztonsági 60Hz
    fi
fi

echo "-> Primary monitor identified: $DETECTED_MONITOR"
echo "-> Refresh rate set to: ${MAX_HZ}Hz"

# Niri monitor beállítás frissítése
if [ -f "$NIRI_MONITOR" ]; then
    echo "-> Updating $NIRI_MONITOR with monitor '$DETECTED_MONITOR' and mode '1920x1080@$MAX_HZ'..."
    sed -i "s|output \"HDMI-A-1\"|output \"$DETECTED_MONITOR\"|g" "$NIRI_MONITOR"
    sed -i "s|mode \"1920x1080@120\"|mode \"1920x1080@$MAX_HZ\"|g" "$NIRI_MONITOR"
fi

# Rust-Shell settings.json frissítése (Bar monitor rögzítése)
if [ -f "$RUST_SHELL_SETTINGS" ]; then
    echo "-> Updating rust-shell settings.json with monitor '$DETECTED_MONITOR'..."
    sed -i "s|\"HDMI-A-1\"|\"$DETECTED_MONITOR\"|g" "$RUST_SHELL_SETTINGS"
else
    echo "Notice: Rust-shell settings.json not found, skipping monitor update for bar."
fi

# --- DRM RENDER ESZKÖZ ELLENŐRZÉSE ---
if [ -f "$NIRI_MAIN_CONFIG" ]; then
    if [ ! -e "/dev/dri/renderD128" ] && [ -e "/dev/dri/renderD129" ]; then
        echo "-> /dev/dri/renderD128 not found, but D129 exists. Updating config.kdl..."
        sed -i 's|render-drm-device "/dev/dri/renderD128"|render-drm-device "/dev/dri/renderD129"|g' "$NIRI_MAIN_CONFIG"
    fi
fi
# =====================================================================

echo "Setting permissions..."

# ORCHESTRA futtathatóvá tétele
chmod +x ~/ORCHESTRA.sh

# Scripts mappa fájljainak futtathatóvá tétele (csak ha léteznek)
if [ -d ~/scripts ]; then
    chmod +x ~/scripts/*
fi

echo "Running ORCHESTRA..."

# ORCHESTRA futtatása, ha létezik
if [ -f ~/ORCHESTRA.sh ]; then
    ~/ORCHESTRA.sh
else
    echo "ERROR: ORCHESTRA.sh not found!"
    exit 1
fi

echo "Setup complete."
