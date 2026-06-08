#!/usr/bin/env bash

pkill -x waybar 2>/dev/null || true
for _ in {1..30}; do
    pgrep -x waybar >/dev/null 2>&1 || break
    sleep 0.05
done
pkill -9 -x waybar 2>/dev/null || true
setsid -f env GDK_BACKEND=wayland waybar >/dev/null 2>&1
