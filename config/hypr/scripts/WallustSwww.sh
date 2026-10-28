#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Wallust Colors for current wallpaper

# Get current focused monitor
current_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
wallpaper_path="${1:-}"
if [ -z "$wallpaper_path" ]; then
    wallpaper_path=$(awww query --json | jq -r --arg monitor "$current_monitor" '[.. | objects | select(.name? == $monitor) | .displaying.image?] | map(select(. != null)) | first // empty')
fi

if [ -z "$wallpaper_path" ] || [ ! -f "$wallpaper_path" ]; then
    exit 1
fi

ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"
current_wallpaper="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
if [ "$(readlink -f "$wallpaper_path")" != "$(readlink -f "$current_wallpaper")" ]; then
    cp -f "$wallpaper_path" "$current_wallpaper"
fi
wallust run "$wallpaper_path" -s
hyprctl reload >/dev/null 2>&1 || true
