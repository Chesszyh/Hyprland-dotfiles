#!/usr/bin/env python3
"""Read-only data collectors for the Quickshell workbench."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


BASE_DIR = Path(__file__).resolve().parents[1]
CONFIG_PATH = BASE_DIR / "config" / "workbench.json"
DEFAULT_CONFIG = {
    "repo_roots": [],
    "ssh_hosts": [],
}
MAX_REPOS = 80
MAX_WALK_DIRS = 4000
PRUNE_DIR_NAMES = {
    ".git",
    ".cache",
    ".local",
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    ".cargo",
    "target",
    ".superpowers",
    "worktrees",
    ".worktrees",
    "site",
    "dist",
    "build",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def envelope(
    topic: str,
    items: list[dict[str, Any]] | None = None,
    *,
    summary: dict[str, Any] | None = None,
    warnings: list[str] | None = None,
    ok: bool = True,
) -> dict[str, Any]:
    return {
        "ok": bool(ok),
        "topic": topic,
        "updated_at": utc_now(),
        "summary": summary or {},
        "warnings": warnings or [],
        "items": items or [],
    }


def load_config() -> dict[str, Any]:
    try:
        with CONFIG_PATH.open("r", encoding="utf-8") as handle:
            loaded = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return dict(DEFAULT_CONFIG)

    config = dict(DEFAULT_CONFIG)
    if isinstance(loaded, dict):
        if isinstance(loaded.get("repo_roots"), list):
            config["repo_roots"] = [str(item) for item in loaded["repo_roots"]]
        if isinstance(loaded.get("ssh_hosts"), list):
            config["ssh_hosts"] = loaded["ssh_hosts"]
    return config


def run_json_command(command: list[str], warnings: list[str], label: str) -> Any | None:
    exe = command[0]
    if shutil.which(exe) is None:
        warnings.append(f"{label}: command not found: {exe}")
        return None
    try:
        completed = subprocess.run(
            command,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=8,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        warnings.append(f"{label}: {exc}")
        return None

    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip() or f"exit {completed.returncode}"
        warnings.append(f"{label}: {detail}")
        return None
    try:
        return json.loads(completed.stdout or "{}")
    except json.JSONDecodeError as exc:
        warnings.append(f"{label}: invalid json: {exc}")
        return None


def run_text_command(command: list[str], warnings: list[str], label: str, *, timeout: int = 8) -> str | None:
    exe = command[0]
    if shutil.which(exe) is None:
        warnings.append(f"{label}: command not found: {exe}")
        return None
    try:
        completed = subprocess.run(
            command,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        warnings.append(f"{label}: {exc}")
        return None

    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip() or f"exit {completed.returncode}"
        warnings.append(f"{label}: {detail}")
        return None
    return completed.stdout


def parse_git_status(status: str) -> dict[str, Any]:
    lines = status.splitlines()
    header = lines[0] if lines else "## unknown"
    payload = header[3:] if header.startswith("## ") else header
    branch_part, _, bracket = payload.partition(" [")
    branch = branch_part
    upstream = None
    ahead = 0
    behind = 0

    if "..." in branch_part:
        branch, upstream = branch_part.split("...", 1)
    branch = branch.strip() or "unknown"
    upstream = upstream.strip() if upstream else None

    if bracket:
        bracket = bracket.rstrip("]")
        ahead_match = re.search(r"ahead (\d+)", bracket)
        behind_match = re.search(r"behind (\d+)", bracket)
        if ahead_match:
            ahead = int(ahead_match.group(1))
        if behind_match:
            behind = int(behind_match.group(1))

    dirty_count = sum(1 for line in lines[1:] if line.strip())
    return {
        "branch": branch,
        "upstream": upstream,
        "ahead": ahead,
        "behind": behind,
        "dirty_count": dirty_count,
        "clean": dirty_count == 0,
    }


def find_git_repos(
    roots: list[str],
    warnings: list[str],
    *,
    max_dirs: int = MAX_WALK_DIRS,
    max_repos: int = MAX_REPOS,
) -> list[Path]:
    repos: list[Path] = []
    seen: set[Path] = set()
    walked_dirs = 0

    for root_text in roots:
        root = Path(os.path.expanduser(root_text))
        if not root.exists():
            warnings.append(f"repos: missing root: {root}")
            continue
        for current, dirs, _files in os.walk(root):
            walked_dirs += 1
            path = Path(current)
            if (path / ".git").is_dir() or (path / ".git").is_file():
                resolved = path.resolve()
                if resolved not in seen:
                    seen.add(resolved)
                    repos.append(resolved)
                dirs[:] = []
                if len(repos) >= max_repos:
                    warnings.append(f"repos: capped at {max_repos} repositories")
                    return sorted(repos)
                continue

            dirs[:] = [name for name in dirs if name not in PRUNE_DIR_NAMES]
            if walked_dirs >= max_dirs:
                warnings.append(f"repos: scanned directory cap reached at {max_dirs}")
                return sorted(repos)
    return sorted(repos)


def collect_repos(config: dict[str, Any]) -> dict[str, Any]:
    warnings: list[str] = []
    items: list[dict[str, Any]] = []
    for repo in find_git_repos(config.get("repo_roots", []), warnings):
        status_text = run_text_command(
            ["git", "-C", str(repo), "status", "--porcelain=v1", "-b"],
            warnings,
            f"repos:{repo}",
        )
        if status_text is None:
            continue
        parsed = parse_git_status(status_text or "")
        items.append(
            {
                "name": repo.name,
                "path": str(repo),
                "branch": parsed["branch"],
                "upstream": parsed["upstream"],
                "ahead": parsed["ahead"],
                "behind": parsed["behind"],
                "dirty_count": parsed["dirty_count"],
                "clean": parsed["clean"],
            }
        )
    summary = {
        "count": len(items),
        "dirty": sum(1 for item in items if item["dirty_count"]),
        "with_upstream_changes": sum(1 for item in items if item["ahead"] or item["behind"]),
    }
    return envelope("repos", items, summary=summary, warnings=warnings)


def agent_root_items() -> list[dict[str, Any]]:
    codex_root = Path.home() / ".codex"
    claude_root = Path.home() / ".claude"
    return [
        {"kind": "session_root", "name": "codex", "path": str(codex_root), "exists": codex_root.exists()},
        {"kind": "session_root", "name": "claude", "path": str(claude_root), "exists": claude_root.exists()},
        {"kind": "session_root", "name": "quickshell", "path": str(BASE_DIR), "exists": BASE_DIR.exists()},
    ]


def tailscale_peer(peer_id: str, raw: dict[str, Any], *, self_peer: bool = False) -> dict[str, Any]:
    return {
        "id": peer_id,
        "host": raw.get("HostName") or raw.get("DNSName") or peer_id,
        "ips": raw.get("TailscaleIPs") or [],
        "os": raw.get("OS"),
        "online": bool(raw.get("Online")),
        "last_seen": raw.get("LastSeen"),
        "self": self_peer,
    }


def parse_tailscale_status(payload: dict[str, Any]) -> dict[str, Any]:
    peers: list[dict[str, Any]] = []
    if isinstance(payload.get("Self"), dict):
        peers.append(tailscale_peer("self", payload["Self"], self_peer=True))

    raw_peers = payload.get("Peer") if isinstance(payload.get("Peer"), dict) else {}
    for peer_id, raw in raw_peers.items():
        if isinstance(raw, dict):
            peers.append(tailscale_peer(str(peer_id), raw))

    online = sum(1 for peer in peers if peer["online"])
    offline = len(peers) - online
    exit_node = payload.get("ExitNodeStatus") if isinstance(payload.get("ExitNodeStatus"), dict) else {}
    return {
        "summary": {
            "total": len(peers),
            "online": online,
            "offline": offline,
            "exit_node_id": exit_node.get("ID"),
            "exit_node_online": exit_node.get("Online"),
        },
        "peers": peers,
    }


def normalize_ssh_host(raw: Any) -> dict[str, Any]:
    if isinstance(raw, dict):
        return {
            "host": raw.get("host") or raw.get("name") or raw.get("hostname"),
            "user": raw.get("user"),
            "port": raw.get("port", 22),
            "label": raw.get("label"),
        }
    return {"host": str(raw), "user": None, "port": 22, "label": None}


def collect_network(config: dict[str, Any]) -> dict[str, Any]:
    warnings: list[str] = []
    items: list[dict[str, Any]] = []
    tailscale = run_json_command(["tailscale", "status", "--json"], warnings, "tailscale")
    tailscale_summary: dict[str, Any] = {}
    if isinstance(tailscale, dict):
        parsed = parse_tailscale_status(tailscale)
        tailscale_summary = parsed["summary"]
        for peer in parsed["peers"]:
            item = dict(peer)
            item["kind"] = "tailscale"
            items.append(item)

    for host in config.get("ssh_hosts", []):
        normalized = normalize_ssh_host(host)
        normalized["kind"] = "ssh"
        items.append(normalized)

    summary = {
        "tailscale": tailscale_summary,
        "ssh_hosts": sum(1 for item in items if item.get("kind") == "ssh"),
        "count": len(items),
    }
    return envelope("network", items, summary=summary, warnings=warnings)


def parse_witr_result(payload: Any, port: str) -> dict[str, Any]:
    candidates: list[Any]
    if isinstance(payload, dict):
        candidates = payload.get("results") or payload.get("items") or payload.get("listeners") or [payload]
    elif isinstance(payload, list):
        candidates = payload
    else:
        candidates = []

    selected: dict[str, Any] = {}
    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        candidate_port = str(candidate.get("port") or candidate.get("local_port") or port)
        if candidate_port == str(port):
            selected = candidate
            break
    if not selected and candidates and isinstance(candidates[0], dict):
        selected = candidates[0]

    process = selected.get("process") if isinstance(selected.get("process"), dict) else selected
    return {
        "port": str(selected.get("port") or port),
        "process": {
            "pid": process.get("pid"),
            "name": process.get("name") or process.get("command"),
            "cmdline": process.get("cmdline") or process.get("cmd"),
            "cwd": process.get("cwd"),
        },
    }


def collect_docker(warnings: list[str]) -> list[dict[str, Any]]:
    output = run_text_command(["docker", "ps", "--format", "{{json .}}"], warnings, "docker")
    if output is None:
        return []
    containers: list[dict[str, Any]] = []
    for line in output.splitlines():
        if not line.strip():
            continue
        try:
            raw = json.loads(line)
        except json.JSONDecodeError as exc:
            warnings.append(f"docker: invalid json line: {exc}")
            continue
        containers.append(
            {
                "kind": "docker",
                "id": raw.get("ID"),
                "name": raw.get("Names"),
                "image": raw.get("Image"),
                "status": raw.get("Status"),
                "ports": raw.get("Ports"),
            }
        )
    return containers


def collect_runtime(config: dict[str, Any], *, port: str | None = None) -> dict[str, Any]:
    del config
    warnings: list[str] = []
    items = collect_docker(warnings)
    if port:
        payload = run_json_command(["witr", "--port", str(port), "--json"], warnings, "witr")
        if payload is not None:
            parsed = parse_witr_result(payload, str(port))
            parsed["kind"] = "port"
            items.append(parsed)
    summary = {
        "docker_containers": sum(1 for item in items if item.get("kind") == "docker"),
        "ports": sum(1 for item in items if item.get("kind") == "port"),
        "count": len(items),
    }
    return envelope("runtime", items, summary=summary, warnings=warnings)


def collect_agents(config: dict[str, Any]) -> dict[str, Any]:
    del config
    warnings: list[str] = []
    items = agent_root_items()

    tmux = run_text_command(["tmux", "list-sessions", "-F", "#{session_name}\t#{session_windows}\t#{session_attached}"], warnings, "tmux")
    if tmux:
        for line in tmux.splitlines():
            name, windows, attached = (line.split("\t") + ["", "", ""])[:3]
            items.append({"kind": "tmux", "name": name, "windows": windows, "attached": attached})

    zellij = run_text_command(["zellij", "list-sessions", "--no-formatting"], warnings, "zellij")
    if zellij:
        for line in zellij.splitlines():
            name = line.strip()
            if name:
                items.append({"kind": "zellij", "name": name})

    summary = {
        "session_roots": sum(1 for item in items if item.get("kind") == "session_root"),
        "tmux_sessions": sum(1 for item in items if item.get("kind") == "tmux"),
        "zellij_sessions": sum(1 for item in items if item.get("kind") == "zellij"),
        "count": len(items),
    }
    return envelope("agents", items, summary=summary, warnings=warnings)


def collect_commands(config: dict[str, Any]) -> dict[str, Any]:
    del config
    items = [
        {
            "id": "quickshell-reload",
            "label": "Reload Quickshell",
            "command": ["qs", "reload"],
            "category": "shell",
            "destructive": False,
        },
        {
            "id": "hypr-reload",
            "label": "Reload Hyprland",
            "command": ["hyprctl", "reload"],
            "category": "window-manager",
            "destructive": False,
        },
        {
            "id": "dark-angel-theme-dark",
            "label": "Apply Dark Angel Abyss",
            "command": [str(BASE_DIR / "scripts" / "dark-angel-theme.py"), "dark"],
            "category": "theme",
            "destructive": False,
        },
        {
            "id": "dark-angel-theme-light",
            "label": "Apply Dark Angel Ashen",
            "command": [str(BASE_DIR / "scripts" / "dark-angel-theme.py"), "light"],
            "category": "theme",
            "destructive": False,
        },
    ]
    summary = {"count": len(items), "categories": sorted({item["category"] for item in items})}
    return envelope("commands", items, summary=summary)


def collect_visual(config: dict[str, Any]) -> dict[str, Any]:
    del config
    tools = [
        {
            "name": "cava",
            "kind": "audio_visualizer",
            "label": "CAVA audio visualizer",
            "command": "cava",
        },
        {
            "name": "pipes.sh",
            "kind": "terminal_animation",
            "label": "pipes.sh terminal animation",
            "command": "pipes.sh",
        },
    ]
    items: list[dict[str, Any]] = []
    for tool in tools:
        path = shutil.which(tool["command"])
        item = dict(tool)
        item["available"] = path is not None
        item["path"] = path
        items.append(item)

    summary = {
        "count": len(items),
        "available": sum(1 for item in items if item["available"]),
        "animation": "available" if any(item["available"] for item in items) else "unavailable",
    }
    return envelope("visual", items, summary=summary)


def cheap_search_items(config: dict[str, Any]) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    for item in agent_root_items():
        indexed = dict(item)
        indexed["source_topic"] = "agents"
        items.append(indexed)

    for item in collect_commands(config)["items"]:
        indexed = dict(item)
        indexed["source_topic"] = "commands"
        items.append(indexed)

    for root in config.get("repo_roots", []):
        items.append(
            {
                "kind": "repo_root",
                "name": Path(str(root)).name,
                "path": str(root),
                "source_topic": "repos",
            }
        )

    for host in config.get("ssh_hosts", []):
        indexed = normalize_ssh_host(host)
        indexed["kind"] = "ssh"
        indexed["source_topic"] = "network"
        items.append(indexed)

    items.append({"kind": "network_tool", "name": "tailscale", "source_topic": "network"})
    return items


def collect_search(config: dict[str, Any], *, query: str = "", port: str | None = None) -> dict[str, Any]:
    del port
    haystack = query.casefold()
    items: list[dict[str, Any]] = []
    for item in cheap_search_items(config):
        text = json.dumps(item, ensure_ascii=False, sort_keys=True).casefold()
        if not haystack or haystack in text:
            items.append(item)
    summary = {"query": query, "count": len(items), "mode": "static"}
    return envelope("search", items, summary=summary)


def collect_topic(topic: str, config: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    if topic == "agents":
        return collect_agents(config)
    if topic == "repos":
        return collect_repos(config)
    if topic == "network":
        return collect_network(config)
    if topic == "runtime":
        return collect_runtime(config, port=args.port)
    if topic == "visual":
        return collect_visual(config)
    if topic == "commands":
        return collect_commands(config)
    if topic == "search":
        return collect_search(config, query=args.query or args.search_query or "", port=args.port)
    return envelope(topic, ok=False, warnings=[f"unknown topic: {topic}"])


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Quickshell workbench read-only data collector")
    parser.add_argument("topic", choices=["agents", "repos", "network", "runtime", "visual", "commands", "search"])
    parser.add_argument("search_query", nargs="?", help="query text for positional search form")
    parser.add_argument("--port", help="port to inspect for runtime/search")
    parser.add_argument("--query", "-q", default="", help="query text for search")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.search_query and args.topic != "search":
        parser.error("positional query is only valid for the search topic")
    result = collect_topic(args.topic, load_config(), args)
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
