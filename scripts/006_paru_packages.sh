#!/usr/bin/env bash
# ==============================================================================
# Script Name: install_pkg_manifest_shelly.sh
# Description: Autonomous AUR/Repo package installer using Shelly (no paru/yay).
# Context:     Arch Linux (Rolling) | Hyprland
# ==============================================================================

set -uo pipefail

# ------------------------------------------------------------------------------
# VISUALS & LOGGING
# ------------------------------------------------------------------------------
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_CYAN=$'\033[1;36m'

log_info()    { printf "%s[INFO]%s %s\n" "${C_BLUE}" "${C_RESET}" "$*"; }
log_success() { printf "%s[SUCCESS]%s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
log_warn()    { printf "%s[WARN]%s %s\n" "${C_YELLOW}" "${C_RESET}" "$*" >&2; }
log_err()     { printf "%s[ERROR]%s %s\n" "${C_RED}" "${C_RESET}" "$*" >&2; }
log_task()    { printf "\n%s%s:: %s%s\n" "${C_BOLD}" "${C_CYAN}" "$*" "${C_RESET}"; }

cleanup() {
  printf "%s" "${C_RESET}"
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------------------
readonly PACKAGES=(
  "xdg-terminal-exec"
  "ttf-material-design-icons-extended"
  "skwd-daemon-bin"
  "skwd-wall"
  "niri-screenshare"
)
# "otf-atkinson-hyperlegible-next"

readonly TIMEOUT_SEC=5
readonly MAX_RETRIES=6

# ------------------------------------------------------------------------------
# PRE-FLIGHT CHECKS
# ------------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  log_err "This script must NOT be run as root."
  exit 1
fi

if ! command -v shelly &>/dev/null; then
  log_err "Shelly is not installed. Install it first:"
  log_err "  git clone https://github.com/terrapkg/shelly"
  exit 1
fi

readonly AUR_HELPER="shelly aur"

# ------------------------------------------------------------------------------
# MAIN LOGIC
# ------------------------------------------------------------------------------
main() {
  log_task "Starting Autonomous Package Installation Sequence"
  log_info "Using Shelly AUR installer"
  log_info "Retry Policy: ${MAX_RETRIES} attempts | ${TIMEOUT_SEC}s delay"

  # --------------------------------------------------------------------------
  # STEP 1: System Update via Shelly
  # --------------------------------------------------------------------------
  log_task "Synchronizing Repositories & Updating System..."

  local update_success=false
  for ((i=1; i<=MAX_RETRIES; i++)); do
    if shelly update; then
      update_success=true
      break
    else
      log_warn "System update failed (Attempt $i/$MAX_RETRIES). Retrying in ${TIMEOUT_SEC}s..."
      sleep "$TIMEOUT_SEC"
    fi
  done

  if [[ "$update_success" == "false" ]]; then
    log_err "System update failed after $MAX_RETRIES attempts. Aborting."
    return 1
  fi

  # --------------------------------------------------------------------------
  # STEP 2: Filter Missing Packages
  # --------------------------------------------------------------------------
  log_info "Checking installation status..."

  local -a to_install=()
  local pkg

  for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    log_success "All packages are already installed."
    return 0
  fi

  log_info "Packages to install: ${#to_install[@]}"

  # --------------------------------------------------------------------------
  # STEP 3: Batch Installation Attempt
  # --------------------------------------------------------------------------
  log_task "Attempting Batch Installation with Shelly..."

  if shelly aur install "${to_install[@]}"; then
    log_success "Batch installation successful."
    return 0
  else
    log_warn "Batch installation failed. Switching to Granular Fallback Mode."
  fi

  # --------------------------------------------------------------------------
  # STEP 4: Granular Fallback Mode
  # --------------------------------------------------------------------------
  local -a failed_pkgs=()
  local success_count=0
  local fail_count=0

  for pkg in "${to_install[@]}"; do
    log_task "Processing: $pkg"
    local retry_count=0

    while true; do
      if shelly aur install "$pkg"; then
        log_success "Installed $pkg."
        ((success_count++))
        break
      fi

      log_warn "Automatic install failed for $pkg."

      if ((retry_count >= MAX_RETRIES)); then
        log_err "Max retries reached for $pkg. Skipping."
        failed_pkgs+=("$pkg")
        ((fail_count++))
        break
      fi

      if [[ ! -t 0 ]]; then
        ((retry_count++))
        log_info "Non-interactive session. Retry $retry_count/$MAX_RETRIES in ${TIMEOUT_SEC}s..."
        sleep "$TIMEOUT_SEC"
        continue
      fi

      printf "%s  -> Manual install [M] or Skip [S]? (Auto-retry in %ss)... %s" \
        "${C_YELLOW}" "$TIMEOUT_SEC" "${C_RESET}"

      local user_input=""
      if read -t "$TIMEOUT_SEC" -n 1 -r -s user_input; then
        case "${user_input,,}" in
          m)
            printf "\n"
            log_info "Manual mode for $pkg..."
            if shelly aur install "$pkg"; then
              log_success "Manual install successful."
              ((success_count++))
              break
            else
              log_err "Manual install failed."
              ((retry_count++))
            fi
            ;;
          s)
            printf "\n"
            log_warn "Skipping $pkg."
            failed_pkgs+=("$pkg")
            ((fail_count++))
            break
            ;;
          *)
            printf "\n"
            log_info "Invalid input. Use M or S."
            ((retry_count++))
            ;;
        esac
      else
        printf "\n"
        ((retry_count++))
        log_info "Timeout. Auto-retry $retry_count/$MAX_RETRIES..."
      fi
    done
  done

  # --------------------------------------------------------------------------
  # SUMMARY
  # --------------------------------------------------------------------------
  printf "\n"
  printf "%s========================================%s\n" "${C_BOLD}" "${C_RESET}"
  printf "%s     INSTALLATION SUMMARY              %s\n" "${C_BOLD}" "${C_RESET}"
  printf "%s========================================%s\n" "${C_BOLD}" "${C_RESET}"

  log_success "Successful: $success_count"

  if [[ $fail_count -gt 0 ]]; then
    log_err "Failed: $fail_count"
    log_err "The following packages failed to install:"
    for f in "${failed_pkgs[@]}"; do
      printf "   - %s\n" "$f"
    done
    return 1
  else
    log_success "All packages processed successfully."
    return 0
  fi
}

main "$@"
