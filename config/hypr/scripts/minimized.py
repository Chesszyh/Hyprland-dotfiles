#!/usr/bin/env python3
"""Keep minimized windows discoverable and restore one to its saved workspace."""
import json
from pathlib import Path
import subprocess
import sys

CACHE = Path.home() / ".cache/hypr/minimized"


def query(name):
    return json.loads(subprocess.check_output(["hyprctl", "-j", name], text=True))


def dispatch(expression):
    result = subprocess.check_output(["hyprctl", "dispatch", expression], text=True).strip()
    if result != "ok":
        raise RuntimeError(result)


def hidden_windows():
    return [w for w in query("clients") if w["workspace"]["name"] == "special:minimized"]


def minimize():
    window = query("activewindow")
    if not window or window["workspace"]["name"] == "special:minimized":
        return
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / (window["address"] + ".json")
    path.write_text(json.dumps(window))
    path.chmod(0o600)
    selector = json.dumps("address:" + window["address"])
    if window.get("pinned"):
        dispatch(f"hl.dsp.window.pin({{ window = {selector}, action = 'disable' }})")
    dispatch(f"hl.dsp.window.move({{ window = {selector}, workspace = 'special:minimized', follow = false }})")


def restore(address=None):
    windows = hidden_windows()
    if not windows:
        subprocess.run(["notify-send", "最小化窗口", "没有待恢复的窗口"])
        return
    if address is None:
        rows = [f"{w['class']} — {w['title']}".replace("\n", " ") for w in windows]
        result = subprocess.run(["rofi", "-dmenu", "-i", "-format", "i", "-p", "恢复窗口",
                                 "-config", str(Path.home() / ".config/rofi/config-keybinds.rasi")],
                                input="\n".join(rows), text=True, capture_output=True)
        if result.returncode != 0:
            return
        address = windows[int(result.stdout.strip())]["address"]
    window = next(w for w in windows if w["address"] == address)
    path = CACHE / (address + ".json")
    saved = json.loads(path.read_text()) if path.exists() else None
    workspace = saved["workspace"]["name"] if saved else str(query("activeworkspace")["id"])
    selector = json.dumps("address:" + address)
    dispatch(f"hl.dsp.window.move({{ window = {selector}, workspace = {json.dumps(workspace)}, follow = false }})")
    if saved and saved["floating"]:
        dispatch(f"hl.dsp.window.float({{ window = {selector}, action = 'enable' }})")
        x, y = saved["at"]
        width, height = saved["size"]
        monitors = query("monitors")
        if not any(m["x"] <= x < m["x"] + m["width"] / m["scale"] and m["y"] <= y < m["y"] + m["height"] / m["scale"] for m in monitors):
            monitor = next((m for m in monitors if m["id"] == window["monitor"]), monitors[0])
            width = min(width, int(monitor["width"] / monitor["scale"]))
            height = min(height, int(monitor["height"] / monitor["scale"]))
            x, y = monitor["x"], monitor["y"]
        dispatch(f"hl.dsp.window.resize({{ window = {selector}, x = {width}, y = {height} }})")
        dispatch(f"hl.dsp.window.move({{ window = {selector}, x = {x}, y = {y} }})")
    dispatch(f"hl.dsp.focus({{ window = {selector} }})")
    if saved and saved.get("pinned"):
        dispatch(f"hl.dsp.window.pin({{ window = {selector}, action = 'enable' }})")
    path.unlink(missing_ok=True)


def status():
    count = len(hidden_windows())
    print(json.dumps({"text": f"▣ {count}" if count else "", "tooltip": f"{count} 个最小化窗口 · 点击恢复", "class": "minimized"}))


if __name__ == "__main__":
    action = sys.argv[1]
    if action == "minimize":
        minimize()
    elif action == "restore":
        restore(sys.argv[2] if len(sys.argv) > 2 else None)
    elif action == "status":
        status()
