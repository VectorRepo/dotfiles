#!/usr/bin/env bash
# Safely reloads Niri configuration.
# (Hyprland 027_hyprctl_reload.sh megfelelője)

set -u

if (( EUID == 0 )); then
    printf 'Error: This script must run as user, not root.\n' >&2
    exit 1
fi

# Exit silently if Niri socket is missing (TTY/SSH)
if [[ -z "${NIRI_SOCKET:-}" ]] && ! command -v niri &>/dev/null; then
    exit 0
fi

# Próbáljuk megtalálni az aktív Niri socketet ha nincs env var
if [[ -z "${NIRI_SOCKET:-}" ]]; then
    # Niri socket: /run/user/<UID>/niri.*.sock
    local_socket=$(find "/run/user/${UID}" -name "niri.*.sock" 2>/dev/null | head -n1 || true)
    if [[ -z "$local_socket" ]]; then
        # Niri nem fut, csendes kilépés
        exit 0
    fi
    export NIRI_SOCKET="$local_socket"
fi

if timeout 5s niri msg action reload-config >/dev/null; then
    if command -v notify-send &>/dev/null; then
        notify-send "System Update" "Niri configuration reloaded" \
            -i system-software-update \
            -u low \
            -t 3000 \
            -a "Update Script" &>/dev/null || true
    fi
    printf '%s[OK   ]%s Niri config reloaded.\n' $'\e[1;32m' $'\e[0m'
else
    printf '%s[WARN ]%s Niri reload timed out or failed.\n' $'\e[1;33m' $'\e[0m' >&2
    exit 0
fi
