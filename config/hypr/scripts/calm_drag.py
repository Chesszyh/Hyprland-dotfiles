#!/usr/bin/env python3
"""Temporarily focus a window after repeated drag reversals."""

import fcntl
import json
import math
import os
import signal
import socket
import subprocess
import time
from collections import deque
from pathlib import Path


SAMPLE_SECONDS = 0.2
WINDOW_SECONDS = 3.0
CALM_SECONDS = 8.0


def ipc(path, request):
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(0.5)
        connection.connect(str(path))
        connection.sendall(request.encode())
        parts = []
        while data := connection.recv(65536):
            parts.append(data)
    return b"".join(parts).decode()


def set_calm(address, enabled):
    tag = "+calm-drag" if enabled else "-calm-drag"
    code = f'hl.dsp.window.tag({{ tag = "{tag}", window = "address:{address}" }})'
    subprocess.run(["hyprctl", "dispatch", code], check=True, capture_output=True, text=True)


def drag_animation(path):
    return json.loads(ipc(path, "j/getoption misc:animate_mouse_windowdragging"))["bool"]


def set_drag_animation(enabled):
    value = "true" if enabled else "false"
    code = f"hl.config({{ misc = {{ animate_mouse_windowdragging = {value} }} }})"
    subprocess.run(["hyprctl", "eval", code], check=True, capture_output=True, text=True)


def restless(samples):
    if len(samples) < 5:
        return False
    turns = 0
    distance = 0.0
    previous_direction = None
    for (_, x1, y1), (_, x2, y2) in zip(samples, list(samples)[1:]):
        dx, dy = x2 - x1, y2 - y1
        length = math.hypot(dx, dy)
        if length < 24:
            continue
        direction = (dx / length, dy / length)
        if previous_direction and sum(a * b for a, b in zip(direction, previous_direction)) < -0.35:
            turns += 1
        previous_direction = direction
        distance += length
    return turns >= 3 and distance >= 420


def main():
    runtime = Path(os.environ["XDG_RUNTIME_DIR"]) / "hypr" / os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    sock = runtime / ".socket.sock"
    with (runtime / "calm-drag-focus.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return

        stopped = False

        def stop(_signum, _frame):
            nonlocal stopped
            stopped = True

        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
        samples = deque()
        tracked = None
        last_position = None
        effect_window = None
        previous_drag_animation = None
        calm_until = 0.0
        try:
            while not stopped:
                now = time.monotonic()
                try:
                    window = json.loads(ipc(sock, "j/activewindow"))
                except (OSError, ValueError):
                    break
                active = window.get("address") if not window.get("fullscreen") else None
                moving = active if window.get("floating") else None
                position = tuple(window["at"]) if moving and window.get("at") else None

                if moving != tracked:
                    samples.clear()
                    tracked = moving
                    last_position = None
                if effect_window == moving and position and last_position and position != last_position:
                    calm_until = now + CALM_SECONDS
                if effect_window and (active != effect_window or now >= calm_until):
                    set_calm(effect_window, False)
                    effect_window = None
                    if previous_drag_animation is not None:
                        if drag_animation(sock) != previous_drag_animation:
                            set_drag_animation(previous_drag_animation)
                        previous_drag_animation = None

                if position:
                    samples.append((now, *position))
                    while samples and now - samples[0][0] > WINDOW_SECONDS:
                        samples.popleft()
                    if restless(samples):
                        if effect_window != moving:
                            previous_drag_animation = drag_animation(sock)
                            set_calm(moving, True)
                            effect_window = moving
                            set_drag_animation(True)
                        calm_until = now + CALM_SECONDS
                        samples.clear()
                else:
                    samples.clear()
                last_position = position
                time.sleep(SAMPLE_SECONDS)
        finally:
            if effect_window:
                try:
                    set_calm(effect_window, False)
                except (OSError, subprocess.CalledProcessError):
                    pass
            if previous_drag_animation is not None:
                try:
                    if drag_animation(sock) != previous_drag_animation:
                        set_drag_animation(previous_drag_animation)
                except (OSError, ValueError, subprocess.CalledProcessError):
                    pass


if __name__ == "__main__":
    main()
