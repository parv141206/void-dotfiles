#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

confirm() {
    local action="$1"
    local answer
    answer=$(printf '%s\n' "No" "Yes" | menu "$action?")
    [[ "$answer" == "Yes" ]]
}

current=$(powerprofilesctl get 2>/dev/null || printf 'balanced')

choice=$(printf '%s\n' \
    "Profile: $current" \
    "Set performance" \
    "Set balanced" \
    "Set power-saver" \
    "Lock" \
    "Suspend" \
    "Logout Hyprland" \
    "Reboot" \
    "Power off" | menu "power")

case "$choice" in
    "Set performance") powerprofilesctl set performance ;;
    "Set balanced") powerprofilesctl set balanced ;;
    "Set power-saver") powerprofilesctl set power-saver ;;
    "Lock") "$HOME/.config/hypr/scripts/lock.sh" ;;
    "Suspend") confirm "suspend" && systemctl suspend ;;
    "Logout Hyprland") confirm "logout" && hyprctl dispatch exit ;;
    "Reboot") confirm "reboot" && systemctl reboot ;;
    "Power off") confirm "power off" && systemctl poweroff ;;
esac
