#!/usr/bin/env bash

set -euo pipefail
source "$HOME/.config/hypr/UserScripts/WallpaperState.sh"
load_wallpaper_state

if [[ "$wallpaper_mode" == video ]]; then
  exec "$HOME/.config/hypr/UserScripts/WallpaperLiveApply.sh"
fi
exec "$HOME/.config/hypr/UserScripts/WallpaperStartup.sh"
