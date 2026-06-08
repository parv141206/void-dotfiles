#!/usr/bin/env bash

profile=$(powerprofilesctl get 2>/dev/null || printf 'balanced')
icon="󰓅"
case "$profile" in
    performance) icon="󰓅" ;;
    power-saver) icon="󰾆" ;;
    balanced) icon="󰾅" ;;
esac

printf '{"text":"%s %s","class":"%s"}\n' "$icon" "$profile" "$profile"
