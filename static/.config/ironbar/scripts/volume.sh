#!/usr/bin/env bash

source ~/.config/ironbar/scripts/variables.sh

# NOTE: Dependency: wpctl (WirePlumber CLI, ships with PipeWire).
# Replaces pamixer, which isn't installed on this PipeWire/WirePlumber setup.

raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) # e.g. "Volume: 0.45" or "Volume: 0.45 [MUTED]"

if [ -z "$raw" ]; then
    echo " n/a"
    exit 0
fi

# "Volume: 0.45" -> 45
volume=$(awk '{ printf "%d", $2 * 100 }' <<< "$raw")

if grep -q "MUTED" <<< "$raw"; then
    printf "<span color='%s'> Muted</span>\n" "$red_color"
elif [ "$volume" -le 30 ]; then
    printf "<span color='%s'> %s%%</span>\n" "$green_color" "$volume"
elif [ "$volume" -le 70 ]; then
    printf "<span color='%s'> %s%%</span>\n" "$green_color" "$volume"
else
    printf "<span color='%s'> %s%%</span>\n" "$orange_color" "$volume"
fi
