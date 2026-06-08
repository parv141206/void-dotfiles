#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

{
    date '+%A, %d %B %Y'
    date '+%I:%M:%S %p'
    printf '\n'
    if command -v cal >/dev/null 2>&1; then
        cal -m
    fi
} | menu "clock" >/dev/null
