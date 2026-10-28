#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/UserScripts/WallpaperState.sh"
load_wallpaper_state
iDIR="$HOME/.config/swaync/images"

if [[ "$wallpaper_mode" == video ]]; then
  wallpaper_mode=static
  save_wallpaper_state
  pkill mpvpaper 2>/dev/null || true
  "$HOME/.config/hypr/UserScripts/WallpaperStartup.sh"
  "$HOME/.config/hypr/scripts/WallustSwww.sh" >/dev/null 2>&1 &
  notify-send -i "$iDIR/ja.png" "Wallpaper Mode" "Switched to static wallpaper mode" || true
else
  wallpaper_mode=video
  save_wallpaper_state

  if command -v ffmpeg >/dev/null 2>&1 && [[ -f "$livewallpaper" ]]; then
    cache_key=$(printf "%s" "$livewallpaper" | md5sum | awk '{print $1}')
    preview_image="$HOME/.cache/video_preview/${cache_key}.png"
    mkdir -p "$HOME/.cache/video_preview"
    ffmpeg -v error -y -i "$livewallpaper" -ss 00:00:01.000 -vframes 1 "$preview_image"
    cp -f "$preview_image" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
  fi

  "$HOME/.config/hypr/UserScripts/WallpaperLiveApply.sh"
  notify-send -i "$iDIR/ja.png" "Wallpaper Mode" "Switched to live wallpaper mode" || true
fi
