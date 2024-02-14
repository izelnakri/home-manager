#!/bin/bash

shorten_time_format() {
    local time_format=$1
    local hours=$(echo $time_format | awk -F':' '{print $1}')
    local minutes=$(echo $time_format | awk -F':' '{print $2}')
    local seconds=$(echo $time_format | awk -F':' '{print $3}')

    # Shorten the format:
    if [ "$hours" != "00" ]; then
        echo "${hours}h ${minutes}m"
    elif [ "$minutes" != "00" ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

get_battery_status() {
    battery_percent=$(acpi -b | grep -P -o '[0-9]+(?=%)')
    battery_status=$(acpi -b | grep -o "Charging\|Discharging")

    get_battery_icon() {
        if [ $battery_percent -gt 90 ]; then
            echo ""
        elif [ $battery_percent -gt 70 ]; then
            echo ""
        elif [ $battery_percent -gt 50 ]; then
            echo ""
        elif [ $battery_percent -gt 30 ]; then
            echo ""
        else
            echo ""
        fi
    }

    if [ "$battery_percent" -eq 100 ]; then
        echo "$(get_battery_icon) $battery_percent%"
        return
    fi

    if [ "$battery_status" == "Charging" ]; then
        time_to_full=$(acpi -b | grep -o -P '(\d+:\d+:\d+|\d+:\d+|\d+\s(?:minute|min|hour|h))' | head -1)
        if [ -z "$time_to_full" ]; then
            echo "$(get_battery_icon) $battery_percent% [Calculating]"
        else
            time_to_full_short=$(shorten_time_format "$time_to_full")
            echo "$(get_battery_icon) $battery_percent% [$time_to_full_short]"
        fi
    else
        time_to_empty=$(acpi -b | grep -o -P '(\d+:\d+:\d+|\d+:\d+|\d+\s(?:minute|min|hour|h))' | head -1)
        if [ -z "$time_to_empty" ]; then
            echo "$(get_battery_icon) $battery_percent% [Calculating]"
        else
            time_to_empty_short=$(shorten_time_format "$time_to_empty")
            echo "$(get_battery_icon) $battery_percent% [$time_to_empty_short]"
        fi
    fi
}

get_battery_status
