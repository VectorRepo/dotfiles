#!/usr/bin/env bash
# Enables user services for AUR packages (Niri stack)
# ==============================================================================

set -euo pipefail

readonly TARGET_USER_SERVICES=(
  #"swayidle.service"
  "skwd-daemon.service"
)

readonly C_RESET=$'\e[0m'
readonly C_BOLD=$'\e[1m'
readonly C_GREEN=$'\e[32m'
readonly C_YELLOW=$'\e[33m'
readonly C_RED=$'\e[31m'
readonly C_BLUE=$'\e[34m'
readonly C_PURPLE=$'\e[35m'

log_info()    { printf "${C_BLUE}[INFO]${C_RESET}  %s\n" "$1"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}    %s\n" "$1"; }
log_warn()    { printf "${C_YELLOW}[SKIP]${C_RESET}  %s\n" "$1"; }
log_err()     { printf "${C_RED}[FAIL]${C_RESET}  %s\n" "$1"; }
log_crit()    { printf "${C_RED}${C_BOLD}[ERROR]${C_RESET} %s\n" "$1"; }

cleanup() { printf "%s" "${C_RESET}"; }
trap cleanup EXIT INT TERM

if [[ $EUID -eq 0 ]]; then
  log_crit "Do NOT run this script as root/sudo."
  exit 1
fi

main() {
  printf "\n${C_BOLD}Starting User Service Initialization (Niri)...${C_RESET}\n"
  printf "${C_BOLD}-------------------------------------------------------${C_RESET}\n"

  local svc_name
  for svc_name in "${TARGET_USER_SERVICES[@]}"; do
    if systemctl --user list-unit-files "$svc_name" &>/dev/null; then
      if output=$(systemctl --user enable --now "$svc_name" 2>&1); then
        log_success "Enabled & Started: ${C_PURPLE}$svc_name${C_RESET}"
      else
        log_err "Could not enable $svc_name. Reason:"
        printf "      %s\n" "$output"
      fi
    else
      log_warn "Service not found: ${C_PURPLE}$svc_name${C_RESET}. Skipping..."
    fi
  done

  printf "${C_BOLD}-------------------------------------------------------${C_RESET}\n"
  log_info "User services updated."
  printf "\n"
}

main "$@"
