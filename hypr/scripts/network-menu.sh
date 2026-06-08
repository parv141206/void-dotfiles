#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

wifi_state=$(nmcli -t -f WIFI g 2>/dev/null || printf 'unknown')

list_networks() {
    nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null |
        awk -F: 'length($2) { printf "%s %s  %s%%  %s\n", ($1=="yes" ? "*" : " "), $2, $3, $4 }'
}

refresh_networks() {
    notify "Network" "Refreshing Wi-Fi list"
    nmcli dev wifi rescan >/dev/null 2>&1 || true
    exec "$0"
}

connect_network() {
    local ssid="$1"
    [[ -n "$ssid" ]] || exit 0

    if nmcli dev wifi connect "$ssid" >/dev/null 2>&1; then
        notify "Network" "Connected to $ssid"
        exit 0
    fi

    pass=$(rofi -dmenu -password -theme "$theme" -p "password")
    [[ -n "$pass" ]] || exit 0

    if nmcli dev wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify "Network" "Connected to $ssid"
    else
        notify-send -u critical "Network" "Could not connect to $ssid"
    fi
}

entries=$( {
    printf 'Wi-Fi: %s\n' "$wifi_state"
    printf '%s\n' "Refresh networks" "Toggle Wi-Fi" "Open nmtui"
    list_networks
} )

choice=$(printf '%s\n' "$entries" | menu "network")
case "$choice" in
    "") exit 0 ;;
    "Refresh networks")
        refresh_networks
        ;;
    "Toggle Wi-Fi")
        if [[ "$wifi_state" == "enabled" ]]; then nmcli radio wifi off; else nmcli radio wifi on; fi
        ;;
    "Open nmtui")
        kitty -e nmtui &
        ;;
    "Wi-Fi:"*) ;;
    *)
        ssid=$(printf '%s\n' "$choice" | sed -E 's/^\*? +//; s/  [0-9]+%.*$//')
        connect_network "$ssid"
        ;;
esac
