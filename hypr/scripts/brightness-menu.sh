#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

choice=$(printf '%s\n' "10%" "25%" "40%" "55%" "70%" "85%" "100%" | menu "brightness")
[[ -n "$choice" ]] || exit 0
brightnessctl set "$choice"
