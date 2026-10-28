#!/usr/bin/env bash

set -euo pipefail

service="daktilo.service"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/daktilo"
preset_file="$state_dir/preset"
default_preset="musicbox"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send \
      -u low \
      -t 1500 \
      -h string:x-canonical-private-synchronous:daktilo_mute \
      "Daktilo" \
      "$1"
  fi
}

if systemctl --user is-active --quiet "$service"; then
  systemctl --user stop "$service"
  notify "Muted"
else
  mkdir -p "$state_dir"
  if [[ ! -s "$preset_file" ]]; then
    printf '%s\n' "$default_preset" > "$preset_file"
  fi
  preset="$(<"$preset_file")"
  systemctl --user reset-failed "$service" >/dev/null 2>&1 || true
  systemctl --user start "$service"
  notify "Playing $preset"
fi
