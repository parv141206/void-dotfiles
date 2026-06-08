#!/usr/bin/env bash

pkill -x waybar 2>/dev/null || true
setsid -f env GDK_BACKEND=wayland waybar >/dev/null 2>&1
