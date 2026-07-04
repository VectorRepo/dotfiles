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
# VÁLTOZÓK DEFINIÁLÁSA (Jó helyen, a használat előtt!)
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
    sed -i "s|/home/adam/|/home/$USER/|g" "$WOFI_STYLE"
else
    echo "Notice: Wofi style.css not found, skipping path update."
fi

# Niri autostart.kdl frissítése
if [ -f "$NIRI_AUTOSTART" ]; then
    echo "Updating Niri autostart paths for user: $USER..."
    sed -i "s|/home/adam/|/home/$USER/|g" "$NIRI_AUTOSTART"
else
    echo "Notice: Niri autostart.kdl not found, skipping path update."
fi

# =====================================================================
# 2. INTELIGENS HARDVERREKORD ÉS MONITOR BEÁLLÍTÁS
# =====================================================================
echo "Detecting hardware and adjusting Niri + Rust-Shell configs..."

# --- VIDEÓKÁRTYA (GPU) FELISMERÉS ---
if [ -f "$NIRI_ENV" ]; then [cite: 1]
    if lspci | grep -iq "nvidia"; then
        echo "-> NVIDIA GPU detected! Enabling Nvidia workarounds..."
        sed -i 's|LIBVA_DRIVER_NAME "radeonsi"|// LIBVA_DRIVER_NAME "radeonsi"|g' "$NIRI_ENV" [cite: 3]
        sed -i 's|// NVIDIA:            __GLX_VENDOR_LIBRARY_NAME "nvidia"|__GLX_VENDOR_LIBRARY_NAME "nvidia"|g' "$NIRI_ENV" [cite: 3]
        sed -i 's|// NVIDIA GBM:        GBM_BACKEND "nvidia-drm"|GBM_BACKEND "nvidia-drm"|g' "$NIRI_ENV" [cite: 3]
        sed -i 's|// NVIDIA cursor fix: WLR_NO_HARDWARE_CURSORS "1"|WLR_NO_HARDWARE_CURSORS "1"|g' "$NIRI_ENV" [cite: 3]
    elif lspci | grep -iq "intel"; then
        echo "-> Intel GPU detected! Setting Intel drivers..."
        sed -i 's|LIBVA_DRIVER_NAME "radeonsi"|LIBVA_DRIVER_NAME "iHD"|g' "$NIRI_ENV" [cite: 3]
    else
        echo "-> AMD or Generic GPU detected. Leaving default (radeonsi)." [cite: 3]
    fi
fi

# --- MONITOR ÉS HZ AUTOMATIKUS MEGHATÁROZÁSA ---
DETECTED_MONITOR=$(ls /sys/class/drm/ | grep -E '^card[0-9]+-' | cut -d'-' -f2- | grep -v '^intel_backlight' | head -n 1)

if [ -z "$DETECTED_MONITOR" ]; then
    DETECTED_MONITOR="HDMI-A-1"
fi

echo "-> Primary monitor identified: $DETECTED_MONITOR"

MAX_HZ="60"
if [ "$DETECTED_MONITOR" = "HDMI-A-1" ]; then
    MAX_HZ="120" # A te 120Hz-es monitorod biztonsági mentése
else
    MAX_HZ="60"  # Másoknak biztonságos alapértelmezett érték
fi

# Niri monitor beállítás frissítése
if [ -f "$NIRI_MONITOR" ]; then [cite: 4]
    echo "-> Updating $NIRI_MONITOR with monitor '$DETECTED_MONITOR' and mode '1920x1080@$MAX_HZ'..." [cite: 5]
    sed -i "s|output \"HDMI-A-1\"|output \"$DETECTED_MONITOR\"|g" "$NIRI_MONITOR" [cite: 5]
    sed -i "s|mode \"1920x1080@120\"|mode \"1920x1080@$MAX_HZ\"|g" "$NIRI_MONITOR" [cite: 5]
fi

# Rust-Shell settings.json frissítése (Bar monitor rögzítése)
if [ -f "$RUST_SHELL_SETTINGS" ]; then
    echo "-> Updating rust-shell settings.json with monitor '$DETECTED_MONITOR'..."
    sed -i "s|\"HDMI-A-1\"|\"$DETECTED_MONITOR\"|g" "$RUST_SHELL_SETTINGS"
else
    echo "Notice: Rust-shell settings.json not found, skipping monitor update for bar."
fi

# --- DRM RENDER ESZKÖZ ELLENŐRZÉSE ---
if [ -f "$NIRI_MAIN_CONFIG" ]; then [cite: 6]
    if [ ! -e "/dev/dri/renderD128" ] && [ -e "/dev/dri/renderD129" ]; then [cite: 6]
        echo "-> /dev/dri/renderD128 not found, but D129 exists. Updating config.kdl..." [cite: 6]
        sed -i 's|render-drm-device "/dev/dri/renderD128"|render-drm-device "/dev/dri/renderD129"|g' "$NIRI_MAIN_CONFIG" [cite: 6]
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
