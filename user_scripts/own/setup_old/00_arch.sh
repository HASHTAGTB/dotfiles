#!/usr/bin/env bash
# description: Installs essential base packages missing in standard Arch compared to CachyOS.

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
readonly ARCH_BASE_PACKAGES=(
    # Networking & Bluetooth
    "networkmanager" "bluez" "bluez-utils" "wpa_supplicant" "iwd" "wget" "rsync"
    
    # Audio (Pipewire stack)
    "pipewire" "pipewire-pulse" "pipewire-alsa" "wireplumber"
    
    # Wayland Portals & Authentication
    "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk" "polkit-kde-agent"
    
    # Filesystems, Archives & Disks
    "btrfs-progs" "dosfstools" "ntfs-3g" "exfatprogs" "zip" "unzip" "snapper"
    
    # Power & System Management
    "upower" "power-profiles-daemon" "sudo"
)

# ==============================================================================
# EXECUTION
# ==============================================================================
if [[ $EUID -ne 0 ]]; then
    echo "Elevating privileges to install base packages..."
    exec sudo "$0" "$@"
fi

echo "Installing Arch base dependencies..."
pacman -Syu --needed --noconfirm "${ARCH_BASE_PACKAGES[@]}"

echo "Base package installation complete. Don't forget to enable services (e.g., NetworkManager, bluetooth)!"
