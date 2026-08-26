#!/usr/bin/env bash

IMG_DIR="$HOME/.config/fastfetch/images"
CONFIG="$HOME/.config/fastfetch/config.jsonc"

# véletlen kép kiválasztása a mappából
RANDOM_IMG=$(find "$IMG_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)

if [ -z "$RANDOM_IMG" ]; then
    echo "Nem található kép a $IMG_DIR mappában!"
    fastfetch --config "$CONFIG"
    exit 0
fi

fastfetch --config "$CONFIG" \
    --logo-type kitty \
    --logo "$RANDOM_IMG" \
    --logo-width 30 \
    --logo-height 15
