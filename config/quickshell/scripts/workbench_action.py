#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path


THEME_SCRIPT = str(Path.home() / ".config/hypr/UserScripts/DarkAngelApply.sh")


def _require_args(action, args, count, usage):
    if len(args) != count:
        raise SystemExit(f"{action} requires {usage}")


def build_command(action, args):
    if action == "reload-hyprland":
        _require_args(action, args, 0, "no arguments")
        return ["hyprctl", "-i", "0", "reload"]
    if action == "restart-quickshell":
        _require_args(action, args, 0, "no arguments")
        return ["systemctl", "--user", "restart", "qs.service"]
    if action == "restart-waybar":
        _require_args(action, args, 0, "no arguments")
        return ["sh", "-lc", "pkill -x waybar || true; setsid waybar >/tmp/waybar.log 2>&1 < /dev/null &"]
    if action == "theme-light":
        _require_args(action, args, 0, "no arguments")
        return [THEME_SCRIPT, "light"]
    if action == "theme-dark":
        _require_args(action, args, 0, "no arguments")
        return [THEME_SCRIPT, "dark"]
    if action == "open-repo":
        _require_args(action, args, 1, "<path>")
        return ["kitty", "--working-directory", os.path.expanduser(args[0])]
    if action == "ssh":
        _require_args(action, args, 1, "<target>")
        return ["kitty", "ssh", args[0]]
    if action == "tailscale-use-exit":
        _require_args(action, args, 1, "<node>")
        return ["tailscale", "set", "--exit-node", args[0]]
    if action == "tailscale-clear-exit":
        _require_args(action, args, 0, "no arguments")
        return ["tailscale", "set", "--exit-node", ""]
    if action == "open-url":
        _require_args(action, args, 1, "<url>")
        return ["xdg-open", args[0]]
    if action == "kill-pid":
        if len(args) != 2 or args[1] != "--confirm":
            raise SystemExit("kill-pid requires <numeric-pid> --confirm")
        if not args[0].isdigit():
            raise SystemExit("kill-pid requires <numeric-pid> --confirm")
        return ["kill", args[0]]

    raise SystemExit(f"unknown action: {action}")


def _json_print(payload):
    print(json.dumps(payload, ensure_ascii=False))


def _parse_argv(argv):
    dry_run = False
    remaining = []
    for item in argv:
        if item == "--dry-run":
            dry_run = True
        else:
            remaining.append(item)

    if not remaining:
        raise SystemExit("action is required")

    return remaining[0], remaining[1:], dry_run


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    try:
        action, args, dry_run = _parse_argv(argv)
        command = build_command(action, args)
    except SystemExit as exc:
        message = str(exc) or "invalid action"
        _json_print({"ok": False, "error": message})
        return 2

    if dry_run:
        _json_print({"ok": True, "dry_run": True, "action": action, "command": command})
        return 0

    try:
        completed = subprocess.run(command, capture_output=True, text=True, timeout=15, check=False)
        _json_print(
            {
                "ok": completed.returncode == 0,
                "returncode": completed.returncode,
                "stdout": completed.stdout,
                "stderr": completed.stderr,
            }
        )
        return 0 if completed.returncode == 0 else completed.returncode
    except Exception as exc:
        _json_print({"ok": False, "returncode": 127, "stdout": "", "stderr": str(exc)})
        return 127


if __name__ == "__main__":
    raise SystemExit(main())
