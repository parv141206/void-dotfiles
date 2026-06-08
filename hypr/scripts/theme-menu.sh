#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

waybar_colors="$HOME/.config/waybar/colors.css"
rofi_colors="$HOME/.config/rofi/colors.rasi"
rofi_minimal="$HOME/.config/rofi/minimal.rasi"
rofi_wallpaper="$HOME/.config/rofi/wallpaper.rasi"
rofi_wallpaper_list="$HOME/.config/rofi/wallpaper-list.rasi"
kitty_theme="$HOME/.config/kitty/current-theme.conf"
state="$HOME/.cache/hypr-rice-theme"
mkdir -p "$(dirname "$state")"

theme_name="Void green"
amoled=0

if [[ -f "$state" ]]; then
    # shellcheck disable=SC1090
    source "$state"
fi

contrast_fg() {
    local hex="${1#"#"}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    if ((r * 299 + g * 587 + b * 114 > 140000)); then
        printf '#111111'
    else
        printf '#e6e6e6'
    fi
}

mix_hex() {
    local a="${1#"#"}" b="${2#"#"}" pct="$3"
    local ar=$((16#${a:0:2})) ag=$((16#${a:2:2})) ab=$((16#${a:4:2}))
    local br=$((16#${b:0:2})) bg=$((16#${b:2:2})) bb=$((16#${b:4:2}))
    printf '#%02x%02x%02x' \
        $(((ar * (100 - pct) + br * pct) / 100)) \
        $(((ag * (100 - pct) + bg * pct) / 100)) \
        $(((ab * (100 - pct) + bb * pct) / 100))
}

dominant_color() {
    magick "$1" -resize 96x96 -colors 10 -format %c histogram:info:- 2>/dev/null |
        sort -nr |
        awk 'match($0, /#[0-9A-Fa-f]{6}/) { print substr($0, RSTART, RLENGTH); exit }'
}

average_color() {
    magick "$1" -resize 1x1 txt:- 2>/dev/null |
        awk 'match($0, /#[0-9A-Fa-f]{6}/) { print substr($0, RSTART, RLENGTH); exit }'
}

save_state() {
    cat >"$state" <<EOF
theme_name='$theme_name'
amoled=$amoled
last_bg='$last_bg'
last_fg='$last_fg'
last_hi='$last_hi'
last_sep='$last_sep'
last_border='$last_border'
last_panel='$last_panel'
last_panel_hi='$last_panel_hi'
last_accent='$last_accent'
last_red='$last_red'
last_amber='$last_amber'
EOF
}

write_theme() {
    local bg="$1" fg="$2" hi="$3" sep="$4" border="$5" accent="$6" red="$7" amber="$8"
    local panel panel_hi

    panel=$(mix_hex "$bg" "$hi" 4)
    panel_hi=$(mix_hex "$bg" "$hi" 9)

    if [[ "$amoled" == "1" ]]; then
        bg="#000000"
        fg="#b8b8b8"
        hi="#e8e8e8"
        sep="#101010"
        border="#191919"
        panel="#050505"
        panel_hi=$(mix_hex "#000000" "$accent" 16)
    fi

    cat >"$waybar_colors" <<EOF
@define-color bg          $bg;
@define-color fg          $fg;
@define-color fghi       $hi;
@define-color sep         $sep;
@define-color border-bot  $border;
@define-color ws-active   $panel_hi;
@define-color green       $accent;
@define-color red         $red;
@define-color amber       $amber;
EOF

    cat >"$kitty_theme" <<EOF
foreground            $hi
background            $bg
selection_foreground  $bg
selection_background  $accent
cursor                $accent
cursor_text_color     $bg
url_color             $accent

color0                $bg
color8                $sep
color1                $red
color9                $red
color2                $accent
color10               $accent
color3                $amber
color11               $amber
color4                $accent
color12               $accent
color5                $hi
color13               $hi
color6                $accent
color14               $accent
color7                $fg
color15               $hi
EOF

    cat >"$rofi_colors" <<EOF
* {
    bg: $bg;
    fg: $fg;
    fghi: $hi;
    sep: $sep;
    border: $border;
    panel: $panel;
    panelhi: $panel_hi;
    accent: $accent;
    red: $red;
    amber: $amber;
}
EOF

    cat >"$rofi_minimal" <<EOF
* {
    bg: $bg;
    fg: $fg;
    fghi: $hi;
    sep: $sep;
    border: $border;
    panel: $panel;
    panelhi: $panel_hi;
    accent: $accent;
    red: $red;
    amber: $amber;
    font: "JetBrainsMono Nerd Font 12";
    background-color: transparent;
    text-color: @fg;
    border-color: @border;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    width: 38%;
    background-color: @bg;
    border: 1px;
    border-radius: 0;
}

mainbox {
    padding: 12px;
    spacing: 10px;
    children: [inputbar, listview];
}

inputbar {
    padding: 9px 11px;
    border: 1px;
    border-color: @sep;
    background-color: @panel;
    children: [prompt, entry];
}

prompt {
    text-color: @accent;
    padding: 0 10px 0 0;
}

entry {
    text-color: @fghi;
    placeholder-color: @fg;
}

listview {
    lines: 11;
    fixed-height: true;
    scrollbar: false;
    border: 1px 0 0 0;
    border-color: @sep;
}

element {
    padding: 8px 10px;
    spacing: 10px;
    border: 0 0 1px 3px;
    border-color: @sep;
}

element selected.normal {
    background-color: @panelhi;
    border-color: @accent;
}

element-icon {
    size: 1.15em;
}

element-text {
    text-color: inherit;
}

element selected.normal element-text {
    text-color: @fghi;
}
EOF

    cat >"$rofi_wallpaper" <<EOF
* {
    bg: $bg;
    fg: $fg;
    fghi: $hi;
    sep: $sep;
    border: $border;
    panel: $panel;
    panelhi: $panel_hi;
    accent: $accent;
    red: $red;
    amber: $amber;
    font: "JetBrainsMono Nerd Font 11";
    background-color: transparent;
    text-color: @fg;
    border-color: @border;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    width: 72%;
    background-color: @bg;
    border: 1px;
    border-radius: 0;
}

mainbox {
    padding: 12px;
    spacing: 10px;
    children: [inputbar, listview];
}

inputbar {
    padding: 9px 11px;
    border: 1px;
    border-color: @sep;
    background-color: @panel;
    children: [prompt, entry];
}

prompt {
    text-color: @accent;
    padding: 0 10px 0 0;
}

entry {
    text-color: @fghi;
}

listview {
    columns: 3;
    lines: 2;
    fixed-height: true;
    scrollbar: true;
    border: 1px 0 0 0;
    border-color: @sep;
}

element {
    orientation: vertical;
    padding: 9px;
    spacing: 8px;
    border: 0 0 1px 3px;
    border-color: @sep;
}

element selected.normal {
    background-color: @panelhi;
    border-color: @accent;
}

element-icon {
    size: 178px;
}

element-text {
    horizontal-align: 0.5;
    text-color: inherit;
}

element selected.normal element-text {
    text-color: @fghi;
}
EOF

    cat >"$rofi_wallpaper_list" <<EOF
* {
    bg: $bg;
    fg: $fg;
    fghi: $hi;
    sep: $sep;
    border: $border;
    panel: $panel;
    panelhi: $panel_hi;
    accent: $accent;
    red: $red;
    amber: $amber;
    font: "JetBrainsMono Nerd Font 11";
    background-color: transparent;
    text-color: @fg;
    border-color: @border;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    width: 64%;
    background-color: @bg;
    border: 1px;
    border-radius: 0;
}

mainbox {
    padding: 12px;
    spacing: 10px;
    children: [inputbar, listview];
}

inputbar {
    padding: 9px 11px;
    border: 1px;
    border-color: @sep;
    background-color: @panel;
    children: [prompt, entry];
}

prompt {
    text-color: @accent;
    padding: 0 10px 0 0;
}

entry {
    text-color: @fghi;
}

listview {
    columns: 1;
    lines: 14;
    fixed-height: true;
    scrollbar: true;
    border: 1px 0 0 0;
    border-color: @sep;
}

element {
    orientation: horizontal;
    padding: 7px 10px;
    spacing: 10px;
    border: 0 0 1px 3px;
    border-color: @sep;
}

element selected.normal {
    background-color: @panelhi;
    border-color: @accent;
}

element-icon {
    size: 42px;
}

element-text {
    text-color: inherit;
}

element selected.normal element-text {
    text-color: @fghi;
}
EOF

    last_bg="$bg"
    last_fg="$fg"
    last_hi="$hi"
    last_sep="$sep"
    last_border="$border"
    last_panel="$panel"
    last_panel_hi="$panel_hi"
    last_accent="$accent"
    last_red="$red"
    last_amber="$amber"
    save_state
    "$HOME/.config/hypr/scripts/restart-waybar.sh"
}

apply_preset() {
    theme_name="$1"
    case "$theme_name" in
        "Void green") write_theme '#111111' '#555555' '#c8c8c8' '#1e1e1e' '#252525' '#5a8a5a' '#9e4444' '#9e7a35' ;;
        "Slate blue") write_theme '#101113' '#69717c' '#d5dbe3' '#1d2228' '#2b3138' '#6d8fb5' '#a85f5f' '#a88b5f' ;;
        "Rose dusk") write_theme '#121010' '#746666' '#dccdcd' '#241f1f' '#302929' '#b27986' '#a85858' '#a88c5c' ;;
        "Nord frost") write_theme '#0f1217' '#687386' '#d8dee9' '#202630' '#2e3440' '#88c0d0' '#bf616a' '#ebcb8b' ;;
        "Tokyo night") write_theme '#11121a' '#6f7897' '#c0caf5' '#202332' '#2a2e42' '#7aa2f7' '#f7768e' '#e0af68' ;;
        "Catppuccin") write_theme '#11111b' '#7f849c' '#cdd6f4' '#1e1e2e' '#313244' '#a6e3a1' '#f38ba8' '#f9e2af' ;;
        "Gruvbox") write_theme '#1d2021' '#928374' '#ebdbb2' '#282828' '#3c3836' '#b8bb26' '#fb4934' '#fabd2f' ;;
        "Solarized dark") write_theme '#002b36' '#586e75' '#eee8d5' '#073642' '#16434d' '#2aa198' '#dc322f' '#b58900' ;;
        "Everforest") write_theme '#1e2326' '#859289' '#d3c6aa' '#272e33' '#374145' '#a7c080' '#e67e80' '#dbbc7f' ;;
        "Dracula") write_theme '#171821' '#7b8198' '#f8f8f2' '#242633' '#303241' '#50fa7b' '#ff5555' '#f1fa8c' ;;
        "Bone mono") write_theme '#101010' '#646464' '#d0d0d0' '#202020' '#2a2a2a' '#9a9a9a' '#9e5555' '#9e863c' ;;
        "Amber terminal") write_theme '#12100b' '#746a55' '#e1d4ad' '#261f12' '#332817' '#d79921' '#cc5c54' '#fabd2f' ;;
    esac
}

from_wallpaper() {
    local img="${1:-}"
    if [[ -z "$img" && -f "$HOME/.cache/hypr-current-wallpaper" ]]; then
        img=$(<"$HOME/.cache/hypr-current-wallpaper")
    fi

    if [[ -z "$img" || ! -f "$img" ]]; then
        notify "Theme" "No current wallpaper found."
        exit 1
    fi

    local avg accent fg hi sep border
    avg=$(average_color "$img")
    accent=$(dominant_color "$img")
    [[ -n "$avg" ]] || avg="#111111"
    [[ -n "$accent" ]] || accent="#5a8a5a"

    fg=$(mix_hex "$avg" "$(contrast_fg "$avg")" 45)
    hi=$(contrast_fg "$avg")
    sep=$(mix_hex "$avg" "$hi" 12)
    border=$(mix_hex "$avg" "$hi" 18)

    theme_name="Wallpaper"
    write_theme "$avg" "$fg" "$hi" "$sep" "$border" "$accent" '#9e4444' '#d79921'
    notify "Theme" "Picked colors from $(basename "$img")"
}

pick_accent() {
    local accent bg fg hi sep border red amber
    accent=$(hyprpicker -a 2>/dev/null || true)
    [[ -n "$accent" ]] || exit 0

    bg="${last_bg:-#111111}"
    fg="${last_fg:-#555555}"
    hi="${last_hi:-#c8c8c8}"
    sep="${last_sep:-#1e1e1e}"
    border="${last_border:-#252525}"
    red="${last_red:-#9e4444}"
    amber="${last_amber:-#9e7a35}"
    write_theme "$bg" "$fg" "$hi" "$sep" "$border" "$accent" "$red" "$amber"
    notify "Theme" "Accent set to $accent"
}

toggle_amoled() {
    if [[ "$amoled" == "1" ]]; then
        amoled=0
    else
        amoled=1
    fi

    if [[ "$theme_name" == "Wallpaper" ]]; then
        from_wallpaper
    else
        apply_preset "$theme_name"
    fi
}

case "${1:-menu}" in
    preset) apply_preset "${2:-Void green}" ;;
    wallpaper) from_wallpaper "${2:-}" ;;
    pick) pick_accent ;;
    amoled) toggle_amoled ;;
    menu)
        amoled_label="AMOLED: off"
        [[ "$amoled" == "1" ]] && amoled_label="AMOLED: on"
        choice=$(printf '%s\n' \
            "Void green" \
            "Slate blue" \
            "Rose dusk" \
            "Nord frost" \
            "Tokyo night" \
            "Catppuccin" \
            "Gruvbox" \
            "Solarized dark" \
            "Everforest" \
            "Dracula" \
            "Bone mono" \
            "Amber terminal" \
            "$amoled_label" \
            "Pick colors from current wallpaper" \
            "Pick accent from screen" \
            "Restart Waybar" | menu "theme")
        case "$choice" in
            "$amoled_label") toggle_amoled ;;
            "Pick colors from current wallpaper") from_wallpaper ;;
            "Pick accent from screen") pick_accent ;;
            "Restart Waybar") "$HOME/.config/hypr/scripts/restart-waybar.sh" ;;
            "") exit 0 ;;
            *) apply_preset "$choice" ;;
        esac
        ;;
esac
