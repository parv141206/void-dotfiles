#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

info=""
if command -v upower >/dev/null 2>&1; then
    battery=$(upower -e 2>/dev/null | grep BAT | head -1 || true)
    if [[ -n "$battery" ]]; then
        info=$(upower -i "$battery" 2>/dev/null |
            awk -F: '/state|percentage|time to empty|time to full|energy-rate/ {gsub(/^ +| +$/, "", $2); print $1 ": " $2}' |
            sed 's/^ *//')
    fi
fi

if [[ -z "$info" && -r /sys/class/power_supply/BAT0/capacity ]]; then
    info="percentage: $(< /sys/class/power_supply/BAT0/capacity)%"
fi

[[ -n "$info" ]] || info="No battery info available"

choice=$(printf '%s\n\n%s\n' "$info" "Power menu" | menu "battery")
[[ "$choice" == "Power menu" ]] && "$HOME/.config/hypr/scripts/power-menu.sh"
