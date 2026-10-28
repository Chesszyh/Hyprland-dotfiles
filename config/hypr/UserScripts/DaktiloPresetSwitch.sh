#!/usr/bin/env bash

set -euo pipefail

direction="${1:-next}"
service="daktilo.service"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/daktilo"
preset_file="$state_dir/preset"
lock_file="$state_dir/preset-switch.lock"
last_switch_file="$state_dir/last-switch-ms"
presets=(default basic musicbox osu drumkit sparks ducktilo)
default_preset="musicbox"
debounce_ms=250

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send \
      -u low \
      -t 1500 \
      -h string:x-canonical-private-synchronous:daktilo_preset \
      "Daktilo" \
      "$1"
  fi
}

mkdir -p "$state_dir"

exec 9>"$lock_file"
if ! flock -n 9; then
  exit 0
fi

now_ms="$(date +%s%3N)"
last_switch_ms=0
if [[ -s "$last_switch_file" ]]; then
  last_switch_ms="$(<"$last_switch_file")"
fi

if (( now_ms - last_switch_ms < debounce_ms )); then
  exit 0
fi

printf '%s\n' "$now_ms" > "$last_switch_file"

current="$default_preset"
if [[ -s "$preset_file" ]]; then
  current="$(<"$preset_file")"
fi

index=0
for i in "${!presets[@]}"; do
  if [[ "${presets[$i]}" == "$current" ]]; then
    index="$i"
    break
  fi
done

case "$direction" in
  prev|previous|left)
    index=$(( (index + ${#presets[@]} - 1) % ${#presets[@]} ))
    ;;
  next|right)
    index=$(( (index + 1) % ${#presets[@]} ))
    ;;
  *)
    notify "Unknown preset direction: $direction"
    exit 2
    ;;
esac

next_preset="${presets[$index]}"
printf '%s\n' "$next_preset" > "$preset_file"

systemctl --user reset-failed "$service" >/dev/null 2>&1 || true

if systemctl --user is-active --quiet "$service"; then
  systemctl --user restart "$service"
  notify "Playing $next_preset"
else
  notify "Selected $next_preset"
fi
