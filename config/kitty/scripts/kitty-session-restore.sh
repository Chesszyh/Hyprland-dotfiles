#!/usr/bin/env bash
set -euo pipefail

state_dir="${KITTY_SESSION_STATE_DIR:-$HOME/.local/state/kitty-session}"
session_file="$state_dir/last.session"
kitty_bin="${KITTY_BIN:-kitty}"

if [[ -s "$session_file" ]]; then
    exec "$kitty_bin" --session "$session_file"
fi

exec "$kitty_bin"
