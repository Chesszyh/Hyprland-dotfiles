#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-restore}" == delayed ]]; then
    sleep "${2:-1}"
fi
python3 "$(dirname "$0")/session.py" restore
if [[ "${1:-restore}" == delayed ]]; then
    systemctl --user start hyprland-session-save.timer
fi
