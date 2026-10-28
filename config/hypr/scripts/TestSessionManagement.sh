#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
python3 -m unittest discover -s "$root/tests" -p test_session.py -v
systemctl --user is-active hyprland-session-save.timer
hyprctl configerrors
