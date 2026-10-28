#!/usr/bin/env python3
"""Present the descriptions defined alongside the active Lua bindings."""
import json
from pathlib import Path
import re
import subprocess
import sys

SOURCE = Path(__file__).resolve().parents[1] / "configs/keybinds.lua"


def entries(common=False):
    rows = []
    for line in SOURCE.read_text().splitlines():
        match = re.match(r'\s*hl\.bind\((?:mainMod \.\. "([^"]+)"|"([^"]+)"),.*description = ("(?:[^"\\]|\\.)*")', line)
        if not match:
            continue
        description = json.loads(match[3])
        if common and not description.startswith("常用 / "):
            continue
        key = "SUPER" + match[1] if match[1] else match[2]
        key = re.sub(r'code:(1[0-9])', lambda m: str((int(m[1])-9) % 10), key)
        key = key.replace("Return", "Enter").replace("Escape", "Esc")
        rows.append(f"{key}  →  {description.removeprefix('常用 / ')}")
    return rows


if __name__ == "__main__":
    common = "--common" in sys.argv
    rows = entries(common)
    if "--print" in sys.argv:
        print("\n".join(rows))
    else:
        subprocess.run(["rofi", "-dmenu", "-i", "-p", "常用操作" if common else "全部快捷键",
                        "-config", str(Path.home() / ".config/rofi/config-keybinds.rasi")],
                       input="\n".join(rows), text=True)
