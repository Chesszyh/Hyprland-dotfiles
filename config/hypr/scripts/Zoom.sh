#!/usr/bin/env bash

set -euo pipefail

factor=$(hyprctl -j getoption cursor:zoom_factor | jq -r '.float')
case "${1:-}" in
  in) factor=$(awk -v n="$factor" 'BEGIN { print (n < 1 ? 1 : n) * 2 }') ;;
  out) factor=$(awk -v n="$factor" 'BEGIN { print (n < 1 ? 1 : n) / 2 }') ;;
  *) exit 2 ;;
esac
hyprctl eval "hl.config({ cursor = { zoom_factor = $factor } })" >/dev/null
