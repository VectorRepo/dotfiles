#!/usr/bin/env bash

# This script installs ALL PACKAGES for the Niri stack.
# --------------------------------------------------------------------------
# Arch Linux / Niri - Elite System Installer
# --------------------------------------------------------------------------

# --- 1. CONFIGURATION ---

# Group 2: Niri Core
pkgs_niri=(
    "niri" "xwayland-satellite" "xdg-desktop-portal" "xdg-desktop-portal-gnome" 
    "xorg-xhost" "polkit" "polkit-gnome" "xdg-utils" "socat" "inotify-tools" "file"
    "bash" "coreutils" "gawk" "sed" "grep" "desktop-file-utils"
)

# Group 3: GUI, Toolkits & Fonts
pkgs_appearance=(
    "qt5-wayland" "qt6-wayland" "gtk3" "gtk4" "nwg-look" "qt5ct" "qt6ct" "qt6-svg"
    "qt6-multimedia" "qt6-declarative" "qt6-imageformats" "adw-gtk-theme" "matugen" "ttf-font-awesome"
    "ttf-nerd-fonts-symbols" "ttf-roboto" "papirus-icon-theme" "adwaita-qt6" "adwaita-qt5"
)

# Group 4: Desktop Experience
pkgs_desktop=(
    "quickshell" "swaylock" "swayidle" "brightnessctl" "libdbusmenu-qt5"
    "libdbusmenu-glib" "python" "wofi" "swaync"
)

# Group 6: Filesystem & Archives
pkgs_filesystem=(
    "udisks2" "udiskie" "gvfs" "gvfs-mtp" "xdg-user-dirs"
    "7zip" "cpio" "rsync"  "doublecmd-qt6"
    "tumbler" "ffmpegthumbnailer" "webp-pixbuf-loader" "poppler-glib"
)

# thunar thunar-volman 

pkgs_network=(
    "nm-connection-editor"
)

# Group 8: Terminal & Shell
pkgs_terminal=(
    "kitty" "zsh" "zsh-syntax-highlighting" "starship" "fastfetch" "bat" "eza" "fd"
    "tealdeer" "gum" "man-db" "tree" "fzf" "less" "ripgrep" "expac"
    "zsh-autosuggestions" "iperf3" "pkgstats" "libqalculate" "yad"
)

# Group 9: Development
pkgs_dev=(
    "neovim" "npm" "meson" "cmake" "clang" "uv" "rq" "jq" "bc" "ueberzugpp" "ccache"
    "mold" "shellcheck" "shfmt" "stylua" "prettier" "tree-sitter-cli"
)

# Group 10: Multimedia
pkgs_multimedia=(
    "ffmpeg" "mpv" "zen-browser-bin" "swayimg" "resvg" "imagemagick" "libheif"
    "wl-clipboard" "cliphist" "vesktop" "steam" "cachyos-gaming-meta" "keepassxc"
)

# Group 11: Sys Admin
pkgs_sysadmin=(
    "pacman-contrib" "gnome-keyring"
)

# --------------------------------------------------------------------------

# --- 2. ENGINE ---

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

install_group() {
    local group_name="$1"
    shift
    local -n pkgs="$1"

    [[ ${#pkgs[@]} -eq 0 ]] && return

    printf "\n${BOLD}${CYAN}:: Processing Group: %s${RESET}\n" "$group_name"

    if pacman -S --needed --noconfirm "${pkgs[@]}"; then
        printf "${GREEN} [OK] Batch installation successful.${RESET}\n"
        return 0
    fi

    printf "\n${YELLOW} [!] Batch transaction failed. Retrying individually...${RESET}\n"
    local fail_count=0

    for pkg in "${pkgs[@]}"; do
        if pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
            printf " ${GREEN}[+] Installed:${RESET} %s\n" "$pkg"
        else
            printf " ${YELLOW}[?] Intervention Needed:${RESET} %s\n" "$pkg"
            if pacman -S --needed "$pkg"; then
                printf " ${GREEN}[+] Installed (Manual):${RESET} %s\n" "$pkg"
            else
                printf " ${RED}[X] Not Found / Failed:${RESET} %s\n" "$pkg"
                ((fail_count++))
            fi
        fi
    done

    if [[ $fail_count -gt 0 ]]; then
        printf "${YELLOW} [!] Group completed with %d failures.${RESET}\n" "$fail_count"
    else
        printf "${GREEN} [OK] Recovery successful.${RESET}\n"
    fi
}

# --- 3. EXECUTION ---

printf "${BOLD}:: Full System Upgrade...${RESET}\n"
pacman -Syu --noconfirm || printf "${YELLOW}[!] Upgrade skipped or failed.${RESET}\n"

install_group "Niri Core"          pkgs_niri
install_group "GUI Appearance"     pkgs_appearance
install_group "Desktop Experience" pkgs_desktop
install_group "Filesystem Tools"   pkgs_filesystem
install_group "Networking"         pkgs_network
install_group "Terminal & CLI"     pkgs_terminal
install_group "Development"        pkgs_dev
install_group "Multimedia"         pkgs_multimedia
install_group "System Admin"       pkgs_sysadmin

printf "\n${BOLD}${GREEN}:: INSTALLATION COMPLETE ::${RESET}\n"
printf "Reboot is recommended to load new drivers and Niri env vars.\n"
