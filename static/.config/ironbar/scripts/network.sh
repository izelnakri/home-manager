#!/bin/bash

get_wireless_network() {
    iwgetid -r
}

get_signal_strength() {
    awk 'NR==line {printf(fmt, $3*10/7)}' line=3 fmt='%.0f' /proc/net/wireless
}

get_outgoing_traffic() {
    vnstat -tr 2 | awk '/tx/ {print $2, $3}'
}

get_incoming_traffic() {
    vnstat -tr 2 | awk '/rx/ {print $2, $3}'
}

main() {
    if iwgetid &> /dev/null; then
        wireless_network=$(get_wireless_network)
        signal_strength=$(get_signal_strength)
        outgoing_traffic=$(get_outgoing_traffic)
        incoming_traffic=$(get_incoming_traffic)

        printf "  %s (%s%%) [➚%s ➘%s]\n" "$wireless_network" "$signal_strength" "$outgoing_traffic" "$incoming_traffic"
    else
        echo " Disconnected"
    fi
}

main
