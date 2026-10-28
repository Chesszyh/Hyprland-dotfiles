#!/usr/bin/env bash
set -euo pipefail

state_dir="$HOME/.local/state/dark-angel"
CURRENT="$(hyprctl -j getoption decoration:screen_shader | python3 -c 'import json, sys; print(json.load(sys.stdin)["str"])')"

if [[ -n "$CURRENT" && "$CURRENT" != "none" ]]; then
    state=off
    message="暗黑晕影效果已关闭"
else
    state=on
    message="暗黑晕影效果已开启"
fi

mkdir -p "$state_dir"
printf '%s\n' "$state" > "$state_dir/screen-shader"
reply="$(hyprctl reload)"
if [[ "$reply" != "ok" ]]; then
    printf 'Hyprland shader reload failed: %s\n' "$reply" >&2
    exit 1
fi
notify-send -u low -i "video-display" "屏幕着色器" "$message"
