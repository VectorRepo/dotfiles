#!/usr/bin/env bash

BLUR_DIR="$HOME/.config/niri/main/Blur"
TARGET="$HOME/.config/niri/main/blur.kdl"

CURRENT="$(readlink "$TARGET")"

if [[ "$CURRENT" == *"blur_on.kdl" ]]; then
    ln -sf "$BLUR_DIR/blur_off.kdl" "$TARGET"
    # notify-send "Niri Blur" "Blur kikapcsolva"
else
    ln -sf "$BLUR_DIR/blur_on.kdl" "$TARGET"
    # notify-send "Niri Blur" "Blur bekapcsolva"
fi

# Niri config újratöltése
niri msg action load-config-file
