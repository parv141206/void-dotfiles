#!/usr/bin/env bash

last_state=""
last_low=0
last_full=0
low=20
battery="${BATTERY:-/sys/class/power_supply/BAT0}"

if [[ ! -r "$battery/capacity" || ! -r "$battery/status" ]]; then
    exit 0
fi

while true; do
    level=$(<"$battery/capacity")
    state=$(<"$battery/status")
    now=$(date +%s)

    if [[ "$state" == "Discharging" && "$level" -le "$low" ]]; then
        if ((now - last_low >= 60)); then
            notify-send -u critical -t 5000 "Battery Low" "${level}%"
            last_low=$now
        fi
    elif [[ "$state" == "Full" ]]; then
        if ((now - last_full >= 60)); then
            notify-send -t 5000 "Battery Full" "Unplug charger"
            last_full=$now
        fi
    elif [[ "$state" == "Charging" && "$last_state" != "Charging" ]]; then
        last_low=0
        last_full=0
        notify-send "Battery Charging" "${level}%"
    fi

    last_state="$state"
    sleep 5
done
