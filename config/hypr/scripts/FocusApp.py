#!/usr/bin/env python3
import json
import subprocess
import sys


def main():
    app = sys.argv[1]
    classes = {"qq": {"qq"}, "chatgpt": {"chatgpt"}}[app]
    clients = json.loads(subprocess.check_output(["hyprctl", "-j", "clients"], text=True))
    matches = [c for c in clients if c["class"].lower() in classes]
    if not matches:
        subprocess.run(["notify-send", "窗口未打开", f"请先打开 {app}"])
        return
    window = min(matches, key=lambda c: c.get("focusHistoryID", 9999))
    selector = json.dumps("address:" + window["address"])
    subprocess.run(["hyprctl", "dispatch", f"hl.dsp.focus({{ window = {selector} }})"], check=True)


if __name__ == "__main__":
    main()
