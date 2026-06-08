#!/usr/bin/env bash

set -euo pipefail

start_once() {
    local name="$1"
    shift

    if ! pgrep -u "$USER" -x "$name" >/dev/null 2>&1; then
        setsid -f "$@" >/dev/null 2>&1
    fi
}

start_script_once() {
    local pattern="$1"
    shift

    if ! pgrep -u "$USER" -f "$pattern" >/dev/null 2>&1; then
        setsid -f "$@" >/dev/null 2>&1
    fi
}

export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND=wayland,x11
export ELECTRON_OZONE_PLATFORM_HINT=auto

systemctl --user import-environment \
    WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
    DBUS_SESSION_BUS_ADDRESS GDK_BACKEND QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME \
    MOZ_ENABLE_WAYLAND ELECTRON_OZONE_PLATFORM_HINT >/dev/null 2>&1 || true
dbus-update-activation-environment --systemd \
    WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
    GDK_BACKEND QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME MOZ_ENABLE_WAYLAND \
    ELECTRON_OZONE_PLATFORM_HINT >/dev/null 2>&1 || true

start_once pipewire pipewire
start_once waybar waybar

if command -v mako >/dev/null 2>&1; then
    start_once mako mako
fi

if command -v hypridle >/dev/null 2>&1; then
    start_once hypridle hypridle
fi

if command -v playerctld >/dev/null 2>&1; then
    start_once playerctld playerctld
fi

if command -v hyprpaper >/dev/null 2>&1; then
    start_once hyprpaper hyprpaper
fi

if [[ -f "$HOME/.cache/hypr-current-wallpaper" ]]; then
    "$HOME/.config/hypr/scripts/wallpaper-menu.sh" set "$(<"$HOME/.cache/hypr-current-wallpaper")" >/dev/null 2>&1 || true
fi

if command -v wl-paste >/dev/null 2>&1 && command -v cliphist >/dev/null 2>&1; then
    start_script_once "wl-paste --type text --watch cliphist store" wl-paste --type text --watch cliphist store
    start_script_once "wl-paste --type image --watch cliphist store" wl-paste --type image --watch cliphist store
fi

start_script_once "$HOME/.config/hypr/scripts/battery_notify.sh" "$HOME/.config/hypr/scripts/battery_notify.sh"
