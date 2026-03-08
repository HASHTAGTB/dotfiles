# 1 Package Removal

## sudo pacman -Rns
dunst
dolphin
wofi
polkit-kde-agent
firefox

## yay -Rns

# 2 Changing Shell

chsh -s $(which zsh)

# 3 Use Keybinds

SUPER ALT . (blur, shadow, opacity)
SUPER # (theme, wallpaper)

# 4 SDDW Theme

`sudo git clone -b master --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme`

`sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/`
