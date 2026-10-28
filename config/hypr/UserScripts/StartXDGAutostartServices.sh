#!/usr/bin/env bash
set -u

# In non-uwsm Hyprland sessions, graphical-session/xdg autostart targets
# are not always activated. Start generated autostart units explicitly.
mapfile -t units < <(
  systemctl --user list-unit-files 'app-*@autostart.service' --no-legend --no-pager 2>/dev/null \
    | awk '{print $1}'
)

for unit in "${units[@]}"; do
  systemctl --user start "$unit" >/dev/null 2>&1 || true
done

