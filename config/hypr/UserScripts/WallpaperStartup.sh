#!/usr/bin/env bash

set -euo pipefail

wall="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
[[ -f "$wall" ]] || exit 1

for _ in {1..30}; do
  if "$HOME/.config/hypr/UserScripts/AwwwEnsure.sh" \
    && awww img "$wall" --transition-type none --transition-duration 0 \
    && awww query --json | jq -e --arg wall "$wall" \
      '[.[][] | select(.displaying.image == $wall)] | length > 0' >/dev/null; then
    exit 0
  fi
  sleep 1
done

printf 'WallpaperStartup: could not apply %s after 30 attempts\n' "$wall" >&2
exit 1
