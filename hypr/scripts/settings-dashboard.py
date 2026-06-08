#!/usr/bin/env python3

import json
import re
import shutil
import subprocess
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, Gtk


HOME = Path.home()
CONFIG = HOME / ".config"
HYPR_CONF = CONFIG / "hypr/hyprland.conf"
DEFAULTS = CONFIG / "hypr/defaults"
WAYBAR_CONF = CONFIG / "waybar/config.jsonc"
WAYBAR_STYLE = CONFIG / "waybar/style.css"
WAYBAR_COLORS = CONFIG / "waybar/colors.css"
ROFI_MINIMAL = CONFIG / "rofi/minimal.rasi"
ROFI_WALLPAPER = CONFIG / "rofi/wallpaper.rasi"
ROFI_WALLPAPER_LIST = CONFIG / "rofi/wallpaper-list.rasi"
KITTY_THEME = CONFIG / "kitty/current-theme.conf"
FASTFETCH_CONF = CONFIG / "fastfetch/config.jsonc"
GTK3_CSS = CONFIG / "gtk-3.0/gtk.css"
GTK3_SETTINGS = CONFIG / "gtk-3.0/settings.ini"
GTK4_CSS = CONFIG / "gtk-4.0/gtk.css"
GTK4_SETTINGS = CONFIG / "gtk-4.0/settings.ini"
QT5_COLORS = CONFIG / "qt5ct/colors/matugen.conf"
QT5_QSS = CONFIG / "qt5ct/qss/matugen-style.qss"
QT6_COLORS = CONFIG / "qt6ct/colors/matugen.conf"
QT6_QSS = CONFIG / "qt6ct/qss/matugen-style.qss"


def run(*args):
    return subprocess.run(args, text=True, capture_output=True)


def launch(*args):
    subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def hypr_get(option):
    return run("hyprctl", "getoption", option).stdout


def hypr_keyword(key, value):
    return run("hyprctl", "keyword", key, str(value))


def hypr_dispatch(dispatcher, *args):
    return run("hyprctl", "dispatch", dispatcher, *map(str, args))


def option_int(option, default=0):
    match = re.search(r"int:\s+(-?\d+)", hypr_get(option))
    return int(match.group(1)) if match else default


def option_float(option, default=0.0):
    match = re.search(r"float:\s+([0-9.]+)", hypr_get(option))
    return float(match.group(1)) if match else default


def option_custom_numbers(option, default=(0,)):
    match = re.search(r"custom type:\s+([0-9 -]+)", hypr_get(option))
    if not match:
        return default
    values = tuple(int(v) for v in match.group(1).split() if v.lstrip("-").isdigit())
    return values or default


def bool_text(enabled):
    return "true" if enabled else "false"


def read_text(path):
    return path.read_text() if path.exists() else ""


def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def patch_line(key, value, path=HYPR_CONF):
    text = read_text(path)
    pattern = rf"(^\s*{re.escape(key)}\s*=\s*)[^\n]+"
    replacement = lambda match: f"{match.group(1)}{value}"
    new_text, count = re.subn(pattern, replacement, text, flags=re.M)
    if count == 0:
        new_text = text.rstrip() + f"\n{key} = {value}\n"
    write_text(path, new_text)


def patch_block_line(block, key, value):
    text = read_text(HYPR_CONF)
    block_pattern = rf"(^\s*{re.escape(block)}\s*\{{.*?^\s*\}})"
    block_match = re.search(block_pattern, text, flags=re.S | re.M)
    if not block_match:
        write_text(HYPR_CONF, text.rstrip() + f"\n\n{block} {{\n    {key} = {value}\n}}\n")
        return

    block_text = block_match.group(1)
    key_pattern = rf"(^\s*{re.escape(key)}\s*=\s*)[^\n]+"
    replacement = lambda match: f"{match.group(1)}{value}"
    new_block, count = re.subn(key_pattern, replacement, block_text, flags=re.M)
    if count == 0:
        new_block = re.sub(r"(^\s*\}\s*$)", f"    {key} = {value}\n\\1", block_text, flags=re.M)
    write_text(HYPR_CONF, text[: block_match.start(1)] + new_block + text[block_match.end(1) :])


def restart_waybar():
    run(str(CONFIG / "hypr/scripts/restart-waybar.sh"))


def load_waybar():
    return json.loads(read_text(WAYBAR_CONF))


def save_waybar(data):
    write_text(WAYBAR_CONF, json.dumps(data, indent=4) + "\n")
    restart_waybar()


def verify_hypr_config():
    return run("Hyprland", "--verify-config", "--config", str(HYPR_CONF)).returncode == 0


def hypr_monitors():
    result = run("hyprctl", "monitors", "-j")
    if result.returncode != 0:
        return []
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return []


def focused_monitor():
    monitors = hypr_monitors()
    for monitor in monitors:
        if monitor.get("focused"):
            return monitor
    return monitors[0] if monitors else {}


def mode_for_monitor(monitor):
    width = int(monitor.get("width", 1920) or 1920)
    height = int(monitor.get("height", 1080) or 1080)
    refresh = float(monitor.get("refreshRate", 60) or 60)
    return f"{width}x{height}@{refresh:.2f}"


def position_for_monitor(monitor):
    return f"{int(monitor.get('x', 0) or 0)}x{int(monitor.get('y', 0) or 0)}"


def patch_monitor_rule(name, mode, position, scale):
    text = read_text(HYPR_CONF)
    value = f"{name}, {mode}, {position}, {scale:g}"
    patterns = [rf"^\s*monitor\s*=\s*{re.escape(name)}\s*,[^\n]+", r"^\s*monitor\s*=\s*,[^\n]+"]
    for pattern in patterns:
        new_text, count = re.subn(pattern, f"monitor = {value}", text, count=1, flags=re.M)
        if count:
            write_text(HYPR_CONF, new_text)
            return
    write_text(HYPR_CONF, text.rstrip() + f"\nmonitor = {value}\n")


def patch_monitor_extra_rule(name, key, value):
    text = read_text(HYPR_CONF)
    line = f"monitor = {name}, {key}, {value}"
    pattern = rf"^\s*monitor\s*=\s*{re.escape(name)}\s*,\s*{re.escape(key)}\s*,[^\n]+"
    new_text, count = re.subn(pattern, line, text, count=1, flags=re.M)
    if count:
        write_text(HYPR_CONF, new_text)
    else:
        write_text(HYPR_CONF, text.rstrip() + f"\n{line}\n")


class Dashboard(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="dev.parv.hyprsettings")
        self.window = None
        self.stack = None
        self.status_label = None

    def do_activate(self):
        if self.window:
            self.window.present()
            return

        self.apply_css()
        self.window = Gtk.ApplicationWindow(application=self)
        self.window.set_title("Hypr Settings")
        self.window.set_default_size(980, 650)
        self.window.set_resizable(True)

        root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        root.add_css_class("root")
        self.window.set_child(root)

        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        sidebar.add_css_class("sidebar")
        root.append(sidebar)

        title = Gtk.Label(label="settings")
        title.add_css_class("app-title")
        title.set_xalign(0)
        sidebar.append(title)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(140)
        self.stack.set_hexpand(True)
        self.stack.set_vexpand(True)
        root.append(self.stack)

        pages = [
            ("overview", "Overview", self.overview_page()),
            ("effects", "Effects", self.effects_page()),
            ("layout", "Layout", self.layout_page()),
            ("input", "Input", self.input_page()),
            ("display", "Display", self.display_page()),
            ("waybar", "Waybar", self.waybar_page()),
            ("appearance", "Appearance", self.appearance_page()),
            ("tools", "Tools", self.tools_page()),
            ("restore", "Restore", self.restore_page()),
            ("system", "System", self.system_page()),
        ]

        for name, label, page in pages:
            self.stack.add_named(page, name)
            button = Gtk.Button(label=label)
            button.add_css_class("nav-button")
            button.set_halign(Gtk.Align.FILL)
            button.connect("clicked", lambda _btn, n=name: self.stack.set_visible_child_name(n))
            sidebar.append(button)

        self.window.present()
        self.refresh_status()

    def apply_css(self):
        css = """
        * {
            font-family: "JetBrainsMono Nerd Font", monospace;
            font-size: 12px;
        }
        window, .root { background: #000000; color: #e8e8e8; }
        .sidebar {
            min-width: 176px;
            padding: 16px 10px;
            border-right: 1px solid #191919;
            background: #050505;
        }
        .app-title {
            color: #b27986;
            font-weight: 700;
            margin: 0 0 14px 8px;
        }
        .nav-button {
            padding: 9px 10px;
            border-radius: 0;
            border: 0;
            background: transparent;
            color: #b8b8b8;
        }
        .nav-button:hover { background: #1c1315; color: #e8e8e8; }
        .page { padding: 18px 22px; }
        .heading {
            font-size: 18px;
            font-weight: 700;
            color: #e8e8e8;
            margin-bottom: 4px;
        }
        .subtle { color: #8f8f8f; margin-bottom: 16px; }
        .section { margin: 0 0 18px 0; }
        .section-title { color: #b27986; font-weight: 700; margin-bottom: 8px; }
        .row { padding: 7px 0; }
        .small-label { color: #8f8f8f; }
        button, switch, scale, spinbutton, dropdown { border-radius: 0; }
        button {
            background: #101010;
            color: #e8e8e8;
            border: 1px solid #191919;
            padding: 8px 10px;
        }
        button:hover { background: #1c1315; border-color: #b27986; }
        scale trough { min-height: 4px; background: #191919; }
        scale highlight, switch:checked { background: #b27986; }
        spinbutton { min-width: 86px; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def page_shell(self, heading, subtitle):
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        page.add_css_class("page")
        scrolled.set_child(page)
        head = Gtk.Label(label=heading)
        head.add_css_class("heading")
        head.set_xalign(0)
        sub = Gtk.Label(label=subtitle)
        sub.add_css_class("subtle")
        sub.set_xalign(0)
        page.append(head)
        page.append(sub)
        return scrolled, page

    def section(self, parent, title):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.add_css_class("section")
        label = Gtk.Label(label=title)
        label.add_css_class("section-title")
        label.set_xalign(0)
        box.append(label)
        parent.append(box)
        return box

    def row(self, parent, label, control):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        box.add_css_class("row")
        text = Gtk.Label(label=label)
        text.set_xalign(0)
        text.set_hexpand(True)
        box.append(text)
        box.append(control)
        parent.append(box)

    def button_row(self, parent, buttons):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        box.add_css_class("row")
        for label, callback in buttons:
            button = Gtk.Button(label=label)
            button.connect("clicked", lambda _btn, cb=callback: cb())
            box.append(button)
        parent.append(box)

    def switch_row(self, parent, label, active, callback):
        switch = Gtk.Switch()
        switch.set_active(bool(active))
        switch.connect("notify::active", lambda sw, _pspec: callback(sw.get_active()))
        self.row(parent, label, switch)
        return switch

    def spin_row(self, parent, label, value, minimum, maximum, step, callback):
        spin = Gtk.SpinButton.new_with_range(minimum, maximum, step)
        spin.set_value(value)
        spin.connect("value-changed", lambda widget: callback(int(widget.get_value())))
        self.row(parent, label, spin)
        return spin

    def scale_row(self, parent, label, value, minimum, maximum, step, digits, callback):
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, minimum, maximum, step)
        scale.set_value(value)
        scale.set_digits(digits)
        scale.set_hexpand(True)
        scale.connect("value-changed", lambda widget: callback(widget.get_value()))
        self.row(parent, label, scale)
        return scale

    def overview_page(self):
        scrolled, page = self.page_shell("Overview", "Current state and quick presets.")
        self.status_label = Gtk.Label()
        self.status_label.set_xalign(0)
        self.status_label.set_selectable(True)
        page.append(self.status_label)
        quick = self.section(page, "Quick presets")
        self.button_row(quick, [
            ("Current default", self.restore_defaults),
            ("Dense", lambda: self.layout_preset(gaps=0, border=1, rounding=0)),
            ("Soft gaps", lambda: self.layout_preset(gaps=6, border=1, rounding=4)),
            ("Glass", lambda: self.effects_preset(0.92, 0.84, True, 5, 2)),
            ("Opaque", lambda: self.effects_preset(1.0, 1.0, False, 3, 3)),
        ])
        refresh = Gtk.Button(label="Refresh status")
        refresh.connect("clicked", lambda _btn: self.refresh_status())
        page.append(refresh)
        return scrolled

    def effects_page(self):
        scrolled, page = self.page_shell("Effects", "Transparency, blur, shadows, rounding, and motion.")
        opacity = self.section(page, "Window opacity")
        self.scale_row(opacity, "Active opacity", option_float("decoration:active_opacity", 1.0), 0.70, 1.00, 0.01, 2, self.set_active_opacity)
        self.scale_row(opacity, "Inactive opacity", option_float("decoration:inactive_opacity", 1.0), 0.60, 1.00, 0.01, 2, self.set_inactive_opacity)
        self.button_row(opacity, [
            ("Opaque", lambda: self.effects_preset(1.0, 1.0, False, 3, 3)),
            ("Subtle", lambda: self.effects_preset(0.97, 0.92, False, 3, 3)),
            ("Glass", lambda: self.effects_preset(0.92, 0.84, True, 5, 2)),
            ("Deep", lambda: self.effects_preset(0.86, 0.76, True, 7, 3)),
        ])

        blur = self.section(page, "Blur")
        self.switch_row(blur, "Enable blur", option_int("decoration:blur:enabled", 0) == 1, self.set_blur_enabled)
        self.scale_row(blur, "Blur size", option_int("decoration:blur:size", 3), 1, 10, 1, 0, lambda value: self.set_blur_value("size", int(value)))
        self.scale_row(blur, "Blur passes", option_int("decoration:blur:passes", 3), 1, 4, 1, 0, lambda value: self.set_blur_value("passes", int(value)))

        decoration = self.section(page, "Decoration")
        self.scale_row(decoration, "Corner rounding", option_int("decoration:rounding", 0), 0, 16, 1, 0, lambda value: self.set_block_int("decoration", "rounding", "decoration:rounding", int(value)))
        self.switch_row(decoration, "Shadow", option_int("decoration:shadow:enabled", 0) == 1, self.set_shadow_enabled)

        motion = self.section(page, "Motion")
        self.switch_row(motion, "Animations", option_int("animations:enabled", 1) == 1, self.set_animations)
        self.button_row(motion, [
            ("Minimal motion", lambda: self.set_animation_speed(2)),
            ("Normal motion", lambda: self.set_animation_speed(3)),
            ("Slow motion", lambda: self.set_animation_speed(5)),
        ])
        return scrolled

    def layout_page(self):
        scrolled, page = self.page_shell("Layout", "Tiling behavior, spacing, borders, and window dispatchers.")
        general = self.section(page, "General")
        gaps_in = option_custom_numbers("general:gaps_in", (0,))[0]
        gaps_out = option_custom_numbers("general:gaps_out", (0,))[0]
        self.spin_row(general, "Inner gaps", gaps_in, 0, 32, 1, self.set_gaps_in)
        self.spin_row(general, "Outer gaps", gaps_out, 0, 32, 1, self.set_gaps_out)
        self.spin_row(general, "Border size", option_int("general:border_size", 1), 0, 8, 1, self.set_border)
        self.switch_row(general, "Resize on border", option_int("general:resize_on_border", 1) == 1, lambda enabled: self.set_block_bool("general", "resize_on_border", "general:resize_on_border", enabled))
        self.switch_row(general, "Allow tearing", option_int("general:allow_tearing", 0) == 1, lambda enabled: self.set_block_bool("general", "allow_tearing", "general:allow_tearing", enabled))

        dwindle = self.section(page, "Dwindle")
        self.switch_row(dwindle, "Preserve split", option_int("dwindle:preserve_split", 1) == 1, lambda enabled: self.set_block_bool("dwindle", "preserve_split", "dwindle:preserve_split", enabled))
        self.button_row(dwindle, [
            ("Toggle split", lambda: hypr_dispatch("togglesplit")),
            ("Pseudo active", lambda: hypr_dispatch("pseudo")),
            ("Toggle floating", lambda: hypr_dispatch("togglefloating")),
            ("Fullscreen", lambda: hypr_dispatch("fullscreen")),
        ])
        return scrolled

    def input_page(self):
        scrolled, page = self.page_shell("Input", "Mouse focus, touchpad behavior, and cursor behavior.")
        mouse = self.section(page, "Mouse")
        self.spin_row(mouse, "Hover focus mode", option_int("input:follow_mouse", 1), 0, 3, 1, lambda value: self.set_block_int("input", "follow_mouse", "input:follow_mouse", value))
        self.switch_row(mouse, "Cursor no warps", option_int("cursor:no_warps", 1) == 1, lambda enabled: self.set_block_bool("cursor", "no_warps", "cursor:no_warps", enabled))

        touchpad = self.section(page, "Touchpad")
        self.switch_row(touchpad, "Tap to click", option_int("input:touchpad:tap-to-click", 1) == 1, lambda enabled: self.set_touchpad_bool("tap-to-click", enabled))
        self.switch_row(touchpad, "Natural scroll", option_int("input:touchpad:natural_scroll", 1) == 1, lambda enabled: self.set_touchpad_bool("natural_scroll", enabled))
        self.switch_row(touchpad, "Disable while typing", option_int("input:touchpad:disable_while_typing", 1) == 1, lambda enabled: self.set_touchpad_bool("disable_while_typing", enabled))
        self.switch_row(touchpad, "Middle button emulation", option_int("input:touchpad:middle_button_emulation", 1) == 1, lambda enabled: self.set_touchpad_bool("middle_button_emulation", enabled))
        return scrolled

    def display_page(self):
        scrolled, page = self.page_shell("Display", "Monitor resolution, scale, position, transform, and refresh behavior.")
        monitor = focused_monitor()
        name = monitor.get("name", "")
        scale = float(monitor.get("scale", 1.0) or 1.0)
        x = int(monitor.get("x", 0) or 0)
        y = int(monitor.get("y", 0) or 0)

        info = self.section(page, "Focused monitor")
        label = Gtk.Label(label=self.display_summary(monitor))
        label.set_xalign(0)
        label.set_selectable(True)
        info.append(label)

        if not name:
            return scrolled

        mode = self.section(page, "Mode")
        self.button_row(mode, [
            ("Native", lambda n=name: self.set_monitor_native(n)),
            ("Preferred auto", lambda n=name: self.set_monitor_preferred(n)),
            ("Reload monitors", lambda: run("hyprctl", "reload")),
        ])

        geometry = self.section(page, "Geometry")
        self.scale_row(geometry, "Scale", scale, 0.75, 2.00, 0.05, 2, lambda value, n=name: self.set_monitor_scale(n, value))
        self.spin_row(geometry, "Position X", x, -7680, 7680, 10, lambda value, n=name: self.set_monitor_position(n, x=value))
        self.spin_row(geometry, "Position Y", y, -4320, 4320, 10, lambda value, n=name: self.set_monitor_position(n, y=value))

        advanced = self.section(page, "Advanced")
        self.spin_row(advanced, "Transform", int(monitor.get("transform", 0) or 0), 0, 7, 1, lambda value, n=name: self.set_monitor_extra(n, "transform", value))
        self.switch_row(advanced, "Variable refresh rate", bool(monitor.get("vrr", False)), lambda enabled, n=name: self.set_monitor_extra(n, "vrr", 1 if enabled else 0))
        self.button_row(advanced, [
            ("Reset transform", lambda n=name: self.set_monitor_extra(n, "transform", 0)),
            ("Set 1x scale", lambda n=name: self.set_monitor_scale(n, 1.0)),
            ("Set native + 1x", lambda n=name: (self.set_monitor_native(n), self.set_monitor_scale(n, 1.0))),
        ])
        return scrolled

    def waybar_page(self):
        scrolled, page = self.page_shell("Waybar", "Size, layout, and visible modules.")
        size = self.section(page, "Size")
        data = load_waybar()
        self.spin_row(size, "Height", int(data.get("height", 30)), 22, 48, 1, self.set_waybar_height)
        font_match = re.search(r"font-size:\s*(\d+)px", read_text(WAYBAR_STYLE))
        self.spin_row(size, "Font size", int(font_match.group(1)) if font_match else 12, 9, 16, 1, self.set_waybar_font)
        self.button_row(size, [
            ("Compact", lambda: self.set_bar_size("compact")),
            ("Normal", lambda: self.set_bar_size("normal")),
            ("Large", lambda: self.set_bar_size("large")),
            ("Restart", restart_waybar),
        ])

        modules = self.section(page, "Right-side modules")
        for module, label in [
            ("network", "Network"),
            ("custom/bluetooth", "Bluetooth"),
            ("custom/theme", "Theme"),
            ("custom/vitals", "Vitals"),
            ("custom/uptime", "Uptime"),
            ("wireplumber", "Volume"),
            ("backlight", "Brightness"),
            ("battery", "Battery"),
            ("clock#date", "Date"),
            ("clock#time", "Time"),
            ("custom/power-profile", "Power profile"),
            ("custom/user", "User"),
        ]:
            self.switch_row(modules, label, module in data.get("modules-right", []), lambda enabled, m=module: self.set_waybar_module(m, enabled))
        return scrolled

    def appearance_page(self):
        scrolled, page = self.page_shell("Appearance", "Theme, wallpaper, AMOLED, and external pickers.")
        section = self.section(page, "Theme")
        self.button_row(section, [
            ("Theme menu", lambda: launch(str(CONFIG / "hypr/scripts/theme-menu.sh"))),
            ("AMOLED", lambda: launch(str(CONFIG / "hypr/scripts/theme-menu.sh"), "amoled")),
            ("Accent picker", lambda: launch(str(CONFIG / "hypr/scripts/theme-menu.sh"), "pick")),
        ])
        self.button_row(section, [
            ("Wallpaper picker", lambda: launch(str(CONFIG / "hypr/scripts/wallpaper-menu.sh"))),
            ("Colors from wallpaper", lambda: launch(str(CONFIG / "hypr/scripts/theme-menu.sh"), "wallpaper")),
        ])
        return scrolled

    def tools_page(self):
        scrolled, page = self.page_shell("Tools", "Open the quick panels.")
        section = self.section(page, "Panels")
        self.button_row(section, [
            ("Launcher", lambda: launch(str(CONFIG / "hypr/scripts/app-launcher.sh"))),
            ("Clipboard", lambda: launch(str(CONFIG / "hypr/scripts/clipboard-menu.sh"))),
            ("Network", lambda: launch(str(CONFIG / "hypr/scripts/network-menu.sh"))),
            ("Bluetooth", lambda: launch(str(CONFIG / "hypr/scripts/bluetooth-menu.sh"))),
        ])
        self.button_row(section, [
            ("Audio", lambda: launch(str(CONFIG / "hypr/scripts/audio-menu.sh"))),
            ("Brightness", lambda: launch(str(CONFIG / "hypr/scripts/brightness-menu.sh"))),
            ("Power", lambda: launch(str(CONFIG / "hypr/scripts/power-menu.sh"))),
            ("Screenshot", lambda: launch(str(CONFIG / "hypr/scripts/screenshot.sh"), "menu")),
        ])
        return scrolled

    def restore_page(self):
        scrolled, page = self.page_shell("Restore", "Return to the captured default rice.")
        section = self.section(page, "Defaults")
        note = Gtk.Label(label=f"Default snapshot: {DEFAULTS}")
        note.add_css_class("small-label")
        note.set_xalign(0)
        section.append(note)
        self.button_row(section, [
            ("Restore current rice default", self.restore_defaults),
            ("Capture current as new default", self.capture_defaults),
        ])
        return scrolled

    def system_page(self):
        scrolled, page = self.page_shell("System", "Session controls and validation.")
        section = self.section(page, "Commands")
        self.button_row(section, [
            ("Verify config", self.verify_and_report),
            ("Reload Hyprland", lambda: run("hyprctl", "reload")),
            ("Restart Waybar", restart_waybar),
            ("Lock", lambda: launch(str(CONFIG / "hypr/scripts/lock.sh"))),
            ("Power menu", lambda: launch(str(CONFIG / "hypr/scripts/power-menu.sh"))),
        ])
        return scrolled

    def display_summary(self, monitor):
        if not monitor:
            return "No active monitor found."
        return "\n".join([
            f"name        {monitor.get('name', 'unknown')}",
            f"resolution  {monitor.get('width', '?')}x{monitor.get('height', '?')} @ {float(monitor.get('refreshRate', 0) or 0):.2f} Hz",
            f"position    {monitor.get('x', 0)}x{monitor.get('y', 0)}",
            f"scale       {float(monitor.get('scale', 1) or 1):.2f}",
            f"transform   {monitor.get('transform', 0)}",
            f"focused     {'yes' if monitor.get('focused') else 'no'}",
        ])

    def monitor_by_name(self, name):
        for monitor in hypr_monitors():
            if monitor.get("name") == name:
                return monitor
        return focused_monitor()

    def apply_monitor_rule(self, name, mode=None, position=None, scale=None):
        monitor = self.monitor_by_name(name)
        mode = mode or mode_for_monitor(monitor)
        position = position or position_for_monitor(monitor)
        scale = float(scale if scale is not None else monitor.get("scale", 1.0) or 1.0)
        value = f"{name}, {mode}, {position}, {scale:g}"
        hypr_keyword("monitor", value)
        patch_monitor_rule(name, mode, position, scale)
        self.refresh_status()

    def set_monitor_native(self, name):
        monitor = self.monitor_by_name(name)
        self.apply_monitor_rule(name, mode_for_monitor(monitor), position_for_monitor(monitor), float(monitor.get("scale", 1.0) or 1.0))

    def set_monitor_preferred(self, name):
        self.apply_monitor_rule(name, "preferred", "auto", 1.0)

    def set_monitor_scale(self, name, scale):
        monitor = self.monitor_by_name(name)
        self.apply_monitor_rule(name, mode_for_monitor(monitor), position_for_monitor(monitor), float(scale))

    def set_monitor_position(self, name, x=None, y=None):
        monitor = self.monitor_by_name(name)
        xpos = int(x if x is not None else monitor.get("x", 0) or 0)
        ypos = int(y if y is not None else monitor.get("y", 0) or 0)
        self.apply_monitor_rule(name, mode_for_monitor(monitor), f"{xpos}x{ypos}", float(monitor.get("scale", 1.0) or 1.0))

    def set_monitor_extra(self, name, key, value):
        hypr_keyword("monitor", f"{name}, {key}, {value}")
        patch_monitor_extra_rule(name, key, value)
        self.refresh_status()

    def set_active_opacity(self, value):
        value = f"{value:.2f}"
        hypr_keyword("decoration:active_opacity", value)
        patch_block_line("decoration", "active_opacity", value)
        self.refresh_status()

    def set_inactive_opacity(self, value):
        value = f"{value:.2f}"
        hypr_keyword("decoration:inactive_opacity", value)
        patch_block_line("decoration", "inactive_opacity", value)
        self.refresh_status()

    def set_blur_enabled(self, enabled):
        value = bool_text(enabled)
        hypr_keyword("decoration:blur:enabled", value)
        patch_block_line("blur", "enabled", value)
        self.refresh_status()

    def set_blur_value(self, key, value):
        hypr_keyword(f"decoration:blur:{key}", value)
        patch_block_line("blur", key, value)
        self.refresh_status()

    def set_shadow_enabled(self, enabled):
        value = bool_text(enabled)
        hypr_keyword("decoration:shadow:enabled", value)
        patch_block_line("shadow", "enabled", value)
        self.refresh_status()

    def set_animations(self, enabled):
        value = bool_text(enabled)
        hypr_keyword("animations:enabled", value)
        patch_block_line("animations", "enabled", value)
        self.refresh_status()

    def set_animation_speed(self, speed):
        text = read_text(HYPR_CONF)
        text = re.sub(r"(animation = windows,\s*1,\s*)\d+", rf"\g<1>{speed}", text)
        text = re.sub(r"(animation = windowsOut,\s*1,\s*)\d+", rf"\g<1>{speed}", text)
        text = re.sub(r"(animation = fade,\s*1,\s*)\d+", rf"\g<1>{speed}", text)
        text = re.sub(r"(animation = layers,\s*1,\s*)\d+", rf"\g<1>{speed}", text)
        text = re.sub(r"(animation = workspaces,\s*1,\s*)\d+", rf"\g<1>{speed}", text)
        write_text(HYPR_CONF, text)
        run("hyprctl", "reload")
        self.refresh_status()

    def set_block_bool(self, block, key, keyword, enabled):
        value = bool_text(enabled)
        hypr_keyword(keyword, value)
        patch_block_line(block, key, value)
        self.refresh_status()

    def set_block_int(self, block, key, keyword, value):
        hypr_keyword(keyword, int(value))
        patch_block_line(block, key, int(value))
        self.refresh_status()

    def set_touchpad_bool(self, key, enabled):
        value = bool_text(enabled)
        hypr_keyword(f"input:touchpad:{key}", value)
        patch_block_line("touchpad", key, value)
        self.refresh_status()

    def set_gaps_in(self, value):
        hypr_keyword("general:gaps_in", value)
        patch_block_line("general", "gaps_in", int(value))
        self.refresh_status()

    def set_gaps_out(self, value):
        hypr_keyword("general:gaps_out", value)
        patch_block_line("general", "gaps_out", int(value))
        self.refresh_status()

    def set_gaps(self, value):
        self.set_gaps_in(value)
        self.set_gaps_out(value)

    def set_border(self, value):
        hypr_keyword("general:border_size", value)
        patch_block_line("general", "border_size", int(value))
        self.refresh_status()

    def layout_preset(self, gaps, border, rounding):
        self.set_gaps(gaps)
        self.set_border(border)
        self.set_block_int("decoration", "rounding", "decoration:rounding", rounding)

    def effects_preset(self, active, inactive, blur_enabled, blur_size, blur_passes):
        self.set_active_opacity(active)
        self.set_inactive_opacity(inactive)
        self.set_blur_enabled(blur_enabled)
        self.set_blur_value("size", blur_size)
        self.set_blur_value("passes", blur_passes)

    def set_waybar_height(self, height):
        data = load_waybar()
        data["height"] = int(height)
        save_waybar(data)

    def set_waybar_font(self, size):
        style = re.sub(r"font-size:\s*\d+px;", f"font-size: {int(size)}px;", read_text(WAYBAR_STYLE))
        write_text(WAYBAR_STYLE, style)
        restart_waybar()

    def set_bar_size(self, size):
        presets = {
            "compact": (26, 11, "4px 10px"),
            "normal": (30, 12, "5px 13px"),
            "large": (36, 13, "7px 15px"),
        }
        height, font, padding = presets[size]
        data = load_waybar()
        data["height"] = height
        save_waybar(data)
        style = read_text(WAYBAR_STYLE)
        style = re.sub(r"font-size:\s*\d+px;", f"font-size: {font}px;", style)
        style = re.sub(r"padding:\s*\d+px\s+\d+px;", f"padding: {padding};", style)
        write_text(WAYBAR_STYLE, style)
        restart_waybar()

    def set_waybar_module(self, module, enabled):
        data = load_waybar()
        modules = data.setdefault("modules-right", [])
        if enabled and module not in modules:
            modules.append(module)
        if not enabled and module in modules:
            modules.remove(module)
        save_waybar(data)

    def capture_defaults(self):
        DEFAULTS.mkdir(parents=True, exist_ok=True)
        for source, name in [
            (HYPR_CONF, "hyprland.conf"),
            (WAYBAR_CONF, "waybar-config.jsonc"),
            (WAYBAR_STYLE, "waybar-style.css"),
            (WAYBAR_COLORS, "waybar-colors.css"),
            (ROFI_MINIMAL, "rofi-minimal.rasi"),
            (ROFI_WALLPAPER, "rofi-wallpaper.rasi"),
            (ROFI_WALLPAPER_LIST, "rofi-wallpaper-list.rasi"),
            (KITTY_THEME, "kitty-current-theme.conf"),
            (FASTFETCH_CONF, "fastfetch-config.jsonc"),
            (GTK3_CSS, "gtk3.css"),
            (GTK3_SETTINGS, "gtk3-settings.ini"),
            (GTK4_CSS, "gtk4.css"),
            (GTK4_SETTINGS, "gtk4-settings.ini"),
            (QT5_COLORS, "qt5ct-matugen.conf"),
            (QT5_QSS, "qt5ct-matugen.qss"),
            (QT6_COLORS, "qt6ct-matugen.conf"),
            (QT6_QSS, "qt6ct-matugen.qss"),
        ]:
            if source.exists():
                shutil.copy2(source, DEFAULTS / name)
        self.refresh_status()

    def restore_defaults(self):
        mapping = [
            ("hyprland.conf", HYPR_CONF),
            ("waybar-config.jsonc", WAYBAR_CONF),
            ("waybar-style.css", WAYBAR_STYLE),
            ("waybar-colors.css", WAYBAR_COLORS),
            ("rofi-minimal.rasi", ROFI_MINIMAL),
            ("rofi-wallpaper.rasi", ROFI_WALLPAPER),
            ("rofi-wallpaper-list.rasi", ROFI_WALLPAPER_LIST),
            ("kitty-current-theme.conf", KITTY_THEME),
            ("fastfetch-config.jsonc", FASTFETCH_CONF),
            ("gtk3.css", GTK3_CSS),
            ("gtk3-settings.ini", GTK3_SETTINGS),
            ("gtk4.css", GTK4_CSS),
            ("gtk4-settings.ini", GTK4_SETTINGS),
            ("qt5ct-matugen.conf", QT5_COLORS),
            ("qt5ct-matugen.qss", QT5_QSS),
            ("qt6ct-matugen.conf", QT6_COLORS),
            ("qt6ct-matugen.qss", QT6_QSS),
        ]
        for name, target in mapping:
            source = DEFAULTS / name
            if source.exists():
                shutil.copy2(source, target)
        run("hyprctl", "reload")
        restart_waybar()
        self.refresh_status()

    def verify_and_report(self):
        ok = verify_hypr_config()
        self.refresh_status(extra=f"\nverify  {'ok' if ok else 'failed'}")

    def refresh_status(self, extra=""):
        if not self.status_label:
            return
        data = {
            "opacity": f"{option_float('decoration:active_opacity', 1.0):.2f} active / {option_float('decoration:inactive_opacity', 1.0):.2f} inactive",
            "blur": "on" if option_int("decoration:blur:enabled", 0) else "off",
            "animations": "on" if option_int("animations:enabled", 1) else "off",
            "gaps": f"{option_custom_numbers('general:gaps_in', (0,))[0]} in / {option_custom_numbers('general:gaps_out', (0,))[0]} out",
            "border": option_int("general:border_size", 1),
            "rounding": option_int("decoration:rounding", 0),
            "hover": option_int("input:follow_mouse", 1),
            "tap": "on" if option_int("input:touchpad:tap-to-click", 1) else "off",
        }
        self.status_label.set_label("\n".join(f"{key:>10}  {value}" for key, value in data.items()) + extra)


if __name__ == "__main__":
    app = Dashboard()
    app.run()
