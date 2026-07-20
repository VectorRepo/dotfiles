#!/usr/bin/env bash
# Configures PAM for GNOME Keyring auto-unlock on login.
# ==============================================================================
# Script Name: 008_pam_keyring.sh
# Description: Installs gnome-keyring/libsecret and surgically inserts the
#              three pam_gnome_keyring.so lines into /etc/pam.d/login.
#              Does NOT overwrite the file — only adds what is missing.
#              Safe for CachyOS and any Arch-based distro.
# Target:      /etc/pam.d/login
# ==============================================================================

set -euo pipefail

# --- Configuration ---
readonly TARGET_FILE="/etc/pam.d/login"
readonly PACKAGES=("libsecret")

# The three lines that need to exist in the file.
# Each entry: "ANCHOR_PATTERN|LINE_TO_INSERT|POSITION(after/before)"
#
#   auth:     after the last `auth include/include` line
#   session:  after the last `session include` line
#   password: after the last `password include` line
#
readonly AUTH_LINE="auth       optional      pam_gnome_keyring.so"
readonly SESSION_LINE="session    optional      pam_gnome_keyring.so auto_start"
readonly PASSWORD_LINE="password   optional      pam_gnome_keyring.so"

# --- Formatting ---
readonly BOLD=$'\e[1m'
readonly GREEN=$'\e[32m'
readonly YELLOW=$'\e[33m'
readonly RED=$'\e[31m'
readonly RESET=$'\e[0m'

log_info()  { printf "${BOLD}${GREEN}[INFO]${RESET}  %s\n" "$1"; }
log_warn()  { printf "${BOLD}${YELLOW}[WARN]${RESET}  %s\n" "$1"; }
log_ok()    { printf "${BOLD}${GREEN}[OK]${RESET}    %s\n" "$1"; }
log_error() { printf "${BOLD}${RED}[ERROR]${RESET} %s\n" "$1" >&2; }

ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warn "Root privileges required. Elevating..."
        exec sudo "$0" "$@"
    fi
}

# ------------------------------------------------------------------------------
# insert_after_last_match PATTERN INSERT_LINE FILE
#
# Finds the LAST line in FILE matching PATTERN (grep -E) and inserts
# INSERT_LINE immediately after it using awk. Idempotent: if INSERT_LINE
# already exists verbatim in FILE, it does nothing.
# ------------------------------------------------------------------------------
insert_after_last_match() {
    local pattern="$1"
    local insert_line="$2"
    local file="$3"

    # Idempotency check — skip if already present
    if grep -qF "$insert_line" "$file"; then
        log_ok "Already present, skipping: ${insert_line}"
        return 0
    fi

    # Find the line number of the LAST match
    local last_match_line
    last_match_line=$(grep -nE "$pattern" "$file" | tail -n1 | cut -d: -f1)

    if [[ -z "$last_match_line" ]]; then
        log_warn "Anchor pattern not found: '$pattern' — appending to end of file instead."
        printf "\n%s\n" "$insert_line" >> "$file"
        return 0
    fi

    # Use awk to insert the line after the matched line number
    local tmp
    tmp=$(mktemp)
    awk -v n="$last_match_line" -v line="$insert_line" '
        NR == n { print; print line; next }
        { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"

    log_ok "Inserted after line ${last_match_line}: ${insert_line}"
}

# ------------------------------------------------------------------------------
main() {
    ensure_root "$@"

    # 1. Install packages
    log_info "Installing packages: ${PACKAGES[*]}..."
    if pacman -S --needed --noconfirm "${PACKAGES[@]}"; then
        log_ok "Packages installed/verified."
    else
        log_error "Failed to install packages."
        exit 1
    fi

    # 2. Sanity check
    if [[ ! -f "$TARGET_FILE" ]]; then
        log_error "$TARGET_FILE not found. Cannot continue."
        exit 1
    fi

    # 3. Backup (timestamped, non-destructive)
    local backup="${TARGET_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$TARGET_FILE" "$backup"
    log_info "Backup created: $backup"

    log_info "Patching $TARGET_FILE ..."

    # 4. auth line — insert after the last `auth ... include` line
    insert_after_last_match \
        '^auth[[:space:]]+(requisite|required|sufficient|optional|include)[[:space:]]' \
        "$AUTH_LINE" \
        "$TARGET_FILE"

    # 5. session line — insert after the last `session ... include` line
    insert_after_last_match \
        '^session[[:space:]]+(requisite|required|sufficient|optional|include)[[:space:]]' \
        "$SESSION_LINE" \
        "$TARGET_FILE"

    # 6. password line — insert after the last `password ... include` line
    insert_after_last_match \
        '^password[[:space:]]+(requisite|required|sufficient|optional|include)[[:space:]]' \
        "$PASSWORD_LINE" \
        "$TARGET_FILE"

    echo ""
    log_ok "GNOME Keyring PAM configuration applied."
    log_info "A reboot or re-login is required for the changes to take effect."
    echo ""
    log_info "Current state of $TARGET_FILE:"
    echo "----------------------------------------------------------------------"
    cat "$TARGET_FILE"
    echo "----------------------------------------------------------------------"
}

main "$@"
