#!/bin/bash
# Apply live wallpaper using Startup_Apps.conf variables.

set -euo pipefail

source "$HOME/.config/hypr/UserScripts/WallpaperState.sh"
load_wallpaper_state

detect_sidecar_audio() {
  local video_path="$1"
  local base="${video_path%.*}"
  local ext
  for ext in mp3 m4a wav flac ogg opus aac; do
    if [ -f "${base}.${ext}" ]; then
      printf "%s" "${base}.${ext}"
      return 0
    fi
  done
  return 1
}

if [ -z "$livewallpaper" ] || [ ! -f "$livewallpaper" ]; then
  exit 0
fi

if [ -z "$livewallpaper_audio" ] || [ ! -f "$livewallpaper_audio" ]; then
  livewallpaper_audio="$(detect_sidecar_audio "$livewallpaper" || true)"
fi

opts="$livewallpaper_opts mute=$livewallpaper_mute"
if [ -n "$livewallpaper_audio" ] && [ -f "$livewallpaper_audio" ]; then
  escaped_audio="${livewallpaper_audio//\'/\'\\\'\'}"
  opts="$opts audio-file='${escaped_audio}' audio-file-auto=no"
fi

awww kill 2>/dev/null || true
pkill mpvpaper 2>/dev/null || true
nohup mpvpaper '*' -o "$opts" "$livewallpaper" >/tmp/mpvpaper-wallpaper.log 2>&1 &
"$HOME/.config/hypr/scripts/GameMode.sh" pause-wallpaper
