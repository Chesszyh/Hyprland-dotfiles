#!/usr/bin/env bash
set -euo pipefail

mode="${1:-toggle}"
state_dir="$HOME/.local/state/dark-angel"
current_file="$state_dir/current"
theme_system="$HOME/.config/dark-angel/scripts/apply-theme.py"

read_current() {
  if [[ -f "$current_file" ]]; then
    local current
    current="$(<"$current_file")"
    if [[ "$current" == "light" || "$current" == "dark" ]]; then
      printf '%s\n' "$current"
      return
    fi
  fi
  printf 'dark\n'
}

case "$mode" in
  light|dark) ;;
  toggle)
    if [[ "$(read_current)" == "dark" ]]; then
      mode="light"
    else
      mode="dark"
    fi
    ;;
  *)
    printf 'Usage: %s [light|dark|toggle]\n' "$0" >&2
    exit 2
    ;;
esac

mkdir -p "$state_dir"
python3 "$theme_system" "$mode" >/dev/null
printf "@import '%s/.config/swaync/dark-angel-%s.css';\n" "$HOME" "$mode" > "$HOME/.config/swaync/dark-angel-current.css"

# Synchronize Waybar theme and reload CSS
if [[ "$mode" == "dark" ]]; then
  ln -sfr "$HOME/.config/waybar/style/dark-angel-abyss.css" "$HOME/.config/waybar/style/dark-angel-current.css"
  printf 'on\n' > "$state_dir/screen-shader"
else
  ln -sfr "$HOME/.config/waybar/style/dark-angel-ashen.css" "$HOME/.config/waybar/style/dark-angel-current.css"
  printf 'off\n' > "$state_dir/screen-shader"
fi
killall -SIGUSR2 waybar >/dev/null 2>&1 || true

set_rofi_theme() {
  local file="$1"
  local theme="$2"
  python3 - "$file" "$theme" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
theme = sys.argv[2]
lines = path.read_text(encoding="utf-8").splitlines()
out = []
done = False
for line in lines:
    if line.lstrip().startswith("@theme "):
        if not done:
            out.append(f'@theme "{theme}"')
            done = True
        continue
    out.append(line)
if not done:
    out.append(f'@theme "{theme}"')
path.write_text("\n".join(out) + "\n", encoding="utf-8")
PY
}

set_rofi_theme "$HOME/.config/rofi/config.rasi" "$HOME/.config/rofi/themes/dark-angel-launcher-${mode}.rasi"
set_rofi_theme "$HOME/.config/rofi/config-wallpaper.rasi" "$HOME/.config/rofi/themes/dark-angel-wallpaper-${mode}.rasi"
set_rofi_theme "$HOME/.config/rofi/config-clipboard.rasi" "$HOME/.config/rofi/themes/dark-angel-clipboard-${mode}.rasi"

# Synchronize Zed theme mode
if [[ -f "$HOME/.config/zed/settings.json" ]]; then
  if [[ "$mode" == "light" ]]; then
    sed -i 's/"mode": "dark"/"mode": "light"/' "$HOME/.config/zed/settings.json"
  else
    sed -i 's/"mode": "light"/"mode": "dark"/' "$HOME/.config/zed/settings.json"
  fi
fi

reply="$(hyprctl reload)"
if [[ "$reply" != "ok" ]]; then
  printf 'Hyprland theme reload failed: %s\n' "$reply" >&2
  exit 1
fi
swaync-client -R >/dev/null 2>&1 || true
swaync-client -rs >/dev/null 2>&1 || true
