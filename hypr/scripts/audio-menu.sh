#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

entries=$(printf '%s\n' \
    "Toggle mute" \
    "Volume +5%" \
    "Volume -5%" \
    "Open pavucontrol")

choice=$(printf '%s\n' "$entries" | menu "audio")
case "$choice" in
    "Toggle mute") pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    "Volume +5%") wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    "Volume -5%") wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    "Open pavucontrol") pavucontrol & ;;
esac
