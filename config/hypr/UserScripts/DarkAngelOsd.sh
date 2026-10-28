#!/usr/bin/env bash
set -euo pipefail

kind="${1:-status}"
value="${2:-0}"
label="${3:-}"

case "$kind" in
  volume)
    qs ipc call osd showVolume "$value" >/dev/null
    ;;
  brightness)
    qs ipc call osd showBrightness "$value" >/dev/null
    ;;
  media)
    qs ipc call osd showMedia "${label:-Media}" >/dev/null
    ;;
  *)
    notify-send "Dark Angel" "${label:-$kind}: $value" >/dev/null 2>&1 || true
    ;;
esac
