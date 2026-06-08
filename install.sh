#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_config="${XDG_CONFIG_HOME:-$HOME/.config}"
backup_root="$HOME/.local/share/hypr-rice/backups/$(date +%Y%m%d_%H%M%S)"
same_target=0

if [[ "$(realpath "$repo_dir")" == "$(realpath "$target_config")" ]]; then
    same_target=1
fi

assume_yes=0
dry_run=0
install_packages=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -y, --yes          Run without confirmation prompts.
  -n, --dry-run      Show what would happen without changing files.
  --packages         Install common Arch package dependencies with pacman.
  -h, --help         Show this help.

This installer backs up existing config paths before copying the dotfiles.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes) assume_yes=1 ;;
        -n|--dry-run) dry_run=1 ;;
        --packages) install_packages=1 ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

dotfile_items=(
    hypr
    waybar
    rofi
    kitty
    fish
    fastfetch
    nvim
    mako
    swaylock
    xdg-desktop-portal
    fontconfig
    gtk-3.0
    gtk-4.0
    qt5ct
    qt6ct
    Kvantum
    kvantum
    color-schemes
    foot
    fuzzel
    ghostty
    git
    btop
    cava
    tmux
    showcase
    mimeapps.list
    user-dirs.dirs
    user-dirs.locale
    gtkrc
    gtkrc-2.0
)

arch_packages=(
    hyprland
    hyprpaper
    hypridle
    waybar
    rofi-wayland
    kitty
    fish
    fastfetch
    nautilus
    xdg-utils
    jq
    brightnessctl
    playerctl
    wireplumber
    pipewire
    pipewire-pulse
    networkmanager
    bluez
    bluez-utils
    wl-clipboard
    cliphist
    grim
    slurp
    satty
    swappy
    wf-recorder
    power-profiles-daemon
    python-gobject
    gtk4
    qt5ct
    qt6ct
    kvantum
    ttf-jetbrains-mono-nerd
    noto-fonts
    xdg-desktop-portal-gtk
)

needed_commands=(
    Hyprland
    waybar
    rofi
    kitty
    fish
    fastfetch
    nautilus
    jq
    grim
    slurp
    satty
    swappy
    wf-recorder
    wl-copy
    cliphist
    brightnessctl
    wpctl
    playerctl
    powerprofilesctl
)

confirm() {
    local prompt="$1"

    if [[ "$assume_yes" == "1" ]]; then
        return 0
    fi

    read -r -p "$prompt [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

run() {
    if [[ "$dry_run" == "1" ]]; then
        printf 'dry-run:'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

copy_item() {
    local item="$1"
    local src="$repo_dir/$item"
    local dest="$target_config/$item"
    local backup="$backup_root/$item"

    [[ -e "$src" ]] || return 0

    if [[ -e "$dest" || -L "$dest" ]]; then
        run mkdir -p "$(dirname "$backup")"
        run mv "$dest" "$backup"
        echo "Backed up $dest -> $backup"
    fi

    run mkdir -p "$(dirname "$dest")"
    if [[ -d "$src" ]]; then
        run mkdir -p "$dest"
        if [[ "$dry_run" == "1" ]]; then
            echo "dry-run: copy $src -> $dest"
        else
            (
                cd "$repo_dir"
                tar --exclude='.git' --exclude='*.bak' --exclude='__pycache__' -cf - "$item"
            ) | (
                cd "$target_config"
                tar -xf -
            )
        fi
    else
        run cp -a "$src" "$dest"
    fi

    echo "Installed $item"
}

check_missing_commands() {
    local missing=()

    for cmd in "${needed_commands[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done

    if [[ "${#missing[@]}" -gt 0 ]]; then
        echo
        echo "Missing commands:"
        printf '  %s\n' "${missing[@]}"
        echo
        echo "On Arch, run: ./install.sh --packages"
    fi
}

install_arch_packages() {
    command -v pacman >/dev/null 2>&1 || {
        echo "pacman not found; skipping package installation." >&2
        return 1
    }

    run sudo pacman -S --needed "${arch_packages[@]}"
}

echo "Hypr rice installer"
echo "Repository: $repo_dir"
echo "Target:     $target_config"
echo "Backup:     $backup_root"
echo

if [[ "$install_packages" == "1" ]]; then
    if confirm "Install common Arch dependencies with pacman?"; then
        install_arch_packages
    fi
fi

if [[ "$same_target" == "1" ]]; then
    echo "Repository is already the target config directory; skipping copy step."
else
    if ! confirm "Install dotfiles into $target_config? Existing paths will be backed up."; then
        echo "Cancelled."
        exit 0
    fi

    run mkdir -p "$target_config"

    for item in "${dotfile_items[@]}"; do
        copy_item "$item"
    done
fi

if [[ "$dry_run" != "1" ]]; then
    chmod +x "$target_config"/hypr/scripts/*.sh 2>/dev/null || true
fi

check_missing_commands

echo
echo "Done."
echo "Log out and start a Hyprland session, or reload with: hyprctl reload"
echo "Restart Waybar with: ~/.config/hypr/scripts/restart-waybar.sh"
