#!/usr/bin/env bash

# initializing wallpaper deamon
swww init &
swww img ~/Wallpapers/arch-monk.jpg &

# pkgs.networkmanagerapplet
nm-applet --indicator &

ironbar &

# dunst # replace with mako

# grim -l 0 -g "$(slurp)" - | wl-copy

# pkgs.grim, slupr, wl-copy

alacritty

# udiskie &

# also run mako here or dunst(?)
#
#
# /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
# dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
# notify-send -a aurora "hello $(whoami)" &
#
