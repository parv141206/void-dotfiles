#!/usr/bin/env bash

if ! command -v bluetoothctl >/dev/null 2>&1; then
    printf '{"text":"󰂲 n/a","class":"off"}\n'
    exit 0
fi

powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}')
if [[ "$powered" != "yes" ]]; then
    printf '{"text":"󰂲 off","class":"off"}\n'
    exit 0
fi

connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
if ((connected > 0)); then
    printf '{"text":"󰂱 %s","class":"on"}\n' "$connected"
else
    printf '{"text":"󰂯 on","class":"on"}\n'
fi
