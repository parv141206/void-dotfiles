#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

if ! command -v cliphist >/dev/null 2>&1; then
    notify "Clipboard" "cliphist is not installed."
    exit 1
fi

choice=$(cliphist list | menu "clipboard")
[[ -n "$choice" ]] || exit 0

printf '%s' "$choice" | cliphist decode | wl-copy
notify "Clipboard" "Copied selection"
