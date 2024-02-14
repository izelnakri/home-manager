#!/bin/bash
#
controller_alias=$(bluetoothctl show | awk '/Alias/ {print $2}')
bluetooth_status=$(bluetoothctl show | awk '/Powered/ {print $2}')

if [ -z "$bluetooth_status" ]; then
    echo " off"
    exit 0
fi

output=$(bluetoothctl <<< "info" | grep -E "Name:|Battery Percentage:")
devices=$(echo "$output" | grep "Name:" | awk '{print $2}')
percentages=$(echo "$output" | grep "Battery Percentage:" | awk '{print strtonum($3)}')

if [ -z "$devices" ]; then
    echo " $controller_alias (on)"
    exit 0
fi

IFS=$'\n'
for device in $devices; do
    read -r percentage <<< "$percentages"
    echo -n " $device ($percentage%), "
    percentages=$(echo "$percentages" | sed '1d')  # Remove the first line after each iteration
done | sed 's/, $//'
