#!/bin/bash

volume_info=$(pamixer --get-volume)
mute_status=$(pamixer --get-mute)

if [[ "$mute_status" == "true" ]]; then
    echo " Muted"
else
    volume=$(echo "$volume_info" | cut -d' ' -f1) # Extract the volume percentage

    if [[ "$volume" -le 30 ]]; then
        echo " $volume%"
    elif [[ "$volume" -le 70 ]]; then
        echo " $volume%"
    else
        echo " $volume%"
    fi
fi
