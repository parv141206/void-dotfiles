#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

waybar_colors="$HOME/.config/waybar/colors.css"
rofi_colors="$HOME/.config/rofi/colors.rasi"
rofi_minimal="$HOME/.config/rofi/minimal.rasi"
rofi_wallpaper="$HOME/.config/rofi/wallpaper.rasi"
rofi_wallpaper_list="$HOME/.config/rofi/wallpaper-list.rasi"
kitty_theme="$HOME/.config/kitty/current-theme.conf"
gtk3_dir="$HOME/.config/gtk-3.0"
gtk4_dir="$HOME/.config/gtk-4.0"
qt5_colors="$HOME/.config/qt5ct/colors/matugen.conf"
qt5_qss="$HOME/.config/qt5ct/qss/matugen-style.qss"
qt6_colors="$HOME/.config/qt6ct/colors/matugen.conf"
qt6_qss="$HOME/.config/qt6ct/qss/matugen-style.qss"
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

refresh_app_theme() {
    touch "$gtk3_dir/gtk.css" "$gtk4_dir/gtk.css" "$gtk3_dir/settings.ini" "$gtk4_dir/settings.ini" 2>/dev/null || true

    if command -v gsettings >/dev/null 2>&1; then
        local current_font
        current_font=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null || printf "'JetBrainsMono Nerd Font 11'")
        current_font="${current_font#\'}"
        current_font="${current_font%\'}"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface gtk-theme 'HighContrast' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface font-name "$current_font" >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface accent-color 'purple' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface accent-color 'slate' >/dev/null 2>&1 || true
    fi

    if command -v xsettingsd >/dev/null 2>&1; then
        pkill -HUP xsettingsd >/dev/null 2>&1 || true
    fi

    systemctl --user import-environment GTK_THEME QT_QPA_PLATFORMTHEME QT_QPA_PLATFORM XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP >/dev/null 2>&1 || true
    dbus-update-activation-environment --systemd GTK_THEME QT_QPA_PLATFORMTHEME QT_QPA_PLATFORM XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP >/dev/null 2>&1 || true
}

write_app_theme() {
    local bg="$1" fg="$2" hi="$3" sep="$4" border="$5" accent="$6" red="$7" amber="$8" panel="$9" panel_hi="${10}"
    local accent_fg disabled_fg trough success qss_fg

    mkdir -p "$gtk3_dir" "$gtk4_dir" "$(dirname "$qt5_colors")" "$(dirname "$qt5_qss")" "$(dirname "$qt6_colors")" "$(dirname "$qt6_qss")"

    accent_fg=$(contrast_fg "$accent")
    disabled_fg=$(mix_hex "$fg" "$bg" 35)
    trough=$(mix_hex "$bg" "$hi" 10)
    success="$accent"
    qss_fg="$hi"

    for qt_conf in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
        local qt_base qt_color qt_qss
        qt_base=$(basename "$(dirname "$qt_conf")")
        if [[ "$qt_base" == "qt6ct" ]]; then
            qt_color="$qt6_colors"
            qt_qss="$qt6_qss"
        else
            qt_color="$qt5_colors"
            qt_qss="$qt5_qss"
        fi
        mkdir -p "$(dirname "$qt_conf")"
        if [[ ! -f "$qt_conf" ]]; then
            cat >"$qt_conf" <<EOF
[Appearance]
color_scheme_path=$qt_color
custom_palette=true
standard_dialogs=default
style=Fusion
stylesheets=$qt_qss

[Interface]
stylesheets=$qt_qss
EOF
        else
            sed -i \
                -e "s|^color_scheme_path=.*|color_scheme_path=$qt_color|" \
                -e "s|^custom_palette=.*|custom_palette=true|" \
                -e "s|^stylesheets=.*|stylesheets=$qt_qss|" \
                "$qt_conf"
        fi
    done

    for dir in "$gtk3_dir" "$gtk4_dir"; do
        cat >"$dir/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-icon-theme-name=Adwaita
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
EOF
    done

    cat >"$gtk3_dir/gtk.css" <<EOF
/* Generated by ~/.config/hypr/scripts/theme-menu.sh */
@define-color theme_bg_color $bg;
@define-color theme_fg_color $hi;
@define-color theme_base_color $panel;
@define-color theme_text_color $hi;
@define-color theme_selected_bg_color $accent;
@define-color theme_selected_fg_color $accent_fg;
@define-color insensitive_bg_color $panel;
@define-color insensitive_fg_color $disabled_fg;
@define-color borders $border;
@define-color unfocused_borders $sep;
@define-color warning_color $amber;
@define-color error_color $red;
@define-color success_color $success;

* {
    caret-color: $accent;
    outline-color: $accent;
    -gtk-icon-shadow: none;
}

window, dialog, popover, menu, .background {
    background-color: $bg;
    color: $hi;
}

headerbar, .titlebar, toolbar, menubar {
    background-color: $panel;
    color: $hi;
    border-color: $border;
}

button, entry, spinbutton, combobox, notebook > header, treeview.view, list, row {
    background-color: $panel;
    color: $hi;
    border-color: $border;
}

button:hover, row:hover, treeview.view:hover {
    background-color: $panel_hi;
}

button:checked, button:active, row:selected, treeview.view:selected {
    background-color: $accent;
    color: $accent_fg;
}

entry selection, textview text selection, label selection {
    background-color: $accent;
    color: $accent_fg;
}

scrollbar slider, scale highlight, progressbar progress {
    background-color: $accent;
}

scrollbar trough, scale trough, progressbar trough {
    background-color: $trough;
}

switch:checked {
    background-color: $accent;
}

separator {
    background-color: $sep;
}
EOF

    cat >"$gtk4_dir/gtk.css" <<EOF
/* Generated by ~/.config/hypr/scripts/theme-menu.sh */
@define-color accent_color $accent;
@define-color accent_bg_color $accent;
@define-color accent_fg_color $accent_fg;
@define-color destructive_color $red;
@define-color destructive_bg_color $red;
@define-color destructive_fg_color $(contrast_fg "$red");
@define-color success_color $success;
@define-color success_bg_color $success;
@define-color success_fg_color $(contrast_fg "$success");
@define-color warning_color $amber;
@define-color warning_bg_color $amber;
@define-color warning_fg_color $(contrast_fg "$amber");
@define-color error_color $red;
@define-color error_bg_color $red;
@define-color error_fg_color $(contrast_fg "$red");
@define-color window_bg_color $bg;
@define-color window_fg_color $hi;
@define-color view_bg_color $bg;
@define-color view_fg_color $hi;
@define-color headerbar_bg_color $panel;
@define-color headerbar_fg_color $hi;
@define-color headerbar_border_color $border;
@define-color headerbar_backdrop_color $bg;
@define-color card_bg_color $panel;
@define-color card_fg_color $hi;
@define-color dialog_bg_color $bg;
@define-color dialog_fg_color $hi;
@define-color popover_bg_color $panel;
@define-color popover_fg_color $hi;
@define-color shade_color alpha($hi, 0.10);
@define-color scrollbar_outline_color $border;

* {
    caret-color: $accent;
    outline-color: $accent;
}

window, dialog, popover, .background {
    background-color: $bg;
    color: $hi;
}

headerbar, toolbar, tabbar {
    background-color: $panel;
    color: $hi;
    border-color: $border;
}

button, entry, spinbutton, dropdown, list, row, .card {
    background-color: $panel;
    color: $hi;
    border-color: $border;
}

button:hover, row:hover {
    background-color: $panel_hi;
}

button:checked, button:active, row:selected {
    background-color: $accent;
    color: $accent_fg;
}

selection {
    background-color: $accent;
    color: $accent_fg;
}

switch:checked, scale highlight, progressbar progress {
    background-color: $accent;
}
EOF

    cat >"$qt5_colors" <<EOF
[ColorScheme]
active_colors=$qss_fg, $panel, $hi, $fg, $disabled_fg, $fg, $qss_fg, $hi, $qss_fg, $bg, $panel, $border, $accent, $accent_fg, $panel_hi, $accent, $accent_fg, $bg, $panel, $qss_fg, $disabled_fg
disabled_colors=$disabled_fg, $panel, $hi, $fg, $disabled_fg, $fg, $disabled_fg, $hi, $disabled_fg, $bg, $panel, $border, $accent, $accent_fg, $panel_hi, $accent, $accent_fg, $bg, $panel, $disabled_fg, $disabled_fg
inactive_colors=$qss_fg, $panel, $hi, $fg, $disabled_fg, $fg, $qss_fg, $hi, $qss_fg, $bg, $panel, $border, $accent, $accent_fg, $panel_hi, $accent, $accent_fg, $bg, $panel, $qss_fg, $disabled_fg
EOF
    cp "$qt5_colors" "$qt6_colors"

    cat >"$qt5_qss" <<EOF
* {
    selection-background-color: $accent;
    selection-color: $accent_fg;
}

QToolTip {
    color: $hi;
    background-color: $panel;
    border: 1px solid $border;
}
EOF
    cp "$qt5_qss" "$qt6_qss"

    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface accent-color 'slate' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11' >/dev/null 2>&1 || true
    fi

    refresh_app_theme
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
@define-color panel       $panel;
@define-color panel-hi    $panel_hi;
@define-color accent      $accent;
@define-color accent-soft $(mix_hex "$accent" "$hi" 36);
@define-color accent-dim  $(mix_hex "$accent" "$bg" 38);
@define-color text-soft   $(mix_hex "$fg" "$hi" 34);
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

    write_app_theme "$bg" "$fg" "$hi" "$sep" "$border" "$accent" "$red" "$amber" "$panel" "$panel_hi"

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
        "Oxocarbon") write_theme '#161616' '#6f6f6f' '#f2f4f8' '#262626' '#393939' '#78a9ff' '#ff7eb6' '#f1c21b' ;;
        "Kanagawa") write_theme '#1f1f28' '#727169' '#dcd7ba' '#2a2a37' '#363646' '#7e9cd8' '#c34043' '#c0a36e' ;;
        "Monokai") write_theme '#161821' '#75715e' '#f8f8f2' '#272822' '#3a3a32' '#a6e22e' '#f92672' '#e6db74' ;;
        "Moonlight") write_theme '#11131f' '#828bb8' '#c8d3f5' '#1b1e2e' '#2f334d' '#82aaff' '#ff757f' '#ffc777' ;;
        "Cyber noir") write_theme '#080b12' '#5f7187' '#d7f9ff' '#101826' '#1f2a3d' '#00e5ff' '#ff2f6d' '#fcee0a' ;;
        "Matcha") write_theme '#111814' '#6f7d72' '#d5e8d4' '#1b241d' '#28342b' '#8fbf7f' '#d07171' '#d8b66d' ;;
        "Orchid") write_theme '#141018' '#74647c' '#eadcf8' '#211826' '#322238' '#c792ea' '#ff6e91' '#f7d774' ;;
        "Iceberg") write_theme '#0f1117' '#6b7089' '#d4d7e5' '#161821' '#272c3f' '#84a0c6' '#e27878' '#e2a478' ;;
    esac
}

theme_names() {
    printf '%s\n' \
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
        "Oxocarbon" \
        "Kanagawa" \
        "Monokai" \
        "Moonlight" \
        "Cyber noir" \
        "Matcha" \
        "Orchid" \
        "Iceberg"
}

preset_palette() {
    case "$1" in
        "Void green") printf '%s\n' '#111111 #555555 #c8c8c8 #5a8a5a #9e4444 #9e7a35' ;;
        "Slate blue") printf '%s\n' '#101113 #69717c #d5dbe3 #6d8fb5 #a85f5f #a88b5f' ;;
        "Rose dusk") printf '%s\n' '#121010 #746666 #dccdcd #b27986 #a85858 #a88c5c' ;;
        "Nord frost") printf '%s\n' '#0f1217 #687386 #d8dee9 #88c0d0 #bf616a #ebcb8b' ;;
        "Tokyo night") printf '%s\n' '#11121a #6f7897 #c0caf5 #7aa2f7 #f7768e #e0af68' ;;
        "Catppuccin") printf '%s\n' '#11111b #7f849c #cdd6f4 #a6e3a1 #f38ba8 #f9e2af' ;;
        "Gruvbox") printf '%s\n' '#1d2021 #928374 #ebdbb2 #b8bb26 #fb4934 #fabd2f' ;;
        "Solarized dark") printf '%s\n' '#002b36 #586e75 #eee8d5 #2aa198 #dc322f #b58900' ;;
        "Everforest") printf '%s\n' '#1e2326 #859289 #d3c6aa #a7c080 #e67e80 #dbbc7f' ;;
        "Dracula") printf '%s\n' '#171821 #7b8198 #f8f8f2 #50fa7b #ff5555 #f1fa8c' ;;
        "Bone mono") printf '%s\n' '#101010 #646464 #d0d0d0 #9a9a9a #9e5555 #9e863c' ;;
        "Amber terminal") printf '%s\n' '#12100b #746a55 #e1d4ad #d79921 #cc5c54 #fabd2f' ;;
        "Oxocarbon") printf '%s\n' '#161616 #6f6f6f #f2f4f8 #78a9ff #ff7eb6 #f1c21b' ;;
        "Kanagawa") printf '%s\n' '#1f1f28 #727169 #dcd7ba #7e9cd8 #c34043 #c0a36e' ;;
        "Monokai") printf '%s\n' '#161821 #75715e #f8f8f2 #a6e22e #f92672 #e6db74' ;;
        "Moonlight") printf '%s\n' '#11131f #828bb8 #c8d3f5 #82aaff #ff757f #ffc777' ;;
        "Cyber noir") printf '%s\n' '#080b12 #5f7187 #d7f9ff #00e5ff #ff2f6d #fcee0a' ;;
        "Matcha") printf '%s\n' '#111814 #6f7d72 #d5e8d4 #8fbf7f #d07171 #d8b66d' ;;
        "Orchid") printf '%s\n' '#141018 #74647c #eadcf8 #c792ea #ff6e91 #f7d774' ;;
        "Iceberg") printf '%s\n' '#0f1117 #6b7089 #d4d7e5 #84a0c6 #e27878 #e2a478' ;;
    esac
}

theme_row() {
    local name="$1"
    local colors color row
    colors=$(preset_palette "$name")
    row="<span foreground='${last_hi:-#e8e8e8}'>$name</span>    "
    for color in $colors; do
        row+="<span foreground='$color'>●</span> "
    done
    printf '%s\n' "$row"
}

emit_theme_menu() {
    local map_file="$1"
    local amoled_label="$2"
    local name
    : >"$map_file"
    while IFS= read -r name; do
        theme_row "$name"
        printf '%s\n' "$name" >>"$map_file"
    done < <(theme_names)

    printf '%s\n' "<span foreground='${last_accent:-#b27986}'>$amoled_label</span>    <span foreground='#000000'>●</span> <span foreground='${last_accent:-#b27986}'>●</span> <span foreground='${last_hi:-#e8e8e8}'>●</span>"
    printf '%s\n' "action:amoled" >>"$map_file"

    printf '%s\n' "<span foreground='${last_accent:-#b27986}'>Pick colors from current wallpaper</span>    <span foreground='${last_bg:-#111111}'>●</span> <span foreground='${last_accent:-#b27986}'>●</span> <span foreground='${last_amber:-#a88c5c}'>●</span>"
    printf '%s\n' "action:wallpaper" >>"$map_file"

    printf '%s\n' "<span foreground='${last_accent:-#b27986}'>Pick accent from screen</span>    <span foreground='${last_accent:-#b27986}'>●</span> <span foreground='${last_panel_hi:-#1c1315}'>●</span> <span foreground='${last_hi:-#e8e8e8}'>●</span>"
    printf '%s\n' "action:pick" >>"$map_file"

    printf '%s\n' "<span foreground='${last_fg:-#b8b8b8}'>Restart Waybar</span>"
    printf '%s\n' "action:restart-waybar" >>"$map_file"
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
        map_file=$(mktemp)
        trap 'rm -f "$map_file"' EXIT
        index=$(emit_theme_menu "$map_file" "$amoled_label" | rofi -dmenu -i -markup-rows -format i -theme "$theme" -p "theme")
        [[ -n "$index" && "$index" != "-1" ]] || exit 0
        choice=$(sed -n "$((index + 1))p" "$map_file")
        case "$choice" in
            "action:amoled") toggle_amoled ;;
            "action:wallpaper") from_wallpaper ;;
            "action:pick") pick_accent ;;
            "action:restart-waybar") "$HOME/.config/hypr/scripts/restart-waybar.sh" ;;
            "") exit 0 ;;
            *) apply_preset "$choice" ;;
        esac
        ;;
esac
