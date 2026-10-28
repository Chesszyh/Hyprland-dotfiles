#!/usr/bin/env python3
import json
from pathlib import Path

HOME = Path.home()
ROOT = HOME / ".config" / "dark-angel"
STATE_ROOT = HOME / ".local" / "state" / "dark-angel"
CACHE_ROOT = HOME / ".cache" / "dark-angel"

palette = json.loads((ROOT / "palette.json").read_text(encoding="utf-8"))
assert set(palette) == {"light", "dark"}

for mode, theme in palette.items():
    assert theme["mode"] == mode
    for key, value in theme.items():
        if key != "mode":
            assert isinstance(value, str) and value.startswith("#") and len(value) == 7

for path in [
    STATE_ROOT / "qml_color.json",
    STATE_ROOT / "current",
    STATE_ROOT / "hypr.conf",
    CACHE_ROOT / "rofi.rasi",
    CACHE_ROOT / "swaync.css",
]:
    assert path.exists(), f"missing generated file: {path}"

json.loads((STATE_ROOT / "qml_color.json").read_text(encoding="utf-8"))
print("dark-angel system theme ok")
