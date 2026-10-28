#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.config/hypr/UserScripts/WallpaperState.sh"
load_wallpaper_state
iDIR="$HOME/.config/swaync/images"

if [[ "$livewallpaper_mute" == yes ]]; then
  livewallpaper_mute=no
  notify_msg="Video wallpaper unmuted"
else
  livewallpaper_mute=yes
  notify_msg="Video wallpaper muted"
fi
save_wallpaper_state

if [[ "$wallpaper_mode" == video ]]; then
  "$HOME/.config/hypr/UserScripts/WallpaperLiveApply.sh" || true
fi

notify-send -i "$iDIR/ja.png" "Wallpaper Audio" "$notify_msg" || true
