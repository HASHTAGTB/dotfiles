#!/usr/bin/env bash
# description: Enables and starts system-level systemd services.

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
readonly SYSTEM_SERVICES=(
    "NetworkManager.service"
    "udisks2.service"
    "firewalld.service"
    "fstrim.timer"
    "systemd-timesyncd.service"
    "systemd-resolved.service"
    "preload"
)

# ==============================================================================
# EXECUTION
# ==============================================================================
if [[ $EUID -ne 0 ]]; then
    echo "Elevating privileges to enable system services..."
    exec sudo "$0" "$@"
fi

echo "Enabling system services..."

for svc in "${SYSTEM_SERVICES[@]}"; do
    if systemctl enable --now "$svc"; then
        echo "[OK] Enabled $svc"
    else
        echo "[FAILED] Could not enable $svc" >&2
    fi
done

echo "System services configured."
