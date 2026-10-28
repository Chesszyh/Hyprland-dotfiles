#!/usr/bin/python3

import ctypes
import subprocess
import time
from ctypes.util import find_library

from CliphistStore import store_clipboard_data


XFIXES_SET_SELECTION_OWNER_NOTIFY_MASK = 1


def read_x11_clipboard() -> bytes:
    try:
        targets = subprocess.run(
            ["/usr/bin/xclip", "-selection", "clipboard", "-out", "-target", "TARGETS"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2,
            check=False,
        )
        if targets.returncode != 0:
            return b""

        offered = set(targets.stdout.decode("ascii", errors="replace").splitlines())
        text_targets = ("UTF8_STRING", "text/plain;charset=utf-8", "text/plain", "STRING")
        metadata = {
            "TARGETS", "TIMESTAMP", "MULTIPLE", "SAVE_TARGETS", "TEXT",
            "TK_APPLICATION", "TK_WINDOW",
        }
        # Replacing a rich selection with text would discard its image/HTML/file formats.
        if offered - set(text_targets) - metadata:
            return b""
        target = next((target for target in text_targets if target in offered), None)
        if target is None:
            return b""

        result = subprocess.run(
            ["/usr/bin/xclip", "-selection", "clipboard", "-out", "-target", target],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return b""

    if result.returncode != 0:
        return b""
    if target == "STRING":
        return result.stdout.decode("latin-1").encode("utf-8")
    try:
        result.stdout.decode("utf-8")
    except UnicodeDecodeError:
        return b""
    return result.stdout


def publish_wayland_clipboard(data: bytes) -> subprocess.Popen[bytes] | None:
    try:
        process = subprocess.Popen(
            ["/usr/bin/wl-copy", "--foreground", "--type", "text/plain"],
            stdin=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        assert process.stdin is not None
        process.stdin.write(data)
        process.stdin.close()
    except (BrokenPipeError, OSError):
        return None

    return process


def stabilize_wayland_clipboard(
    data: bytes,
    *,
    attempts: int = 3,
    settle_time: float = 0.15,
) -> subprocess.Popen[bytes] | None:
    for _ in range(attempts):
        process = publish_wayland_clipboard(data)
        if process is None:
            continue
        time.sleep(settle_time)
        if process.poll() is None:
            return process

    return None


def main() -> int:
    x11 = ctypes.CDLL(find_library("X11"), use_errno=True)
    xfixes = ctypes.CDLL(find_library("Xfixes"), use_errno=True)

    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
    x11.XDefaultRootWindow.restype = ctypes.c_ulong
    x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
    x11.XInternAtom.restype = ctypes.c_ulong
    x11.XNextEvent.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    x11.XNextEvent.restype = ctypes.c_int
    x11.XFlush.argtypes = [ctypes.c_void_p]
    xfixes.XFixesSelectSelectionInput.argtypes = [
        ctypes.c_void_p,
        ctypes.c_ulong,
        ctypes.c_ulong,
        ctypes.c_ulong,
    ]

    connection = x11.XOpenDisplay(None)
    if not connection:
        return 1

    root = x11.XDefaultRootWindow(connection)
    clipboard = x11.XInternAtom(connection, b"CLIPBOARD", 0)
    xfixes.XFixesSelectSelectionInput(
        connection,
        root,
        clipboard,
        XFIXES_SET_SELECTION_OWNER_NOTIFY_MASK,
    )
    x11.XFlush(connection)

    previous = read_x11_clipboard()
    if previous:
        store_clipboard_data(previous)

    wayland_owner = None
    event = (ctypes.c_long * 24)()
    while True:
        x11.XNextEvent(connection, ctypes.byref(event))
        current = read_x11_clipboard()
        if current and current != previous:
            if wayland_owner is not None:
                wayland_owner.poll()
            # XWayland can revoke the first replacement while transferring ownership.
            wayland_owner = stabilize_wayland_clipboard(current)
            store_clipboard_data(current)
        previous = current


if __name__ == "__main__":
    raise SystemExit(main())
