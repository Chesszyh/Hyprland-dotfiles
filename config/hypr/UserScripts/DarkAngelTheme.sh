#!/usr/bin/env bash
set -euo pipefail

mode="${1:-toggle}"
qs_target=(qs ipc call theme)
theme_script="$HOME/.config/hypr/UserScripts/DarkAngelApply.sh"

case "$mode" in
  light|dark)
    if ! "${qs_target[@]}" switchTo "$mode" >/dev/null 2>&1; then
      "$theme_script" "$mode"
    fi
    ;;
  toggle)
    if ! "${qs_target[@]}" toggle >/dev/null 2>&1; then
      "$theme_script" toggle
    fi
    ;;
  *)
    printf 'Usage: %s [light|dark|toggle]\n' "$0" >&2
    exit 2
    ;;
esac

sleep 0.2
hyprctl reload >/dev/null 2>&1 || true
