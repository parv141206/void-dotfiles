#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

wallpaper_theme="$HOME/.config/rofi/wallpaper.rasi"
wallpaper_list_theme="$HOME/.config/rofi/wallpaper-list.rasi"
view_state="$HOME/.cache/hypr-wallpaper-view"
map_file=$(mktemp)
trap 'rm -f "$map_file"' EXIT

wall_dirs=(
    "$HOME/Pictures"
)

current_view() {
    local view="grid"
    [[ -f "$view_state" ]] && view=$(<"$view_state")
    case "$view" in
        grid|list) printf '%s\n' "$view" ;;
        *) printf 'grid\n' ;;
    esac
}

set_view() {
    mkdir -p "$(dirname "$view_state")"
    printf '%s\n' "$1" >"$view_state"
}

wallpaper_files() {
    find "${wall_dirs[@]}" -maxdepth 5 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort -u
}

wallpaper_label() {
    local img="$1" view="$2"
    if [[ "$view" == "list" ]]; then
        printf '%s\n' "${img#"$HOME/Pictures/"}"
    else
        printf '%s\n' "$(basename "$img")"
    fi
}

start_hyprpaper() {
    if ! pgrep -u "$USER" -x hyprpaper >/dev/null 2>&1; then
        setsid -f hyprpaper >/dev/null 2>&1
        sleep 0.4
    fi
}

monitor_names() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null
}

write_hyprpaper_config() {
    local img="$1"
    local conf="$HOME/.config/hypr/hyprpaper.conf"
    local monitors

    monitors=$(monitor_names)
    {
        printf 'ipc = on\n'
        printf 'splash = false\n'
        printf 'preload = %s\n' "$img"
        if [[ -n "$monitors" ]]; then
            while IFS= read -r mon; do
                [[ -n "$mon" ]] && printf 'wallpaper = %s,%s\n' "$mon" "$img"
            done <<<"$monitors"
        else
            printf 'wallpaper = ,%s\n' "$img"
        fi
    } >"$conf"
}

set_wallpaper() {
    local img="$1"
    [[ -f "$img" ]] || exit 1

    write_hyprpaper_config "$img"
    start_hyprpaper
    hyprctl hyprpaper preload "$img" >/dev/null 2>&1 || true
    if monitor_names | grep -q .; then
        while IFS= read -r mon; do
            [[ -n "$mon" ]] && hyprctl hyprpaper wallpaper "$mon,$img" >/dev/null 2>&1 || true
        done < <(monitor_names)
    else
        hyprctl hyprpaper wallpaper ",$img" >/dev/null 2>&1 || true
    fi
    printf '%s\n' "$img" >"$HOME/.cache/hypr-current-wallpaper"
    notify "Wallpaper" "$(basename "$img")"
}

random_wallpaper() {
    local img
    img=$(wallpaper_files | shuf -n 1)
    [[ -n "$img" ]] && set_wallpaper "$img"
}

emit_choices() {
    local view="${1:-grid}"
    : >"$map_file"

    printf '%s\n' "Refresh wallpapers"
    printf '%s\n' "action:refresh" >>"$map_file"

    if [[ "$view" == "grid" ]]; then
        printf '%s\n' "Switch to list view"
        printf '%s\n' "action:view-list" >>"$map_file"
    else
        printf '%s\n' "Switch to grid view"
        printf '%s\n' "action:view-grid" >>"$map_file"
    fi

    printf '%s\n' "Random wallpaper"
    printf '%s\n' "action:random" >>"$map_file"

    printf '%s\n' "Theme from current wallpaper"
    printf '%s\n' "action:theme-current" >>"$map_file"

    printf '%s\n' "Set wallpaper and pick colors"
    printf '%s\n' "action:set-theme" >>"$map_file"

    while IFS= read -r img; do
        label=$(wallpaper_label "$img" "$view")
        printf '%s\0icon\x1f%s\n' "$label" "$img"
        printf '%s\n' "$img" >>"$map_file"
    done < <(wallpaper_files)
}

case "${1:-menu}" in
    set)
        set_wallpaper "$2"
        ;;
    random)
        random_wallpaper
        ;;
    menu)
        view=$(current_view)
        if [[ "$view" == "list" ]]; then
            rofi_theme="$wallpaper_list_theme"
            prompt="wallpaper list"
        else
            rofi_theme="$wallpaper_theme"
            prompt="wallpaper grid"
        fi

        index=$(emit_choices "$view" | rofi -dmenu -i -show-icons -format i -theme "$rofi_theme" -p "$prompt")
        [[ -n "$index" && "$index" != "-1" ]] || exit 0

        selected=$(sed -n "$((index + 1))p" "$map_file")
        case "$selected" in
            action:refresh)
                exec "$0" menu
                ;;
            action:view-list)
                set_view list
                exec "$0" menu
                ;;
            action:view-grid)
                set_view grid
                exec "$0" menu
                ;;
            action:random)
                random_wallpaper
                ;;
            action:theme-current)
                "$HOME/.config/hypr/scripts/theme-menu.sh" wallpaper
                ;;
            action:set-theme)
                img_index=$(wallpaper_files | nl -w1 -s'. ' | rofi -dmenu -i -format i -theme "$theme" -p "set + theme")
                [[ -n "$img_index" && "$img_index" != "-1" ]] || exit 0
                img=$(wallpaper_files | sed -n "$((img_index + 1))p")
                set_wallpaper "$img"
                "$HOME/.config/hypr/scripts/theme-menu.sh" wallpaper "$img"
                ;;
            *)
                set_wallpaper "$selected"
                ;;
        esac
        ;;
esac
