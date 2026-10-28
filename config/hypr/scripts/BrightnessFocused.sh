#!/bin/bash
# Route brightness keys to the monitor that currently has Hyprland focus.

scripts_dir="$HOME/.config/hypr/scripts"

get_focused_monitor() {
    local focused_monitor

    focused_monitor=$(hyprctl -j activeworkspace | jq -r '.monitor // empty')
    if [ -n "$focused_monitor" ]; then
        printf '%s\n' "$focused_monitor"
        return 0
    fi

    hyprctl -j monitors | jq -r '.[] | select(.focused == true) | .name' | head -n1
}

is_internal_monitor() {
    [[ "$1" =~ ^(eDP|LVDS|DSI) ]]
}

main() {
    local action focused_monitor

    action=${1:---get}
    focused_monitor=$(get_focused_monitor)

    if [ -z "$focused_monitor" ] || is_internal_monitor "$focused_monitor"; then
        exec "$scripts_dir/Brightness.sh" "$action"
    fi

    exec "$scripts_dir/ExternalBrightness.sh" --connector "$focused_monitor" "$action"
}

main "$@"
