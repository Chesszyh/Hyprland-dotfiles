#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
import os
import shutil
import shlex
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import TextIO

ROFI_CONFIG = Path.home() / ".config" / "rofi" / "config.rasi"
USER_APPS = Path.home() / ".local" / "share" / "applications"
SCRIPT_MODE_NAME = "Apps"
SCRIPT_MODES = ("run", "filebrowser", "window")
ROFI_CUSTOM_DELETE = 10
ROFI_CUSTOM_COPY = 11
ROFI_CUSTOM_EDIT = 12
HEAVY_PLACEHOLDERS = {"%f", "%F", "%u", "%U", "%i", "%c", "%k", "%v", "%m"}
DEVNULL: TextIO = subprocess.DEVNULL


@dataclass
class DesktopEntry:
    desktop_id: str
    path: Path
    name: str
    exec_line: str
    icon: str
    terminal: bool
    hidden: bool
    no_display: bool
    type_name: str


def app_dirs() -> list[Path]:
    dirs = [USER_APPS]
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    for data_dir in data_dirs.split(":"):
        if data_dir:
            dirs.append(Path(data_dir) / "applications")
    flatpak_user = Path.home() / ".local" / "share" / "flatpak" / "exports" / "share" / "applications"
    flatpak_system = Path("/var/lib/flatpak/exports/share/applications")
    for flatpak_dir in (flatpak_user, flatpak_system):
        if flatpak_dir not in dirs:
            dirs.append(flatpak_dir)
    return [path for path in dirs if path.exists()]


def desktop_id_for(path: Path, base: Path) -> str:
    try:
        return str(path.relative_to(base)).replace("/", "-")
    except ValueError:
        return path.name


def parse_desktop(path: Path, desktop_id: str) -> DesktopEntry | None:
    values: dict[str, str] = {}
    in_entry = False
    try:
        for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw.strip()
            if line == "[Desktop Entry]":
                in_entry = True
                continue
            if line.startswith("[") and line.endswith("]") and in_entry:
                break
            if not in_entry or not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            values.setdefault(key.strip(), value.strip())
    except OSError:
        return None

    name = values.get("Name") or values.get("Name[en_US]") or path.stem
    return DesktopEntry(
        desktop_id=desktop_id,
        path=path,
        name=name,
        exec_line=values.get("Exec", ""),
        icon=values.get("Icon", "application-x-executable"),
        terminal=values.get("Terminal", "false").lower() == "true",
        hidden=values.get("Hidden", "false").lower() == "true",
        no_display=values.get("NoDisplay", "false").lower() == "true",
        type_name=values.get("Type", "Application"),
    )


def load_entries(include_hidden: bool = False) -> list[DesktopEntry]:
    entries: list[DesktopEntry] = []
    seen: set[str] = set()
    for base in app_dirs():
        for path in sorted(base.rglob("*.desktop")):
            desktop_id = desktop_id_for(path, base)
            if desktop_id in seen:
                continue
            seen.add(desktop_id)
            entry = parse_desktop(path, desktop_id)
            if entry is None:
                continue
            if not include_hidden and (entry.hidden or entry.no_display or entry.type_name != "Application"):
                continue
            entries.append(entry)
    return entries


def strip_field_codes(exec_line: str) -> list[str]:
    cleaned = exec_line
    for code in HEAVY_PLACEHOLDERS:
        cleaned = cleaned.replace(code, "")
    cleaned = cleaned.replace("%%", "%")
    try:
        return [part for part in shlex.split(cleaned) if part]
    except ValueError:
        return []


def command_from_exec(exec_line: str) -> str:
    parts = strip_field_codes(exec_line)
    if not parts:
        return ""
    index = 0
    if parts[index] == "env":
        index += 1
        while index < len(parts) and "=" in parts[index] and not parts[index].startswith("-"):
            index += 1
    if index >= len(parts):
        return ""
    return parts[index]


def command_valid(command: str) -> bool:
    if not command:
        return False
    expanded = os.path.expanduser(command)
    if "/" in expanded:
        return os.path.isfile(expanded) and os.access(expanded, os.X_OK)
    return shutil.which(expanded) is not None


def invalid_reason(entry: DesktopEntry) -> str | None:
    if entry.type_name != "Application":
        return "not an Application desktop entry"
    if entry.hidden or entry.no_display:
        return None
    command = command_from_exec(entry.exec_line)
    if not command:
        return "missing or unparsable Exec"
    if not command_valid(command):
        return f"missing command: {command}"
    return None


def source_label(path: Path) -> str:
    home = str(Path.home())
    text = str(path)
    if text.startswith(home + "/"):
        return "~/" + text[len(home) + 1 :]
    return text


def source_display_label(path: Path) -> str:
    parent = source_label(path.parent)
    return f"{path.name} @ {parent}"


def display_markup(entry: DesktopEntry) -> str:
    name = html.escape(entry.name)
    source = html.escape(source_display_label(entry.path))
    return f"<b>{name}</b> <span size=\"smaller\" alpha=\"72%\">{source}</span>"


def script_row(entry: DesktopEntry) -> str:
    search_meta = html.escape(f"{entry.name} {entry.desktop_id} {source_label(entry.path)}")
    return (
        f"{entry.desktop_id}"
        f"\0display\x1f{display_markup(entry)}"
        f"\x1ficon\x1f{entry.icon}"
        f"\x1fmeta\x1f{search_meta}"
        f"\x1finfo\x1f{entry.desktop_id}"
    )


def script_payload(
    entries: list[DesktopEntry],
    message: str | None = None,
    *,
    keep_selection: bool = False,
    keep_filter: bool = False,
    new_selection: int | None = None,
) -> str:
    lines = [
        "\0prompt\x1fApps",
        "\0markup-rows\x1ftrue",
        "\0no-custom\x1ftrue",
        "\0use-hot-keys\x1ftrue",
    ]
    if message:
        lines.append(f"\0message\x1f{html.escape(message)}")
    if keep_selection:
        lines.append("\0keep-selection\x1ftrue")
    if keep_filter:
        lines.append("\0keep-filter\x1ftrue")
    if new_selection is not None:
        lines.append(f"\0new-selection\x1f{new_selection}")
    lines.extend(script_row(entry) for entry in entries)
    return "\n".join(lines) + "\n"


def valid_entries() -> list[DesktopEntry]:
    return [entry for entry in load_entries() if invalid_reason(entry) is None]


def entry_index(entries: list[DesktopEntry], desktop_id: str | None) -> int | None:
    if not desktop_id:
        return None
    for index, entry in enumerate(entries):
        if entry.desktop_id == desktop_id:
            return index
    return None


def find_entry(entries: list[DesktopEntry], desktop_id: str | None) -> DesktopEntry | None:
    index = entry_index(entries, desktop_id)
    if index is None:
        return None
    return entries[index]


def notify(summary: str, body: str = "") -> None:
    notify_send = shutil.which("notify-send")
    if not notify_send:
        return

    spawn_detached([notify_send, summary, body])


def spawn_detached(command: list[str]) -> None:
    subprocess.Popen(
        command,
        stdin=DEVNULL,
        stdout=DEVNULL,
        stderr=DEVNULL,
        start_new_session=True,
        close_fds=True,
    )


def launch_entry(entry: DesktopEntry) -> tuple[bool, str]:
    reason = invalid_reason(entry)
    if reason:
        return False, f"{entry.name}: {reason}"

    gtk_id = entry.desktop_id[:-8] if entry.desktop_id.endswith(".desktop") else entry.desktop_id
    gtk = shutil.which("gtk-launch")
    if gtk:
        result = subprocess.run([gtk, gtk_id], check=False, stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
        if result.returncode == 0:
            return True, f"Launched {entry.name}"

    parts = strip_field_codes(entry.exec_line)
    if not parts:
        return False, f"{entry.name}: missing or unparsable Exec"
    if entry.terminal:
        parts = ["kitty", "-e", *parts]
    spawn_detached(parts)
    return True, f"Launched {entry.name}"


def delete_entry(entry: DesktopEntry) -> tuple[bool, str]:
    try:
        entry.path.unlink()
        return True, f"Deleted {source_label(entry.path)}"
    except FileNotFoundError:
        return False, f"Already missing: {source_label(entry.path)}"
    except PermissionError:
        return False, f"Permission denied: {source_label(entry.path)}"
    except OSError as exc:
        return False, f"Delete failed: {source_label(entry.path)} ({exc})"


def copy_to_clipboard(text: str) -> bool:
    clipboard_tools = (
        ([shutil.which("wl-copy")], text),
        ([shutil.which("xclip"), "-selection", "clipboard"], text),
        ([shutil.which("xsel"), "--clipboard", "--input"], text),
    )
    for command, payload in clipboard_tools:
        if not command[0]:
            continue
        subprocess.run(command, input=payload, text=True, check=False)
        return True
    return False


def edit_entry(entry: DesktopEntry) -> None:
    spawn_detached(["kitty", "-e", "nvim", str(entry.path)])


def selected_desktop_id(argv: list[str]) -> str | None:
    info = os.environ.get("ROFI_INFO")
    if info:
        return info
    if len(argv) > 1 and argv[1]:
        return argv[1]
    return None


def selection_after_delete(index: int | None, count: int) -> int | None:
    if index is None or count <= 0:
        return None
    return min(index, count - 1)


def script_mode(argv: list[str]) -> int:
    retv = int(os.environ.get("ROFI_RETV", "0"))
    desktop_id = selected_desktop_id(argv)
    entries = valid_entries()

    if retv == 0:
        print(
            script_payload(
                entries,
                "Enter launch | Delete remove | Ctrl+C copy path | Ctrl+E edit | Alt+Left/Right mode",
                keep_selection=True,
                keep_filter=True,
            ),
            end="",
        )
        return 0

    entry = find_entry(entries, desktop_id)
    if entry is None:
        print(
            script_payload(
                entries,
                "Selected launcher no longer exists. The list was refreshed.",
                keep_selection=False,
            ),
            end="",
        )
        return 0

    index = entry_index(entries, desktop_id)

    if retv == 1:
        ok, message = launch_entry(entry)
        if ok:
            return 0
        print(script_payload(entries, message, keep_selection=True, keep_filter=True, new_selection=index), end="")
        return 0

    if retv == ROFI_CUSTOM_DELETE:
        ok, message = delete_entry(entry)
        if ok:
            notify("Launcher deleted", source_label(entry.path))
        updated_entries = valid_entries()
        print(
            script_payload(
                updated_entries,
                message,
                keep_selection=True,
                keep_filter=True,
                new_selection=selection_after_delete(index, len(updated_entries)),
            ),
            end="",
        )
        return 0

    if retv == ROFI_CUSTOM_COPY:
        if copy_to_clipboard(str(entry.path)):
            notify("Launcher path copied", source_label(entry.path))
            message = f"Copied: {source_label(entry.path)}"
        else:
            message = "No clipboard tool found (expected wl-copy, xclip, or xsel)."
        print(script_payload(entries, message, keep_selection=True, keep_filter=True, new_selection=index), end="")
        return 0

    if retv == ROFI_CUSTOM_EDIT:
        edit_entry(entry)
        notify("Editing launcher", source_label(entry.path))
        print(
            script_payload(
                entries,
                f"Editing: {source_label(entry.path)}",
                keep_selection=True,
                keep_filter=True,
                new_selection=index,
            ),
            end="",
        )
        return 0

    print(script_payload(entries, keep_selection=True, keep_filter=True, new_selection=index), end="")
    return 0


def launcher_modes(script_path: Path) -> str:
    return ",".join((f"{SCRIPT_MODE_NAME}:{script_path}", *SCRIPT_MODES))


def build_rofi_command(script_path: Path) -> list[str]:
    return [
        "rofi",
        "-config",
        str(ROFI_CONFIG),
        "-show",
        SCRIPT_MODE_NAME,
        "-modes",
        launcher_modes(script_path),
        "-sidebar-mode",
        "-kb-custom-1",
        "Delete",
        "-kb-remove-char-forward",
        "",
        "-kb-custom-2",
        "Control+c",
        "-kb-secondary-copy",
        "",
        "-kb-custom-3",
        "Control+e",
        "-kb-move-end",
        "",
        "-kb-mode-next",
        "Alt+Right",
        "-kb-mode-previous",
        "Alt+Left",
        "-kb-row-left",
        "Left",
        "-kb-row-right",
        "Right",
        "-kb-move-char-back",
        "",
        "-kb-move-char-forward",
        "",
    ]


def run_launcher() -> int:
    command = build_rofi_command(Path(__file__).resolve())
    return subprocess.run(command, check=False).returncode


def clean_invalid(apply: bool) -> int:
    invalid = [(entry, invalid_reason(entry)) for entry in load_entries(include_hidden=False)]
    invalid = [(entry, reason) for entry, reason in invalid if reason]
    for entry, reason in invalid:
        print(f"{entry.desktop_id}\t{source_label(entry.path)}\t{reason}")
        if not apply:
            continue
        delete_entry(entry)
    return 1 if invalid and not apply else 0


def main(argv: list[str] | None = None) -> int:
    argv = argv or os.sys.argv
    if "ROFI_RETV" in os.environ:
        return script_mode(argv)

    parser = argparse.ArgumentParser()
    parser.add_argument("--clean", action="store_true", help="scan invalid launchers")
    parser.add_argument("--apply", action="store_true", help="apply cleanup by moving/hiding invalid launchers")
    args = parser.parse_args(argv[1:])

    if args.clean:
        return clean_invalid(args.apply)
    return run_launcher()


if __name__ == "__main__":
    raise SystemExit(main())
