#!/usr/bin/env bash

set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/daktilo"
preset_file="$state_dir/preset"
default_preset="musicbox"

mkdir -p "$state_dir"

if [[ ! -s "$preset_file" ]]; then
	printf '%s\n' "$default_preset" >"$preset_file"
fi

preset="$(<"$preset_file")"
exec "${DAKTILO_BIN:-$HOME/.cargo/bin/daktilo}" --device pipewire --preset "$preset" --variate-volume 0.7,0.9
