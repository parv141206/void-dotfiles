#!/usr/bin/env bash

set -euo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-cpu-stat"
mkdir -p "$(dirname "$cache")"

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_all=$((idle + iowait))
non_idle=$((user + nice + system + irq + softirq + steal))
total=$((idle_all + non_idle))

cpu=0
if [[ -f "$cache" ]]; then
    read -r prev_total prev_idle < "$cache" || true
    total_delta=$((total - prev_total))
    idle_delta=$((idle_all - prev_idle))
    if ((total_delta > 0)); then
        cpu=$(((100 * (total_delta - idle_delta)) / total_delta))
    fi
fi
printf '%s %s\n' "$total" "$idle_all" > "$cache"

ram=$(free | awk '/Mem:/ {printf "%d", ($3 / $2) * 100}')
disk=$(df -h / | awk 'NR == 2 {gsub("%", "", $5); print $5}')

temp=$(sensors 2>/dev/null |
    awk '
        /Package id 0:/ {gsub(/[+°C]/, "", $4); printf "%.0f", $4; found=1; exit}
        /^CPU:/ {gsub(/[+°C]/, "", $2); printf "%.0f", $2; found=1; exit}
        END {if (!found) print "n/a"}
    ')

fan=$(sensors 2>/dev/null |
    awk '/CPU Fan:|fan1:/ {print $2; found=1; exit} END {if (!found) print "n/a"}')

gpu_temp=$(sensors 2>/dev/null |
    awk '/^GPU:/ {gsub(/[+°C]/, "", $2); printf "%.0f", $2; found=1; exit} END {if (!found) print "n/a"}')

profile=$(powerprofilesctl get 2>/dev/null || printf 'n/a')
load=$(cut -d' ' -f1-3 /proc/loadavg)

text=" ${cpu}% 󰍛 ${ram}% 󰔏 ${temp}°"
tooltip="CPU: ${cpu}%\\nRAM: ${ram}%\\nDisk /: ${disk}%\\nCPU temp: ${temp}°C\\nGPU temp: ${gpu_temp}°C\\nFan: ${fan} RPM\\nLoad: ${load}\\nPower: ${profile}"

class="normal"
if [[ "$temp" =~ ^[0-9]+$ ]] && ((temp >= 85)); then
    class="critical"
elif [[ "$temp" =~ ^[0-9]+$ ]] && ((temp >= 75)); then
    class="warning"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
