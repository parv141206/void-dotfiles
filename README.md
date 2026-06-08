# Parv's Hyprland Rice

A minimal black-first Hyprland setup for Arch Linux with a Sway-inspired layout, tight Waybar, themed Rofi menus, Kitty + Fish, Fastfetch, wallpaper-aware colors, screenshots, recording, and a GTK settings dashboard for people who do not want to edit config files by hand.

![Overview](showcase/overview.png)

![Settings dashboard](showcase/settings_panel_main.png)

![Home](showcase/home.png)

## Highlights

- Hyprland config tuned for a clean laptop workflow.
- Pixel-sharp 1080p scaling with no blurry fractional scaling.
- Minimal top Waybar with workspaces, vitals, Wi-Fi, Bluetooth, audio, brightness, battery, power profile, clock, screenshot, and recording controls.
- GTK settings dashboard for visual control of layout, blur, opacity, animations, gaps, borders, Waybar modules, themes, wallpaper, AMOLED mode, and restore defaults.
- Rofi menus for apps, clipboard, themes, wallpaper selection, Wi-Fi, Bluetooth, audio, brightness, battery, power, and clock.
- Wallpaper picker with grid/list views, previews, refresh action, random wallpaper, and color extraction.
- Theme system with multiple color schemes, AMOLED mode, and wallpaper color picking.
- Kitty as the terminal, Fish as the shell, JetBrains Mono Nerd Font throughout.
- Fastfetch theme kept simple: Arch logo, useful system info, and palette.
- Screen recording via `wf-recorder` with high quality defaults: 60 FPS, x264 CRF 14, slow preset, Opus audio, MKV output.
- Screenshot manager using `grim`, `slurp`, and `satty` or `swappy`.
- Touchpad support with tap-to-click, natural scrolling, gestures, and mouse focus.
- Safe installer that backs up existing configs before copying.

## Waybar Controls

Left side:

- Arch logo: open the settings dashboard.
- Workspaces: current workspace display.

Right side:

- Screenshot button: left click opens screenshot menu, right click selects area and opens editor, middle click opens `~/Pictures/Screenshots`.
- Recording button: left click toggles full-screen recording, right click records a selected area, middle click opens `~/Videos/Recordings`.
- Wi-Fi: opens network menu.
- Bluetooth: opens Bluetooth menu.
- Theme: opens theme menu.
- Vitals: opens settings dashboard; tooltip shows CPU, RAM, disk, temperatures, fan, load, and power profile.
- Uptime: opens power menu.
- Audio: opens audio menu; scroll changes volume capped at 100 percent.
- Brightness: opens brightness menu; scroll adjusts brightness.
- Battery: opens battery menu.
- Clock/date: opens clock menu.
- Power profile/user: opens power menu.

## Keybinds

Main modifier is `Super` or the Windows key.

| Key | Action |
| --- | --- |
| `Super + Enter` | Open Kitty |
| `Super + E` | Open Nautilus |
| `Super + Space` | Open app launcher |
| `Super + V` | Clipboard menu |
| `Super + Shift + W` | Wallpaper selector |
| `Super + C` | Kill active window |
| `Super + W` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + 1..0` | Switch to workspace 1..10 |
| `Super + Shift + 1..0` | Move active window to workspace 1..10 |
| `Ctrl + Super + Left/Right` | Move between workspaces |
| `Super + Left/Right` | Focus window left/right |
| `Super + mouse left` | Move window |
| `Super + mouse right` | Resize window |
| `PrintScreen` / `Fn + PrintScreen` | Screenshot menu |
| `Super + PrintScreen` | Select area and edit screenshot |
| `Super + Shift + C` | Reload Hyprland |
| `Super + Shift + E` | Exit Hyprland |

## Included Configs

The shareable part of this repo is intentionally curated. It is not a dump of all of `~/.config`.

- `hypr/` - Hyprland config, scripts, defaults, autostart.
- `waybar/` - Waybar layout, colors, scripts, styling.
- `rofi/` - App/menu/wallpaper themes.
- `kitty/` - Terminal config and current theme.
- `fish/` - Shell config, prompt, aliases/functions.
- `fastfetch/` - Startup system info.
- `nvim/` - Neovim setup.
- `showcase/` - Screenshots for GitHub.
- Optional visual tooling: GTK, Qt, fontconfig, btop, cava, tmux, mako, swaylock, and related configs if present.

Browser profiles, caches, secrets, recovery folders, and generated junk are ignored.

## Install

Clone the repo somewhere temporary:

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git ~/dotfiles
cd ~/dotfiles
```

Preview what would be installed:

```bash
./install.sh --dry-run
```

Install the configs:

```bash
./install.sh
```

Install common Arch dependencies too:

```bash
./install.sh --packages
```

Run without prompts:

```bash
./install.sh --yes
```

The installer backs up existing files to:

```text
~/.local/share/hypr-rice/backups/YYYYMMDD_HHMMSS
```

## Dependencies

Core:

```text
hyprland hyprpaper hypridle waybar rofi-wayland kitty fish fastfetch nautilus
```

Menus and system controls:

```text
jq xdg-utils brightnessctl playerctl wireplumber pipewire pipewire-pulse
networkmanager bluez bluez-utils power-profiles-daemon wl-clipboard cliphist
```

Screenshots and recording:

```text
grim slurp satty swappy wf-recorder
```

Settings dashboard and fonts:

```text
python-gobject gtk4 ttf-jetbrains-mono-nerd noto-fonts
```

## Recording

Recording files are saved to:

```text
~/Videos/Recordings
```

Defaults are intentionally high quality:

- 60 FPS
- x264
- CRF 14
- slow preset
- Opus audio
- MKV container

You can override recording quality with environment variables:

```bash
RECORD_FPS=30 RECORD_CRF=18 RECORD_PRESET=medium ~/.config/hypr/scripts/recording.sh full
```

## Screenshots

Screenshots are saved to:

```text
~/Pictures/Screenshots
```

The screenshot menu supports:

- Area edit
- Area save
- Area copy
- Active window edit/save/copy
- Full screen edit/save/copy

It uses `satty` first and falls back to `swappy`.

## Restore Defaults

The settings dashboard has a restore action that returns the rice to the captured default state included in:

```text
~/.config/hypr/defaults
```

This is useful when experimenting with transparency, blur, gaps, borders, animations, Waybar modules, and theme colors.

## Notes

- This setup assumes Arch Linux and Hyprland on Wayland.
- The default terminal is Kitty.
- Kitty opens Fish by default.
- App launcher and menus use Rofi.
- File manager is Nautilus.
- The repo deliberately ignores browser profiles and local application state.
