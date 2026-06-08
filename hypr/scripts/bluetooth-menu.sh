#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}')

device_lines() {
    bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
        [[ -n "$mac" ]] || continue
        state="off"
        bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes' && state="on"
        printf '%s  %s  %s\n' "$state" "$mac" "$name"
    done
}

entries=$( {
    printf 'Bluetooth: %s\n' "${powered:-unknown}"
    printf '%s\n' "Power on" "Power off" "Scan now" "Open blueman"
    device_lines
} )

choice=$(printf '%s\n' "$entries" | menu "bluetooth")
case "$choice" in
    "") exit 0 ;;
    "Power on") rfkill unblock bluetooth 2>/dev/null || true; bluetoothctl power on ;;
    "Power off") bluetoothctl power off ;;
    "Scan now") rfkill unblock bluetooth 2>/dev/null || true; bluetoothctl power on; timeout 8s bluetoothctl scan on >/dev/null 2>&1 || true; notify "Bluetooth" "Scan complete" ;;
    "Open blueman") blueman-manager & ;;
    Bluetooth:*) ;;
    *)
        mac=$(printf '%s\n' "$choice" | awk '{print $2}')
        [[ -n "$mac" ]] || exit 0
        if bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes'; then
            bluetoothctl disconnect "$mac"
        else
            rfkill unblock bluetooth 2>/dev/null || true
            bluetoothctl power on
            bluetoothctl connect "$mac"
        fi
        ;;
esac
