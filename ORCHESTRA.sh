#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX MASTER ORCHESTRATOR — NIRI STACK
# ==============================================================================

INSTALL_SEQUENCE=(
    "S | 002_package_installation.sh"
    "U | 003_enabling_user_services.sh"
    "U | 004_enabling_gnome_polkit.sh"
    "U | 005_changing_shell_zsh.sh"
    "U | 006_paru_packages.sh"
    "S | 008_pam_keyring.sh"
    "U | 009_fc_cache_fv.sh"
    "U | 012_theme_ctl.sh"        # pending rewrite for Quickshell/Niri
    "U | 013_qtct_config.sh"
    "U | 015_terminal_default.sh"
    "U | 016_tldr_update.sh"
    "U | 017_neovim_clean.sh"
    "S | 018_system_services.sh"
    "S | 019_gtk_root_symlink.sh"
    "U | 020_cache_purge.sh"
    "U | 021_cursor_theme_bibata_classic_modern.sh"
    "U | 023_mpv_setup.sh"
    "U | 027_niri_reload.sh"
)

# ==============================================================================
#  INTERNAL ENGINE (Do not edit below)
# ==============================================================================

set -o errexit
set -o nounset
set -o pipefail

readonly SCRIPT_DIR="${HOME}/scripts"
readonly STATE_FILE="${HOME}/Documents/.install_state"
readonly LOG_FILE="${HOME}/Documents/logs/install_$(date +%Y%m%d_%H%M%S).log"

readonly SUDO_REFRESH_INTERVAL=50

declare -g SUDO_PID=""

declare -g RED="" GREEN="" BLUE="" YELLOW="" BOLD="" RESET=""

if [[ -t 1 ]] && command -v tput &>/dev/null; then
    if (( $(tput colors 2>/dev/null || echo 0) >= 8 )); then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
    fi
fi

setup_logging() {
    if [[ ! -d "$SCRIPT_DIR" ]]; then
        echo "CRITICAL ERROR: The hardcoded path does not exist:"
        echo " -> $SCRIPT_DIR"
        exit 1
    fi

    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || { echo "CRITICAL ERROR: Could not create log directory $log_dir"; exit 1; }
    fi

    touch "$LOG_FILE"
    exec 3>&1 4>&2
    exec > >(tee >(sed 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\x1B(B//g' >> "$LOG_FILE")) 2>&1

    echo "--- Installation Started: $(date '+%Y-%m-%d %H:%M:%S') ---"
    echo "--- Log File: $LOG_FILE ---"
}

log() {
    local level="$1"
    local msg="$2"
    local color=""

    case "$level" in
        INFO)    color="$BLUE" ;;
        SUCCESS) color="$GREEN" ;;
        WARN)    color="$YELLOW" ;;
        ERROR)   color="$RED" ;;
        RUN)     color="$BOLD" ;;
    esac

    printf "%s[%s]%s %s\n" "${color}" "${level}" "${RESET}" "${msg}"
}

init_sudo() {
    log "INFO" "Sudo privileges required. Please authenticate."
    if ! sudo -v; then
        log "ERROR" "Sudo authentication failed."
        exit 1
    fi

    ( while true; do sudo -n true; sleep "$SUDO_REFRESH_INTERVAL"; kill -0 "$$" || exit; done 2>/dev/null ) &
    SUDO_PID=$!
    disown "$SUDO_PID"
}

cleanup() {
    local exit_code=$?
    if [[ -n "${SUDO_PID:-}" ]]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi

    if [[ $exit_code -eq 0 ]]; then
        log "SUCCESS" "Orchestrator finished successfully."
    else
        log "ERROR" "Orchestrator exited with error code $exit_code."
    fi
}
trap cleanup EXIT

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

get_script_description() {
    local filename="$1"
    local desc
    desc=$(sed -n '2s/^#[[:space:]]*//p' "${SCRIPT_DIR}/${filename}" 2>/dev/null)
    if [[ -z "$desc" ]]; then
        desc=$(sed -n '3s/^#[[:space:]]*//p' "${SCRIPT_DIR}/${filename}" 2>/dev/null)
    fi
    printf "%s" "${desc:-No description available}"
}

preflight_check() {
    local missing=0
    log "INFO" "Performing pre-flight validation..."

    for entry in "${INSTALL_SEQUENCE[@]}"; do
        local rest="${entry#*|}"
        rest=$(trim "$rest")
        local filename args
        read -r filename args <<< "$rest"

        if [[ ! -f "${SCRIPT_DIR}/${filename}" ]]; then
            log "ERROR" "Missing file: ${filename}"
            ((++missing))
        fi
    done

    if ((missing > 0)); then
        echo -e "${RED}CRITICAL:${RESET} $missing script(s) are missing from $SCRIPT_DIR."
        read -r -p "Continue anyway? [y/N]: " _choice
        if [[ "${_choice,,}" != "y" ]]; then
            log "ERROR" "Aborting execution."
            exit 1
        fi
    else
        log "SUCCESS" "All sequence files verified."
    fi
}

show_help() {
    cat << EOF
Arch Linux Master Orchestrator — Niri Stack

Usage: $(basename "$0") [OPTIONS]

Options:
    --help, -h       Show this help message and exit
    --dry-run, -d    Preview execution plan without running anything
    --reset          Clear progress state and start fresh
EOF
    exit 0
}

main() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}CRITICAL ERROR: This script must NOT be run as root!${RESET}"
        exit 1
    fi

    case "${1:-}" in
        --help|-h)   show_help ;;
        --dry-run|-d)
            echo -e "\n${YELLOW}=== DRY RUN MODE ===${RESET}"
            echo -e "Script directory: ${BOLD}${SCRIPT_DIR}${RESET}"
            echo -e "State file: ${BOLD}${STATE_FILE}${RESET}\n"

            local i=0
            for entry in "${INSTALL_SEQUENCE[@]}"; do
                ((++i))
                local mode="${entry%%|*}"
                local rest="${entry#*|}"
                mode=$(trim "$mode")
                rest=$(trim "$rest")
                local filename args
                read -r filename args <<< "$rest"
                local mode_label="USER"
                [[ "$mode" == "S" ]] && mode_label="SUDO"
                local status="${BLUE}[PENDING]${RESET}"
                [[ ! -f "${SCRIPT_DIR}/${filename}" ]] && status="${RED}[MISSING]${RESET}"
                [[ -f "$STATE_FILE" ]] && grep -Fxq "$filename" "$STATE_FILE" 2>/dev/null && status="${GREEN}[DONE]${RESET}"
                printf "  %3d. [%s] %-45s %s\n" "$i" "$mode_label" "${filename}${args:+ $args}" "$status"
            done
            echo ""
            echo "No changes were made."
            exit 0
            ;;
        --reset)
            rm -f "$STATE_FILE"
            echo "State file reset. Starting fresh."
            ;;
    esac

    setup_logging
    preflight_check

    local start_ts=$SECONDS

    local needs_sudo=0
    for entry in "${INSTALL_SEQUENCE[@]}"; do
        if [[ "$entry" == S* ]]; then needs_sudo=1; break; fi
    done

    if [[ $needs_sudo -eq 1 ]]; then
        init_sudo
    fi

    touch "$STATE_FILE"
    cd "$SCRIPT_DIR" || { log "ERROR" "Failed to cd to $SCRIPT_DIR"; exit 1; }

    if [[ -s "$STATE_FILE" ]]; then
        echo -e "\n${YELLOW}>>> PREVIOUS SESSION DETECTED <<<${RESET}"
        read -r -p "Do you want to [C]ontinue where you left off or [S]tart over? [C/s]: " _session_choice
        if [[ "${_session_choice,,}" == "s" || "${_session_choice,,}" == "start" ]]; then
            rm -f "$STATE_FILE"
            touch "$STATE_FILE"
            log "INFO" "State file reset. Starting fresh."
        else
            log "INFO" "Continuing from previous session."
        fi
    fi

    local interactive_mode=0
    echo -e "\n${YELLOW}>>> EXECUTION MODE <<<${RESET}"
    read -r -p "Do you want to run interactively (prompt before every script)? [y/N]: " _mode_choice
    if [[ "${_mode_choice,,}" == "y" || "${_mode_choice,,}" == "yes" ]]; then
        interactive_mode=1
        log "INFO" "Interactive mode selected."
    else
        log "INFO" "Autonomous mode selected."
    fi

    local total_scripts=${#INSTALL_SEQUENCE[@]}
    local current_index=0
    local SKIPPED_OR_FAILED=()

    for entry in "${INSTALL_SEQUENCE[@]}"; do
        ((++current_index))

        local mode="${entry%%|*}"
        local rest="${entry#*|}"
        mode=$(trim "$mode")
        rest=$(trim "$rest")

        local filename args
        read -r filename args <<< "$rest"

        while [[ ! -f "$filename" ]]; do
            log "ERROR" "Script not found: $filename"
            read -r -p "Do you want to [S]kip to next, [R]etry check, or [Q]uit? (s/r/q): " _choice
            case "${_choice,,}" in
                s|skip)
                    log "WARN" "Skipping $filename (User Selection)"
                    SKIPPED_OR_FAILED+=("$filename")
                    continue 2
                    ;;
                r|retry) sleep 1 ;;
                *) exit 1 ;;
            esac
        done

        if grep -Fxq "$filename" "$STATE_FILE"; then
            log "WARN" "[${current_index}/${total_scripts}] Skipping $filename (Already Completed)"
            continue
        fi

        if [[ $interactive_mode -eq 1 ]]; then
            local desc
            desc=$(get_script_description "$filename")
            echo -e "\n${YELLOW}>>> NEXT SCRIPT [${current_index}/${total_scripts}]:${RESET} $filename ${args:+ $args} ($mode)"
            echo -e "    ${BOLD}Description:${RESET} $desc"
            read -r -p "Do you want to [P]roceed, [S]kip, or [Q]uit? (p/s/q): " _user_confirm
            case "${_user_confirm,,}" in
                s|skip)
                    log "WARN" "Skipping $filename (User Selection)"
                    SKIPPED_OR_FAILED+=("$filename")
                    continue
                    ;;
                q|quit) exit 0 ;;
            esac
        fi

        while true; do
            log "RUN" "[${current_index}/${total_scripts}] Executing: $filename $args ($mode)"

            local result=0
            if [[ "$mode" == "S" ]]; then
                sudo bash "$filename" $args || result=$?
            elif [[ "$mode" == "U" ]]; then
                bash "$filename" $args || result=$?
            else
                log "ERROR" "Invalid mode '$mode'."
                exit 1
            fi

            if [[ $result -eq 0 ]]; then
                echo "$filename" >> "$STATE_FILE"
                log "SUCCESS" "Finished $filename"
                sleep 1
                break
            else
                log "ERROR" "Failed $filename (Exit Code: $result)."
                read -r -p "Do you want to [S]kip to next, [R]etry, or [Q]uit? (s/r/q): " _fail_choice
                case "${_fail_choice,,}" in
                    s|skip)
                        SKIPPED_OR_FAILED+=("$filename")
                        break
                        ;;
                    r|retry) sleep 1; continue ;;
                    *) exit 1 ;;
                esac
            fi
        done
    done

    if [[ ${#SKIPPED_OR_FAILED[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}================================================================${RESET}"
        echo -e "${YELLOW}NOTE: Some scripts were skipped or failed:${RESET}"
        for f in "${SKIPPED_OR_FAILED[@]}"; do
            echo " - $f"
        done
        echo -e "${YELLOW}================================================================${RESET}\n"
    fi

    local end_ts=$SECONDS
    local duration=$((end_ts - start_ts))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo -e "\n${GREEN}================================================================${RESET}"
    echo -e "${BOLD}FINAL INSTRUCTIONS:${RESET}"
    echo -e "1. Execution Time: ${BOLD}${minutes}m ${seconds}s${RESET}"
    echo -e "2. Please ${BOLD}REBOOT YOUR SYSTEM${RESET} for all changes to take effect."
    echo -e "${GREEN}================================================================${RESET}\n"
}

main "$@"
