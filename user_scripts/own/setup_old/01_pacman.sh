#!/usr/bin/env bash
# description: Installs official Arch repository packages.

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
readonly CORE_PACKAGES=(
# Hyprland
"uwsm" "hyprpolkitagent"
# GUI
"nwg-look" "sddm" "qt5ct" "qt6ct" "adw-gtk-theme" "matugen" "ttf-font-awesome" "ttf-jetbrains-mono-nerd" "noto-fonts-emoji"
# Desktop
"waybar" "swww" "hyprlock" "hypridle" "hyprpicker" "swaync" "rofi" "libdbusmenu-qt5"
# Audio & Bluetooth
"playerctl" "blueman" "pavucontrol" "gst-plugin-pipewire"
# Filesystem
"udiskie" "gvfs-mtp" "gvfs-nfs" "gvfs-smb" "xdg-user-dirs" "gnome-disk-utility" "unrar" "7zip" "cpio" "thunar" "thunar-archive-plugin" "thunar-volman" "tumbler" "webp-pixbuf-loader" "poppler-glib"
# Network
"nm-connection-editor" "network-manager-applet"
# Terminal
"kitty" "zsh-syntax-highlighting" "starship" "yazi" "gum" "zsh-autosuggestions" "libqalculate" "moreutils" "eza" "bat" "fd" "fzf" "ripgrep"
# Development
"neovim" "git-delta" "meson" "cmake" "uv" "rq" "jq" "bc" "viu" "chafa" "ueberzugpp" "ccache" "mold" "shellcheck" "shfmt" "stylua" "prettier" "tree-sitter-cli" "zoxide"
# Multimedia
"mpv" "mpv-mpris" "swappy" "swayimg" "resvg" "imagemagick" "ffmpegthumbnailer" "grim" "slurp" "wl-clipboard" "cliphist" "tesseract-data-eng"
# System
"btop" "htop" "dgop" "nvtop" "gdu" "lshw" "wev" "seahorse" "yad" "dysk" "fastfetch" "pacman-contrib"
# Gnome
"loupe" "gnome-calculator" "gnome-clocks"
# Fonts
"noto-fonts" "noto-fonts-cjk" "ttf-liberation" "ttf-dejavu" "ttf-nerd-fonts-symbold-common" "otf-font-awesome"
# Custom
"zen-browser" "yay" "gnome-keyring" "trash-cli"
)

# ==============================================================================
# EXECUTION
# ==============================================================================
if [[ $EUID -ne 0 ]]; then
    echo "Elevating privileges to install pacman packages..."
    exec sudo "$0" "$@"
fi

echo "Installing official packages..."
pacman -Syu --needed --noconfirm "${CORE_PACKAGES[@]}"

echo "Official package installation complete."
