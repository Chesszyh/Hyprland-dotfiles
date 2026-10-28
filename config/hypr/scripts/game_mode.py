#!/usr/bin/env python3
"""Temporarily reduce desktop effects and restore the settings they replaced."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys

STATE = Path(os.environ["XDG_RUNTIME_DIR"]) / ("hypr-game-mode-" + os.environ["HYPRLAND_INSTANCE_SIGNATURE"] + ".json")
OPTIONS = {
    "animations:enabled": False,
    "decoration:shadow:enabled": False,
    "decoration:blur:enabled": False,
    "decoration:rounding": 0,
    "general:gaps_in": 0,
    "general:gaps_out": 0,
    "general:border_size": 1,
}


def lua(value):
    if isinstance(value, dict):
        return "{" + ",".join(f"[{json.dumps(k)}]={lua(v)}" for k, v in value.items()) + "}"
    return json.dumps(value, ensure_ascii=False)


def config(values):
    root = {}
    for name, value in values.items():
        target = root
        keys = name.split(":")
        for key in keys[:-1]:
            target = target.setdefault(key, {})
        target[keys[-1]] = value
    return lua(root)


def evaluate(code):
    result = subprocess.check_output(["hyprctl", "eval", code], text=True).strip()
    if result != "ok":
        raise RuntimeError(result)


def read_options():
    values = {}
    for name in OPTIONS:
        value = json.loads(subprocess.check_output(["hyprctl", "-j", "getoption", name], text=True))
        if "css" in value:
            values[name] = dict(zip(("top", "right", "bottom", "left"), map(int, value["css"].split())))
        else:
            values[name] = next(value[k] for k in ("bool", "int", "float", "str") if k in value)
    return values


def pause_wallpaper(state):
    result = subprocess.run(["pgrep", "-x", "mpvpaper"], capture_output=True, text=True)
    paused = set(state.get("paused", []))
    for pid in map(int, result.stdout.split()):
        os.kill(pid, signal.SIGSTOP)
        paused.add(pid)
    state["paused"] = sorted(paused)


def save(state):
    STATE.write_text(json.dumps(state))
    STATE.chmod(0o600)


def main(mode):
    state = json.loads(STATE.read_text()) if STATE.exists() else None
    if mode in ("apply", "pause-wallpaper") and state is None:
        return
    if mode == "pause-wallpaper":
        pause_wallpaper(state)
        save(state)
        return
    if mode == "toggle" and state is not None:
        evaluate('hl.window_rule({ name = "game-mode-opacity", enabled = false }); hl.config(' + config(state["options"]) + ")")
        for pid in state.get("paused", []):
            proc = Path(f"/proc/{pid}/comm")
            if proc.exists() and proc.read_text().strip() == "mpvpaper":
                os.kill(pid, signal.SIGCONT)
        STATE.unlink()
        subprocess.run(["notify-send", "游戏模式", "已恢复桌面效果和壁纸"])
        return
    # A reload may apply a new theme; preserve that configuration for the next exit.
    state = {"options": read_options(), "paused": (state or {}).get("paused", [])}
    save(state)
    evaluate('hl.config(' + config(OPTIONS) + '); hl.window_rule({ name = "game-mode-opacity", match = { class = ".*" }, opacity = "1 override 1 override 1 override" })')
    pause_wallpaper(state)
    save(state)
    if mode == "toggle":
        subprocess.run(["notify-send", "游戏模式", "已减少桌面效果并暂停动态壁纸"])


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "toggle")
