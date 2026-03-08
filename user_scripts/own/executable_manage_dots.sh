#!/bin/bash

# --- Configuration ---
REPO_URL="git@github.com:HASHTAGTB/linux-config.git"
DOT_DIR="$HOME/dotfiles"
FILES=(
    ".config/hypr/edit_here"
    "user_scripts/theme_matugen/theme_ctl.sh"
    ".config/waypaper/congig.ini"
    ".config/hypr/shaders/saturation.glsl"
    ".zshrc"
)

# Files to back up as reference only (No symlinks, requires sudo)
SYSTEM_FILES=(
    "/etc/fstab"
    "/etc/pacman.conf"
    "/etc/resolv.conf" # Your DNS settings
)

mkdir -p "$DOT_DIR/system_reference"

case $1 in
    backup)
        echo "📦 Starting Backup..."
        for item in "${FILES[@]}"; do
            if [ -e "$HOME/$item" ]; then
                mkdir -p "$DOT_DIR/$(dirname "$item")"
                if [ ! -L "$HOME/$item" ]; then
                    mv "$HOME/$item" "$DOT_DIR/$item"
                    ln -s "$DOT_DIR/$item" "$HOME/$item"
                fi
            fi
        done

        echo "📂 Copying system files (DNS/Fstab) for reference..."
        for sys_file in "${SYSTEM_FILES[@]}"; do
            if [ -f "$sys_file" ]; then
                sudo cp "$sys_file" "$DOT_DIR/system_reference/"
                sudo chown $USER:$USER "$DOT_DIR/system_reference/$(basename "$sys_file")"
            fi
        done

        echo "📝 Updating package list..."
        pacman -Qqe > "$DOT_DIR/pkglist.txt"

        cd "$DOT_DIR" || exit
        git add .
        git commit -m "Backup: $(date +'%Y-%m-%d %H:%M')"
        git push -f origin main
        echo "🔥 System state pushed to GitHub."
        ;;

    restore)
        echo "🔗 Restoring symlinks..."
        for item in "${FILES[@]}"; do
            mkdir -p "$(dirname "$HOME/$item")"
            rm -rf "$HOME/$item"
            ln -s "$DOT_DIR/$item" "$HOME/$item"
        done
        chmod +x "$HOME/user_scripts/theme_matugen/theme_ctl.sh"
        echo "✅ Restore complete. Check system_reference/ for manual tweaks."
        ;;
esac
