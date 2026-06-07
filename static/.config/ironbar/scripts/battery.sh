#!/usr/bin/env bash

source ~/.config/ironbar/scripts/variables.sh

# NOTE: Dependency: acpi (only used for the time-remaining estimate).
# Percent/status are read straight from sysfs BAT0 so that HID-device
# batteries (touchscreen/stylus, e.g. "Battery 1" in `acpi -b`) can't
# corrupt the parsing.

BAT=/sys/class/power_supply/BAT0

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
	# If there is no laptop battery, render nothing.
	[ -d "$BAT" ] || return

	battery_percent=$(cat "$BAT/capacity")
	battery_status=$(cat "$BAT/status")

	bolt_icon=$'' # nf-fa-bolt, shown while charging

	get_battery_icon() {
		if [ "$battery_percent" -gt 90 ]; then
			echo ""
		elif [ "$battery_percent" -gt 70 ]; then
			echo ""
		elif [ "$battery_percent" -gt 50 ]; then
			echo ""
		elif [ "$battery_percent" -gt 30 ]; then
			echo "<span color='$orange_color'></span>"
		else
			echo "<span color='$red_color'></span>"
		fi
	}

	# Time estimate from acpi, scoped to the real battery line ("Battery 0")
	# so the HID battery's "Battery 1" line is ignored.
	battery_time=$(acpi -b 2>/dev/null | grep -m1 'Battery 0:' | grep -o -P '(\d+:\d+:\d+|\d+:\d+|\d+\s(?:minute|min|hour|h))' | head -1)

	if [ "$battery_status" == "Charging" ]; then
		if [ "$battery_percent" -eq 100 ]; then
			echo "$(get_battery_icon) $battery_percent%"
			return
		fi
		if [ -z "$battery_time" ]; then
			echo "<span bgcolor='$green_background_color'>$bolt_icon $(get_battery_icon) $battery_percent% [Calculating]</span>"
		else
			echo "<span bgcolor='$green_background_color'>$bolt_icon $(get_battery_icon) $battery_percent% [$(shorten_time_format "$battery_time") to full]</span>"
		fi
	elif [ "$battery_status" == "Discharging" ]; then
		if [ "$battery_percent" -lt 15 ]; then
			last_battery_notification_id=$(makoctl list | jq '.data[][] | select(.summary.data == "Battery Low")' | jq '.id.data')
			[[ -n ${last_battery_notification_id} ]] || last_battery_notification_id=1
			notify-send -r $last_battery_notification_id "Battery Low" "Battery level is ${battery_percent}%\!" -t 45000
		fi

		if [ -z "$battery_time" ]; then
			echo "$(get_battery_icon) $battery_percent% [Calculating]"
		else
			echo "$(get_battery_icon) $battery_percent% [$(shorten_time_format "$battery_time") left]"
		fi
	else
		# Full / Not charging / Unknown: show level without a time estimate.
		echo "$(get_battery_icon) $battery_percent%"
	fi
}

get_battery_status
