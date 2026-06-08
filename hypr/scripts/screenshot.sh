#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

mode="${1:-menu}"
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
file="$dir/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$dir"

geometry_area() {
    slurp
}

geometry_active() {
    hyprctl activewindow -j |
        jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

capture() {
    local target="$1" output="$2"
    case "$target" in
        full)
            grim "$output"
            ;;
        area)
            local geom
            geom=$(geometry_area)
            [[ -n "$geom" ]] || exit 0
            grim -g "$geom" "$output"
            ;;
        active)
            local geom
            geom=$(geometry_active)
            [[ -n "$geom" && "$geom" != "null,null nullxnull" ]] || exit 1
            grim -g "$geom" "$output"
            ;;
    esac
}

copy_png() {
    wl-copy --type image/png < "$1"
    notify "Screenshot" "Copied to clipboard"
}

edit_png() {
    local img="$1"
    if command -v satty >/dev/null 2>&1; then
        satty --filename "$img" --output-filename "$img" \
            --copy-command wl-copy \
            --actions-on-enter save-to-file \
            --actions-on-right-click save-to-clipboard \
            --no-window-decoration >/dev/null 2>&1 &
        return
    fi

    if command -v swappy >/dev/null 2>&1; then
        swappy -f "$img" -o "$img" >/dev/null 2>&1 &
        return
    fi

    notify "Screenshot" "Install satty or swappy for editing."
}

save_shot() {
    capture "$1" "$file"
    notify "Screenshot saved" "$file"
}

copy_shot() {
    local tmp
    tmp=$(mktemp --suffix=.png)
    trap "rm -f '$tmp'" EXIT
    capture "$1" "$tmp"
    copy_png "$tmp"
}

edit_shot() {
    capture "$1" "$file"
    edit_png "$file"
}

case "$mode" in
    full) save_shot full ;;
    area) save_shot area ;;
    active) save_shot active ;;
    full-copy) copy_shot full ;;
    area-copy) copy_shot area ;;
    active-copy) copy_shot active ;;
    full-edit) edit_shot full ;;
    area-edit) edit_shot area ;;
    active-edit) edit_shot active ;;
    menu)
        notify "Screenshot" "Opening screenshot manager"
        choice=$(printf '%s\n' \
            "Area: edit" \
            "Area: save" \
            "Area: copy" \
            "Active window: edit" \
            "Active window: save" \
            "Active window: copy" \
            "Full screen: edit" \
            "Full screen: save" \
            "Full screen: copy" | menu "screenshot")
        case "$choice" in
            "Area: edit") edit_shot area ;;
            "Area: save") save_shot area ;;
            "Area: copy") copy_shot area ;;
            "Active window: edit") edit_shot active ;;
            "Active window: save") save_shot active ;;
            "Active window: copy") copy_shot active ;;
            "Full screen: edit") edit_shot full ;;
            "Full screen: save") save_shot full ;;
            "Full screen: copy") copy_shot full ;;
        esac
        ;;
    *)
        echo "Usage: $0 [menu|full|area|active|full-copy|area-copy|active-copy|full-edit|area-edit|active-edit]" >&2
        exit 1
        ;;
esac
