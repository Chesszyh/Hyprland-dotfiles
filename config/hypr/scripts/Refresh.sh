#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for refreshing ags, waybar, rofi, swaync, wallust

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Kill already running processes
_ps=(rofi ags)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# quit ags & relaunch ags
#ags -q && ags &

# Restart desktop UI via user services so they stay outside Hyprland's cgroup.
systemctl --user restart waybar.service
systemctl --user reset-failed swaync.service >/dev/null 2>&1 || true
systemctl --user restart swaync.service
systemctl --user restart qs.service
swaync-client --reload-config >/dev/null 2>&1 || true


exit 0
