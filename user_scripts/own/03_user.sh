#!/usr/bin/env bash
# description: Enables and starts user-level systemd services.

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
readonly USER_SERVICES=(
    "pipewire.socket"
    "pipewire-pulse.socket"
    "wireplumber.service"
    "hypridle.service"
    "hyprpolkitagent.service"
    "fumon.service"
    "gnome-keyring-daemon.service"
    "gnome-keyring-daemon.socket"
    "network_meter.service"
    # Add your user services here
)

# ==============================================================================
# EXECUTION
# ==============================================================================
if [[ $EUID -eq 0 ]]; then
    echo "Error: Do NOT run user service scripts as root/sudo." >&2
    exit 1
fi

echo "Enabling user services..."

for svc in "${USER_SERVICES[@]}"; do
    if systemctl --user enable --now "$svc"; then
        echo "[OK] Enabled $svc"
    else
        echo "[FAILED] Could not enable $svc" >&2
    fi
done

echo "User services configured."
