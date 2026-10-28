#!/bin/bash
# Import Wallpaper Engine package with repkg, mux video+audio, and apply in Hyprland.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/wallpaper.pkg [output_name]"
  exit 1
fi

pkg_path="$1"
custom_name="${2:-}"
repkg_bin="/usr/local/bin/repkg"
cwd="$(pwd)"
extract_dir="$cwd/output"
source "$HOME/.config/hypr/UserScripts/WallpaperState.sh"
live_apply_script="$HOME/.config/hypr/UserScripts/WallpaperLiveApply.sh"
dynamic_root="$HOME/Pictures/wallpapers/Dynamic-Wallpapers"

if [ ! -f "$pkg_path" ]; then
  echo "Error: pkg not found: $pkg_path"
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg not found"
  exit 1
fi

if [ ! -x "$repkg_bin" ]; then
  echo "Error: repkg not executable at $repkg_bin"
  exit 1
fi

slugify() {
  local s="$1"
  s="$(printf "%s" "$s" | tr '[:upper:]' '[:lower:]')"
  s="$(printf "%s" "$s" | sed -E 's/[^a-z0-9._-]+/_/g; s/^_+//; s/_+$//')"
  [ -z "$s" ] && s="wallpaper"
  printf "%s" "$s"
}

pick_largest_file() {
  local search_dir="$1"
  shift
  find "$search_dir" -type f \( "$@" \) -printf '%s\t%p\n' 2>/dev/null \
    | sort -nr \
    | head -n 1 \
    | cut -f2-
}

detect_audio_for_video() {
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

pkg_base="$(basename "$pkg_path")"
pkg_name="${pkg_base%.*}"
[ -n "$custom_name" ] && pkg_name="$custom_name"
safe_name="$(slugify "$pkg_name")"

mkdir -p "$dynamic_root"
rm -rf "$extract_dir"
echo "[1/5] Extracting with repkg..."
"$repkg_bin" extract "$pkg_path" -o "$extract_dir" --overwrite

materials_dir="$extract_dir/materials"
sounds_dir="$extract_dir/sounds"

if [ ! -d "$materials_dir" ]; then
  echo "Error: materials directory not found: $materials_dir"
  exit 1
fi

video_file="$(pick_largest_file "$materials_dir" -iname '*.raw.mp4' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov')"
if [ -z "$video_file" ]; then
  video_file="$(pick_largest_file "$extract_dir" -iname '*.raw.mp4' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov')"
fi

if [ -z "$video_file" ] || [ ! -f "$video_file" ]; then
  echo "Error: no video file found in extracted output"
  exit 1
fi

audio_file=""
if [ -d "$sounds_dir" ]; then
  audio_file="$(pick_largest_file "$sounds_dir" -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' -o -iname '*.flac' -o -iname '*.ogg' -o -iname '*.opus' -o -iname '*.aac')"
fi
if [ -z "$audio_file" ]; then
  audio_file="$(detect_audio_for_video "$video_file" || true)"
fi

target_dir="$dynamic_root/$safe_name"
mkdir -p "$target_dir"
final_file="$target_dir/${safe_name}.final.mp4"

echo "[2/5] Video: $video_file"
if [ -n "$audio_file" ] && [ -f "$audio_file" ]; then
  echo "[3/5] Audio: $audio_file"
  echo "[4/5] Muxing and extending video to audio length..."
  ffmpeg -y -stream_loop -1 -i "$video_file" -i "$audio_file" \
    -map 0:v:0 -map 1:a:0 \
    -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
    -c:a aac -b:a 192k -shortest "$final_file"
else
  echo "[3/5] No external audio found, transcoding video only..."
  ffmpeg -y -i "$video_file" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an "$final_file"
fi

echo "[5/5] Updating Hypr wallpaper config..."
load_wallpaper_state
wallpaper_mode=video
livewallpaper="$final_file"
livewallpaper_audio=""
save_wallpaper_state

"$live_apply_script" || true
echo "Done: $final_file"
