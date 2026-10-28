#!/usr/bin/env bash
set -euo pipefail
"$(dirname "$0")/SessionSave.sh" auto
systemctl --user stop hyprland-session-save.timer
