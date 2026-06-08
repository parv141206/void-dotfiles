#!/usr/bin/env bash

theme="$HOME/.config/rofi/minimal.rasi"

menu() {
    local prompt="$1"
    rofi -dmenu -i -show-icons -theme "$theme" -p "$prompt"
}

menu_custom() {
    local prompt="$1"
    rofi -dmenu -i -show-icons -theme "$theme" -p "$prompt"
}

notify() {
    notify-send -t 2500 "$@"
}
