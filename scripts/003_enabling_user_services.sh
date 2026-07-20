#!/usr/bin/env bash
# Enables user services for Niri
# ==============================================================================

set -euo pipefail

readonly C_RESET=$'\e[0m'
readonly C_GREEN=$'\e[1;32m'
readonly C_RED=$'\e[1;31m'
readonly C_BLUE=$'\e[1;34m'
readonly C_YELLOW=$'\e[1;33m'
readonly C_BOLD=$'\e[1m'

log() {
    local level="$1"
    local message="$2"
    case "$level" in
        INFO)    printf "${C_BLUE}[INFO]${C_RESET}  %s\n" "$message" ;;
        SUCCESS) printf "${C_GREEN}[OK]${C_RESET}    %s\n" "$message" ;;
        WARN)    printf "${C_YELLOW}[WARN]${C_RESET}  %s\n" "$message" ;;
        ERROR)   printf "${C_RED}[FAIL]${C_RESET}  %s\n" "$message" ;;
    esac
}

if [[ $EUID -eq 0 ]]; then
    log ERROR "Do NOT run user service scripts as root."
    exit 1
fi

services=(
    "gnome-keyring-daemon.service"
    "gnome-keyring-daemon.socket"
    "swaync.service" 
)

main() {
    log INFO "Initializing Niri User Service Setup..."

    local success_count=0
    local fail_count=0

    for unit in "${services[@]}"; do
        if ! systemctl --user list-unit-files "$unit" &>/dev/null; then
             log WARN "Unit ${C_BOLD}$unit${C_RESET} not found. Skipped."
             fail_count=$((fail_count + 1))
             continue
        fi

        if output=$(systemctl --user enable --now "$unit" 2>&1); then
            log SUCCESS "Enabled: ${C_BOLD}$unit${C_RESET}"
            success_count=$((success_count + 1))
        else
            log ERROR "Failed: ${C_BOLD}$unit${C_RESET}"
            printf "      └─ %s\n" "$output"
            fail_count=$((fail_count + 1))
        fi
    done

    printf "\n"
    log INFO "Done. Success: ${success_count} | Skipped/Failed: ${fail_count}"
    systemctl --user daemon-reload
}

main
