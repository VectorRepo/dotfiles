#!/usr/bin/env bash
# Niri theme bootstrap — gtk theme beállítás

set -euo pipefail

# ==============================================================================
# KONFIGURÁCIÓ — csak ezeket kell módosítani
# ==============================================================================
GTK_THEME="adw-gtk3"
ICON_THEME="Papirus"
COLOR_SCHEME="prefer-dark"

BLUR_DIR="$HOME/.config/niri/main/Blur"
BLUR_TARGET="$HOME/.config/niri/main/blur.kdl"
# ==============================================================================

log() { printf '[012_theme_ctl] %s\n' "$*" >&2; }

# ── GTK Theme & Color Scheme ──────────────────────────────────────────────────
log "Setting GTK theme: $GTK_THEME"
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

log "Setting color scheme: $COLOR_SCHEME"
gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME"

log "Setting icon theme: $ICON_THEME"
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"

# ── Blur alapértelmezés: blur_off ─────────────────────────────────────────────
if [[ -f "$BLUR_DIR/blur_off.kdl" ]]; then
    ln -sf "$BLUR_DIR/blur_off.kdl" "$BLUR_TARGET"
    log "Blur set to OFF (default)"
else
    log "WARNING: $BLUR_DIR/blur_off.kdl not found — skipping blur setup"
fi

log "Done."
