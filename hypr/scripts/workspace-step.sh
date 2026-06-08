#!/usr/bin/env bash

set -euo pipefail

dir="${1:-}"
current=$(hyprctl -j activeworkspace | jq -r '.id')

case "$dir" in
    next)
        target=$((current + 1))
        ;;
    prev)
        target=$((current - 1))
        if ((target < 1)); then
            target=1
        fi
        ;;
    *)
        echo "Usage: $0 next|prev" >&2
        exit 1
        ;;
esac

hyprctl dispatch workspace "$target"
