#!/usr/bin/env bash
# This script installs ALL PACKAGEES, you can inspect this script manually to remove/add anything you might want.
# --------------------------------------------------------------------------
# Arch Linux / Hyprland / UWSM - Elite System Installer (v3.1 - Smart Fallback)
# --------------------------------------------------------------------------

# --- 1. CONFIGURATION ---

# Group 1: Graphics & Drivers
pkgs_graphics=(
  "mesa-utils" "libva" "libva-utils"
)

# Group 2: Hyprland Core
pkgs_hyprland=(
  "uwsm" "hyprpolkitagent" "socat" "inotify-tools"
)

# Group 3: GUI, Toolkits & Fonts
pkgs_appearance=(
  "nwg-look" "sddm" "qt5ct" "qt6ct" "qt6-svg" "qt6-multimedia-ffmpeg" "adw-gtk-theme" "matugen" "ttf-font-awesome" "ttf-jetbrains-mono-nerd" "noto-fonts-emoji" "sassc"
)

# Group 4: Desktop Experience
pkgs_desktop=(
  "waybar" "swww" "hyprlock" "hypridle" "hyprsunset" "hyprpicker" "swaync" "rofi" "libdbusmenu-qt5" "libdbusmenu-glib"
)

# Group 5: Audio & Bluetooth
pkgs_audio=(
  "playerctl" "blueman" "bluetui" "pavucontrol" "gst-plugin-pipewire" "libcanberra"
)

# Group 6: Filesystem & Archives
pkgs_filesystem=(
  "udiskie" "gvfs-mtp" "gvfs-nfs" "gvfs-smb" "xdg-user-dirs" "gnome-disk-utility" "unrar" "7zip" "cpio" "thunar" "thunar-archive-plugin" "thunar-volman" "tumbler" "webp-pixbuf-loader" "poppler-glib"
)

# Group 7: Network & Internet
pkgs_network=(
  "nm-connection-editor" "vsftpd" "bmon" "httrack" "wavemon" "network-manager-applet"
)

# Group 8: Terminal & Shell
pkgs_terminal=(
  "kitty" "zsh-syntax-highlighting" "starship" "yazi" "gum" "zsh-autosuggestions" "iperf3" "libqalculate" "moreutils" "eza" "bat" "fd" "fzf" "ripgrep"
)

# Group 9: Development
pkgs_dev=(
  "neovim" "git-delta" "meson" "cmake" "clang" "uv" "rq" "jq" "bc" "viu" "chafa" "ueberzugpp" "ccache" "mold" "shellcheck" "shfmt" "stylua" "prettier" "tree-sitter-cli"
)

# Group 10: Multimedia
pkgs_multimedia=(
  "mpv" "mpv-mpris" "swappy" "swayimg" "resvg" "imagemagick" "libheif" "ffmpegthumbnailer" "grim" "slurp" "wl-clipboard" "cliphist" "tesseract-data-eng"
)

# Group 11: Sys Admin
pkgs_sysadmin=(
  "dgop" "nvtop" "sysbench" "acpid" "gdu" "iotop" "iftop" "lshw" "wev" "libsecret" "seahorse" "yad" "dysk"
)

# Group 12: Gnome Utilities
pkgs_gnome=(
  "snapshot" "cameractrls" "loupe" "gnome-text-editor" "gnome-calculator" "gnome-clocks"
)

# Group 13: Productivity
pkgs_productivity=(
  "zathura" "zathura-pdf-mupdf" "cava"
)

#Group 14: Custom
pkgs_custom=(
	"zen-browser"
)

# --------------------------------------------------------------------------
# --- 2. ENGINE (Optimized) ---
# --------------------------------------------------------------------------

# 1. Root Check
if [[ $EUID -ne 0 ]]; then
  printf "Elevating privileges...\n"
  exec sudo "$0" "$@"
fi

# 2. Safety & Aesthetics
set -u
set -o pipefail

BOLD=$(tput bold)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# 3. Core Logic
install_group() {
  local group_name="$1"
  shift
  local pkgs=("$@")

  [[ ${#pkgs[@]} -eq 0 ]] && return

  printf "\n${BOLD}${CYAN}:: Processing Group: %s${RESET}\n" "$group_name"

  # STRATEGY A: Batch Install
  if pacman -S --needed --noconfirm "${pkgs[@]}"; then
    printf "${GREEN} [OK] Batch installation successful.${RESET}\n"
    return 0
  fi

  # STRATEGY B: Fallback Individual Install (Smart)
  printf "\n${YELLOW} [!] Batch transaction failed. Retrying individually...${RESET}\n"

  local fail_count=0

  for pkg in "${pkgs[@]}"; do
    # Try 1: Auto-install (Silent)
    # If this works, it means there was no conflict for THIS specific package.
    if pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
      printf "  ${GREEN}[+] Installed:${RESET} %s\n" "$pkg"
    
    # Try 2: Interactive (Verbose)
    # If Auto failed, it's likely a conflict (e.g., tldr vs tealdeer). 
    # We run without --noconfirm so you can intervene.
    else
      printf "  ${YELLOW}[?] Intervention Needed:${RESET} %s\n" "$pkg"
      if pacman -S --needed "$pkg"; then
        printf "  ${GREEN}[+] Installed (Manual):${RESET} %s\n" "$pkg"
      else
        printf "  ${RED}[X] Not Found / Failed:${RESET} %s\n" "$pkg"
        ((fail_count++))
      fi
    fi
  done

  if [[ $fail_count -gt 0 ]]; then
    printf "${YELLOW} [!] Group completed with %d failures.${RESET}\n" "$fail_count"
  else
    printf "${GREEN} [OK] Recovery successful. All packages installed.${RESET}\n"
  fi
}

# --- 3. EXECUTION ---

printf "${BOLD}:: Initializing Arch Keyring...${RESET}\n"
pacman-key --init
pacman-key --populate archlinux

printf "\n${BOLD}:: Full System Upgrade...${RESET}\n"
pacman -Syu --noconfirm || printf "${YELLOW}[!] Upgrade skipped or failed.${RESET}\n"

# Execute Groups
install_group "Graphics & Drivers" "${pkgs_graphics[@]}"
install_group "Hyprland Core" "${pkgs_hyprland[@]}"
install_group "GUI Appearance" "${pkgs_appearance[@]}"
install_group "Desktop Experience" "${pkgs_desktop[@]}"
install_group "Audio & Bluetooth" "${pkgs_audio[@]}"
install_group "Filesystem Tools" "${pkgs_filesystem[@]}"
install_group "Networking" "${pkgs_network[@]}"
install_group "Terminal & CLI" "${pkgs_terminal[@]}"
install_group "Development" "${pkgs_dev[@]}"
install_group "Multimedia" "${pkgs_multimedia[@]}"
install_group "System Admin" "${pkgs_sysadmin[@]}"
install_group "Gnome Utilities" "${pkgs_gnome[@]}"
install_group "Productivity" "${pkgs_productivity[@]}"
install_group "Custom" "${pkgs_custom[@]}"

printf "\n${BOLD}${GREEN}:: INSTALLATION COMPLETE ::${RESET}\n"
printf "Reboot is recommended to load new drivers and Hyprland env vars.\n"
