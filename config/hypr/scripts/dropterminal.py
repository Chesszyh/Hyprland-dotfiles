#!/usr/bin/env python3
"""Toggle one terminal on the focused monitor, returning focus when hidden."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time

STATE = Path(os.environ["XDG_RUNTIME_DIR"]) / "hypr-dropdown-terminal.json"


def query(name):
    return json.loads(subprocess.check_output(["hyprctl", "-j", name], text=True))


def dispatch(expression):
    result = subprocess.check_output(["hyprctl", "dispatch", expression], text=True).strip()
    if result != "ok":
        raise RuntimeError(result)


def geometry(monitor):
    width, height = monitor["width"], monitor["height"]
    if monitor.get("transform", 0) % 2:
        width, height = height, width
    width, height = width / monitor["scale"], height / monitor["scale"]
    return (round(monitor["x"] + width * .25), round(monitor["y"] + height * .05),
            round(width * .5), round(height * .5))


def toggle(command):
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    clients = query("clients")
    terminal = next((w for w in clients if w["address"] == state.get("address")), None)
    if terminal and terminal["workspace"]["name"] != "special:scratchpad":
        selector = json.dumps("address:" + terminal["address"])
        if terminal.get("pinned"):
            dispatch(f"hl.dsp.window.pin({{ window = {selector} }})")
        dispatch(f"hl.dsp.window.move({{ window = {selector}, workspace = 'special:scratchpad', follow = false }})")
        if state.get("previous") in {w["address"] for w in clients}:
            dispatch(f"hl.dsp.focus({{ window = {json.dumps('address:' + state['previous'])} }})")
        return
    active = query("activewindow")
    workspace = query("activeworkspace")["id"]
    monitor = next(m for m in query("monitors") if m["focused"])
    x, y, width, height = geometry(monitor)
    state["previous"] = active.get("address")
    if terminal is None:
        before = {w["address"] for w in clients}
        dispatch(f"hl.dsp.exec_cmd({json.dumps(command)}, {{ float = true, workspace = 'special:scratchpad silent' }})")
        expected_class = Path(shlex.split(command)[0]).name
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            terminal = next((w for w in query("clients") if w["address"] not in before and w["class"].lower() == expected_class.lower()), None)
            if terminal:
                break
            time.sleep(.1)
        if terminal is None:
            raise RuntimeError("未找到新建的下拉终端窗口")
        state["address"] = terminal["address"]
    selector = json.dumps("address:" + terminal["address"])
    dispatch(f"hl.dsp.window.float({{ window = {selector}, action = 'enable' }})")
    dispatch(f"hl.dsp.window.move({{ window = {selector}, workspace = {workspace}, follow = false }})")
    dispatch(f"hl.dsp.window.resize({{ window = {selector}, x = {width}, y = {height} }})")
    dispatch(f"hl.dsp.window.move({{ window = {selector}, x = {x}, y = {y} }})")
    if not terminal.get("pinned"):
        dispatch(f"hl.dsp.window.pin({{ window = {selector} }})")
    dispatch(f"hl.dsp.focus({{ window = {selector} }})")
    STATE.write_text(json.dumps(state))


if __name__ == "__main__":
    toggle(sys.argv[1])
