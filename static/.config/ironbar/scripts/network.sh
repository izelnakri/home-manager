#!/bin/bash

source ~/.config/ironbar/scripts/variables.sh

# NOTE: Dependencies: NetworkManager (nmcli) for connection info, vnstat for
# live traffic. Replaces iwgetid (not installed); works for Wi-Fi and wired.

get_traffic() {
    # Single 2s sample (sets globals tx/rx). The old script sampled twice
    # (4s total) which overran the bar's 2.5s refresh interval.
    local dev=$1 sample
    sample=$(vnstat -tr 2 -i "$dev" 2>/dev/null)
    tx=$(awk '/tx/ { print $2, $3 }' <<< "$sample")
    rx=$(awk '/rx/ { print $2, $3 }' <<< "$sample")
}

main() {
    # First connected, non-loopback device.
    line=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
        | awk -F: '$3 == "connected" && $2 != "loopback" { print; exit }')

    if [ -z "$line" ]; then
        echo " Disconnected"
        return
    fi

    dev=${line%%:*}
    type=$(cut -d: -f2 <<< "$line")

    get_traffic "$dev"

    if [ "$type" = "wifi" ]; then
        # Active access point: SSID + signal strength (0-100).
        ap=$(nmcli -t -f ACTIVE,SSID,SIGNAL device wifi list ifname "$dev" 2>/dev/null \
            | awk -F: '$1 == "yes" { print; exit }')
        ssid=$(cut -d: -f2 <<< "$ap")
        signal=$(cut -d: -f3 <<< "$ap")
        printf "<span color='%s'>  %s (%s%%) [➚%s ➘%s]</span>\n" \
            "$green_color" "${ssid:-Wi-Fi}" "${signal:-?}" "$tx" "$rx"
    else
        conn=$(nmcli -t -f GENERAL.CONNECTION device show "$dev" 2>/dev/null | cut -d: -f2)
        printf "<span color='%s'>  %s [➚%s ➘%s]</span>\n" \
            "$green_color" "${conn:-Wired}" "$tx" "$rx"
    fi
}

main
