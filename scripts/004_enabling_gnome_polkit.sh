#!/usr/bin/env bash
# Polkit GNOME user service setup for Hyprland / Wayland

set -euo pipefail

SERVICE_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SERVICE_DIR}/polkit-gnome.service"
AGENT_BIN="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

echo "[INFO] Setting up polkit-gnome user service..."

# --- sanity checks ------------------------------------------------------------

if [[ ! -x "$AGENT_BIN" ]]; then
    echo "[ERROR] polkit-gnome agent binary not found:"
    echo "        $AGENT_BIN"
    echo "        Is polkit-gnome installed?"
    exit 1
fi

# --- create directory ---------------------------------------------------------

mkdir -p "$SERVICE_DIR"

# --- write service file (idempotent) ------------------------------------------

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Polkit GNOME Authentication Agent
Documentation=man:polkit(8)
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=$AGENT_BIN
Restart=on-failure
RestartSec=1
Slice=session.slice

[Install]
WantedBy=default.target
EOF

echo "[SUCCESS] Service file written:"
echo "          $SERVICE_FILE"

# --- reload + enable -----------------------------------------------------------

systemctl --user daemon-reload
systemctl --user enable --now polkit-gnome.service

echo "[SUCCESS] polkit-gnome.service enabled and started"

# --- status hint --------------------------------------------------------------

echo "[INFO] Current service status:"
systemctl --user --no-pager --full status polkit-gnome.service || true
