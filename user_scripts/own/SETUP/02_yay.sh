#!/usr/bin/env bash
# description: Installs AUR packages using Yay.

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
readonly AUR_PACKAGES=(
  "wlogout"
  "adwaita-qt6"
  "adwaita-qt5"
  "otf-atkinson-hyperlegible-next"
  "fluent-icon-theme-git"
  "hyprshade"
  "waypaper"
  "tray-tui"
  "wifitui-bin"
  "xdg-terminal-exec"
  "pacseek-bin"
  "tealdeer"
  "man-db"
  "aria2"
  "uget"
  "pinta"
)

# ==============================================================================
# EXECUTION
# ==============================================================================
if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run AUR installations as root." >&2
    exit 1
fi

if ! command -v yay &> /dev/null; then
    echo "Error: yay is not installed." >&2
    exit 1
fi

echo "Installing AUR packages..."
yay -Syu --needed --noconfirm "${AUR_PACKAGES[@]}"

echo "AUR package installation complete."
