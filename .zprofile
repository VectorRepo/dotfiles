# # Only on first login on tty1, not over ssh, and not from an existing GUI
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]] && [[ "$(fgconsole 2>/dev/null)" == "1" ]]; then
  niri-session -l
fi
