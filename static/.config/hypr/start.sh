#!/usr/bin/env bash

set -euo pipefail

# initializing wallpaper deamon
swww-daemon &
swww img ~/Wallpapers/arch-monk.jpg &

# pkgs.networkmanagerapplet
nm-applet --indicator &

systemctl --user restart ironbar.service

dunst # replace with mako

# grim -l 0 -g "$(slurp)" - | wl-copy

# pkgs.grim, slupr, wl-copy

alacritty

# udiskie &

# /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
# dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
# notify-send -a aurora "hello $(whoami)" &
