#!/usr/bin/env bash

if command -v swaylock >/dev/null 2>&1; then
    exec swaylock -f
fi

if command -v hyprlock >/dev/null 2>&1; then
    exec hyprlock
fi

notify-send -u critical "No lock command found" "Install swaylock or hyprlock."
