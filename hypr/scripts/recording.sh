#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/scripts/rofi-common.sh"

pidfile="${XDG_RUNTIME_DIR:-/tmp}/hypr-recording.pid"
current_file="${XDG_RUNTIME_DIR:-/tmp}/hypr-recording-current"
dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$dir"

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

running_pid() {
    if [[ -f "$pidfile" ]]; then
        local pid
        pid=$(<"$pidfile")
        if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" >/dev/null 2>&1; then
            printf '%s\n' "$pid"
            return 0
        fi
    fi

    rm -f "$pidfile" "$current_file"
    return 1
}

status() {
    local file tooltip

    if running_pid >/dev/null; then
        file=$(<"$current_file" 2>/dev/null || printf 'recording')
        tooltip="Recording\n$(basename "$file")\nLeft click: stop\nRight click: area recording"
        printf '{"text":"󰑋 rec","class":"recording","tooltip":"%s"}\n' "$(json_escape "$tooltip")"
    else
        tooltip="Screen recording\nNative monitor, 60 FPS, CRF 8\nLeft click: full screen\nRight click: select area\nMiddle click: recordings folder"
        printf '{"text":"󰕧 rec","class":"idle","tooltip":"%s"}\n' "$(json_escape "$tooltip")"
    fi
}

stop_recording() {
    local pid
    pid=$(running_pid || true)
    [[ -n "${pid:-}" ]] || {
        notify "Recording" "Nothing is recording."
        return 0
    }

    kill -INT "$pid" >/dev/null 2>&1 || true
    for _ in {1..30}; do
        kill -0 "$pid" >/dev/null 2>&1 || break
        sleep 0.1
    done
    kill -0 "$pid" >/dev/null 2>&1 && kill -TERM "$pid" >/dev/null 2>&1 || true
    rm -f "$pidfile"

    local file
    file=$(<"$current_file" 2>/dev/null || true)
    rm -f "$current_file"
    notify "Recording saved" "${file:-$dir}"
}

record_args() {
    local file="$1"
    shift

    printf '%s\0' \
        -f "$file" \
        -D \
        -r "${RECORD_FPS:-60}" \
        -c "${RECORD_CODEC:-libx264}" \
        -p "preset=${RECORD_PRESET:-slow}" \
        -p "crf=${RECORD_CRF:-8}" \
        -C "${RECORD_AUDIO_CODEC:-libopus}" \
        -a \
        "$@"
}

focused_monitor() {
    hyprctl monitors -j 2>/dev/null |
        jq -r 'first(.[] | select(.focused == true) | .name) // first(.[].name) // empty' 2>/dev/null
}

start_recording() {
    local target="${1:-full}"
    local geom=""
    local file="$dir/recording_$(date +%Y-%m-%d_%H-%M-%S).mkv"
    local log="${XDG_RUNTIME_DIR:-/tmp}/hypr-recording.log"
    local args=()
    local monitor=""

    if running_pid >/dev/null; then
        stop_recording
        return 0
    fi

    if ! command -v wf-recorder >/dev/null 2>&1; then
        notify-send -u critical "Recording" "wf-recorder is not installed."
        exit 1
    fi

    case "$target" in
        area)
            geom=$(slurp)
            [[ -n "$geom" ]] || exit 0
            args=(-g "$geom")
            ;;
        full)
            monitor=$(focused_monitor)
            if [[ -n "${monitor:-}" ]]; then
                args=(-o "$monitor")
            else
                args=()
            fi
            ;;
        *)
            echo "Usage: $0 [status|toggle|full|area|stop|menu|open]" >&2
            exit 1
            ;;
    esac

    mapfile -d '' -t wf_args < <(record_args "$file" "${args[@]}")
    wf-recorder "${wf_args[@]}" >"$log" 2>&1 &
    local pid=$!
    printf '%s\n' "$pid" >"$pidfile"
    printf '%s\n' "$file" >"$current_file"
    disown "$pid" >/dev/null 2>&1 || true

    notify "Recording started" "$(basename "$file")"
}

open_recordings() {
    xdg-open "$dir" >/dev/null 2>&1 &
}

case "${1:-status}" in
    status) status ;;
    toggle|full) start_recording full ;;
    area) start_recording area ;;
    stop) stop_recording ;;
    open) open_recordings ;;
    menu)
        choice=$(printf '%s\n' "Full screen" "Select area" "Stop recording" "Open recordings" | menu "record")
        case "$choice" in
            "Full screen") start_recording full ;;
            "Select area") start_recording area ;;
            "Stop recording") stop_recording ;;
            "Open recordings") open_recordings ;;
        esac
        ;;
    *)
        echo "Usage: $0 [status|toggle|full|area|stop|menu|open]" >&2
        exit 1
        ;;
esac
