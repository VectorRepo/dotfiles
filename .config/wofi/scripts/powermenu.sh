#!/usr/bin/env bash
#
# Egyszerű power menu - függőleges lista, nincs keresősáv, nincs
# extra infósáv. A bar "custom/power" gombja hívja (ld. waybar
# config.jsonc on-click).
#
# User-független: mindenhol $HOME-ot használ. A style.css @import-ját
# futáskor generáljuk egy ideiglenes fájlba a wofi-colors.css helyes,
# abszolút útjával.
#
# ESC = mindig megszakítás, semmi nem hajtódik végre. Csak Enter
# (0-s wofi kilépőkód) számít érvényes választásnak - ezt explicit
# if/else-vel ellenőrizzük, nem `|| true`-val nyeljük el.

set -uo pipefail

WOFI_DIR="$HOME/.config/wofi"
POWER_DIR="$WOFI_DIR/power"
CONF="$POWER_DIR/power-menu-config"
STYLE_TEMPLATE="$POWER_DIR/power-menu-style.template.css"
COLORS_PATH="$WOFI_DIR/wofi-colors.css"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
STYLE_RENDERED="$RUNTIME_DIR/wofi-power-menu-style.css"

sed "s#__WOFI_COLORS_PATH__#${COLORS_PATH}#g" "$STYLE_TEMPLATE" > "$STYLE_RENDERED"

# --- Ikonok (Font Awesome Nerd Font, explicit Unicode escape-ekkel,
#     hogy ne tudjanak útközben megsérülni) ---
ICON_LOCK=$'\uf023'
ICON_LOGOUT=$'\uf08b'
ICON_SUSPEND=$'\uf186'
ICON_REBOOT=$'\uf021'
ICON_SHUTDOWN=$'\uf011'

LABEL_LOCK="$ICON_LOCK  Lock"
LABEL_LOGOUT="$ICON_LOGOUT  Log Out"
LABEL_SUSPEND="$ICON_SUSPEND  Suspend"
LABEL_REBOOT="$ICON_REBOOT  Reboot"
LABEL_SHUTDOWN="$ICON_SHUTDOWN  Shut Down"

WOFI_BASE=(wofi --dmenu --conf "$CONF" --style "$STYLE_RENDERED" --location center)

show_menu() {
  local result
  if result=$(printf '%s\n%s\n%s\n%s\n%s\n' \
      "$LABEL_LOCK" "$LABEL_LOGOUT" "$LABEL_SUSPEND" "$LABEL_REBOOT" "$LABEL_SHUTDOWN" \
      | "${WOFI_BASE[@]}" --width 200 --height 245); then
    printf '%s' "$result"
  else
    printf ''
  fi
}

confirm() {
  local action_label="$1"
  local response
  if response=$(printf '%s\n%s\n' "Yes, $action_label" "Cancel" \
      | "${WOFI_BASE[@]}" --width 200 --height 90); then
    [[ "$response" == "Yes, $action_label" ]]
  else
    return 1
  fi
}

lock_screen() {
  if command -v swaylock >/dev/null 2>&1; then
    swaylock
  elif command -v hyprlock >/dev/null 2>&1; then
    hyprlock
  elif command -v gtklock >/dev/null 2>&1; then
    gtklock
  else
    loginctl lock-session
  fi
}

selection=$(show_menu)

case "$selection" in
  "$LABEL_LOCK")
    lock_screen
    ;;
  "$LABEL_LOGOUT")
    niri msg action quit --skip-confirmation
    ;;
  "$LABEL_SUSPEND")
    systemctl suspend
    ;;
  "$LABEL_REBOOT")
    confirm "reboot" && systemctl reboot
    ;;
  "$LABEL_SHUTDOWN")
    confirm "shutdown" && systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac
