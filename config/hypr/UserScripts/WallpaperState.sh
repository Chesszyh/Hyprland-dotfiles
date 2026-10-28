#!/usr/bin/env bash

wallpaper_state_file="$HOME/.config/hypr/wallpaper-state"

load_wallpaper_state() {
  wallpaper_mode=static
  livewallpaper=""
  livewallpaper_audio=""
  livewallpaper_opts="load-scripts=no loop panscan=1.0"
  livewallpaper_mute=yes
  [[ -f "$wallpaper_state_file" ]] && source "$wallpaper_state_file"
}

save_wallpaper_state() {
  local temp="${wallpaper_state_file}.tmp"
  {
    printf 'wallpaper_mode=%q\n' "$wallpaper_mode"
    printf 'livewallpaper=%q\n' "$livewallpaper"
    printf 'livewallpaper_audio=%q\n' "$livewallpaper_audio"
    printf 'livewallpaper_opts=%q\n' "$livewallpaper_opts"
    printf 'livewallpaper_mute=%q\n' "$livewallpaper_mute"
  } > "$temp"
  mv "$temp" "$wallpaper_state_file"
}
