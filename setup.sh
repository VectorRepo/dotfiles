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
