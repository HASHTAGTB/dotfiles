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
"nwg-look" "sddm" "qt5ct" "qt6ct" "qt6-svg" "qt6-multimedia-ffmpeg" "adw-gtk-theme" "matugen" "ttf-font-awesome" "ttf-jetbrains-mono-nerd" "noto-fonts-emoji"
# Desktop
"waybar" "swww" "hyprlock" "hypridle" "hyprpicker" "swaync" "rofi" "libdbusmenu-qt5" "libdbusmenu-glib"
# Audio & Bluetooth
"playerctl" "blueman" "pavucontrol" "gst-plugin-pipewire"
# Filesystem
"udiskie" "gvfs-mtp" "gvfs-nfs" "gvfs-smb" "xdg-user-dirs" "gnome-disk-utility" "unrar" "7zip" "cpio" "thunar" "thunar-archive-plugin" "thunar-volman" "tumbler" "webp-pixbuf-loader" "poppler-glib"
# Network
"nm-connection-editor" "network-manager-applet"
# Terminal
"kitty" "zsh-syntax-highlighting" "starship" "yazi" "gum" "zsh-autosuggestions" "libqalculate" "moreutils" "eza" "bat" "fd" "fzf" "ripgrep"
# Development
"neovim" "git-delta" "meson" "cmake" "clang" "uv" "rq" "jq" "bc" "viu" "chafa" "ueberzugpp" "ccache" "mold" "shellcheck" "shfmt" "stylua" "prettier" "tree-sitter-cli"
# Multimedia
"mpv" "mpv-mpris" "swappy" "swayimg" "resvg" "imagemagick" "libheif" "ffmpegthumbnailer" "grim" "slurp" "wl-clipboard" "cliphist" "tesseract-data-eng"
# System
"dgop" "nvtop" "gdu" "lshw" "wev" "libsecret" "seahorse" "yad" "dysk"
# Gnome
"loupe" "gnome-calculator" "gnome-clocks"
# Custom
"zen-browser" "yay" "gnome-keyring"
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
