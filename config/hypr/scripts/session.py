#!/usr/bin/env python3
"""Save and restore applications and their workspaces."""
from collections import Counter
from datetime import datetime
import fcntl
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import time

SESSION_DIR = Path.home() / ".config/hypr/sessions"
MINIMIZED_DIR = Path.home() / ".cache/hypr/minimized"
COMMANDS = {
    "google-chrome": "google-chrome", "Google-chrome": "google-chrome",
    "firefox": "firefox", "code": "code", "Code": "code", "kitty": "kitty",
    "Chatgpt": "chatgpt", "chatgpt": "chatgpt",
    "thunar": "thunar", "org.gnome.Nautilus": "nautilus",
    "org.gnome.Evince": "evince", "org.gnome.Ptyxis": "ptyxis",
    "osu!": str(Path.home() / "Applications/osu.AppImage"),
}
FLATPAKS = {"qq": "com.qq.QQ", "wechat": "com.tencent.WeChat"}


def query(name):
    return json.loads(subprocess.check_output(["hyprctl", "-j", name], text=True, timeout=5))


def dispatch(expression):
    result = subprocess.check_output(["hyprctl", "dispatch", expression], text=True, timeout=5).strip()
    if result != "ok":
        raise RuntimeError(result)


def notify(message):
    subprocess.run(["notify-send", "会话", message], check=False)


def log(message):
    with (SESSION_DIR / "session.log").open("a") as file:
        file.write(f"[{datetime.now().isoformat(timespec='seconds')}] {message}\n")


def save_session(mode="auto"):
    clients = query("clients")
    if not isinstance(clients, list):
        raise ValueError("Hyprland 未返回窗口列表")
    saved = []
    for client in clients:
        workspace = client["workspace"]
        if workspace["name"] == "special:scratchpad":
            continue
        if workspace["name"] == "special:minimized":
            cached = MINIMIZED_DIR / (client["address"] + ".json")
            if not cached.exists():
                continue
            workspace = json.loads(cached.read_text())["workspace"]
        if workspace["id"] > 0:
            saved.append({"class": client["class"], "workspace": workspace})
    # Shutdown may leave a responsive compositor with no windows; preserve the last session.
    if not saved and mode == "auto":
        return 0
    data = {"timestamp": datetime.now().astimezone().isoformat(timespec="seconds"),
            "active_workspace": query("activeworkspace"), "clients": saved}
    data["active_workspace"] = {k: data["active_workspace"][k] for k in ("id", "name")}
    target = SESSION_DIR / "last_session.json"
    temporary = SESSION_DIR / "last_session.tmp"
    temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    temporary.chmod(0o600)
    backups = SESSION_DIR / "backups"
    backups.mkdir(exist_ok=True)
    if target.exists():
        backup = backups / ("session_" + datetime.now().strftime("%Y%m%d_%H%M%S_%f") + ".json")
        shutil.copy2(target, backup)
        for old in sorted(backups.glob("session_*.json"))[:-10]:
            old.unlink()
    temporary.replace(target)
    log(f"Saved {len(saved)} application windows ({mode})")
    if mode == "manual":
        notify(f"已保存 {len(saved)} 个应用窗口及工作区")
    return len(saved)


def command_for(app):
    if app.lower() in FLATPAKS:
        return ["flatpak", "run", FLATPAKS[app.lower()]]
    command = COMMANDS.get(app, app.lower())
    return [command] if shutil.which(command) else None


def move_to_workspace(client, workspace):
    if client["workspace"]["id"] != workspace:
        selector = json.dumps("address:" + client["address"])
        dispatch(f"hl.dsp.window.move({{ window = {selector}, workspace = {workspace}, follow = false }})")


def restore_session():
    target = SESSION_DIR / "last_session.json"
    if not target.exists():
        notify("尚无已保存的会话")
        return {"existing": 0, "opened": 0, "skipped": 0}
    data = json.loads(target.read_text())
    original = query("activewindow")
    used = set()
    result = Counter(existing=0, opened=0, skipped=0)
    for saved in data["clients"]:
        workspace = saved["workspace"]["id"]
        if workspace <= 0:
            result["skipped"] += 1
            continue
        app = saved["class"]
        clients = query("clients")
        matches = [c for c in clients if c["class"].lower() == app.lower() and c["address"] not in used]
        if matches:
            client = min(matches, key=lambda c: c["workspace"]["id"] != workspace)
            move_to_workspace(client, workspace)
            used.add(client["address"])
            result["existing"] += 1
            continue
        command = command_for(app)
        if not command:
            result["skipped"] += 1
            log(f"No launcher for class {app}")
            continue
        before = {c["address"] for c in clients}
        dispatch(f"hl.dsp.exec_cmd({json.dumps(shlex.join(command))}, {{ workspace = '{workspace} silent' }})")
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            matches = [c for c in query("clients") if c["address"] not in before and c["class"].lower() == app.lower()]
            if matches:
                client = matches[0]
                move_to_workspace(client, workspace)
                used.add(client["address"])
                result["opened"] += 1
                break
            time.sleep(0.2)
        else:
            result["skipped"] += 1
            log(f"No new window observed for class {app}")
    if original.get("address") in {c["address"] for c in query("clients")}:
        dispatch(f"hl.dsp.focus({{ window = {json.dumps('address:' + original['address'])} }})")
    log(f"Restore: existing={result['existing']} opened={result['opened']} skipped={result['skipped']}")
    notify(f"复用 {result['existing']} 个，打开 {result['opened']} 个，未恢复 {result['skipped']} 个")
    return dict(result)


def main():
    SESSION_DIR.mkdir(parents=True, exist_ok=True)
    action = sys.argv[1]
    with (SESSION_DIR / ".session.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            if action == "save":
                save_session(sys.argv[2] if len(sys.argv) > 2 else "auto")
            elif action == "restore":
                restore_session()
        except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
            log(f"{action} failed: {type(error).__name__}")
            print(f"会话{action}失败：{error}", file=sys.stderr)
            if action == "restore" or "manual" in sys.argv:
                notify("操作失败，已保留原有会话记录")
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
