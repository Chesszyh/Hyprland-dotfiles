#!/usr/bin/env bash
set -euo pipefail

state_dir="${KITTY_SESSION_STATE_DIR:-$HOME/.local/state/kitty-session}"
snapshot_root="$state_dir/snapshots"
session_file="$state_dir/last.session"
kitty_bin="${KITTY_BIN:-kitty}"
timestamp="${KITTY_SESSION_TIMESTAMP:-$(date +%Y%m%d_%H%M%S)}"
keep_count="${KITTY_SESSION_KEEP_COUNT:-10}"
keep_days="${KITTY_SESSION_KEEP_DAYS:-14}"

discover_kitty_to() {
    local current_user
    local socket_glob
    local candidates
    local candidate
    local newest=""

    if [[ -n "${KITTY_SESSION_TO:-}" ]]; then
        printf '%s\n' "$KITTY_SESSION_TO"
        return 0
    fi

    if [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
        printf '%s\n' "$KITTY_LISTEN_ON"
        return 0
    fi

    current_user="${USER:-$(id -un)}"
    socket_glob="${KITTY_SESSION_SOCKET_GLOB:-/tmp/kitty-session-$current_user-*}"
    mapfile -t candidates < <(compgen -G "$socket_glob" || true)

    for candidate in "${candidates[@]}"; do
        if [[ -n "${KITTY_SESSION_SOCKET_GLOB:-}" || -S "$candidate" ]]; then
            if [[ -z "$newest" || "$candidate" -nt "$newest" ]]; then
                newest="$candidate"
            fi
        fi
    done

    if [[ -n "$newest" ]]; then
        printf 'unix:%s\n' "$newest"
        return 0
    fi

    printf 'unix:/tmp/kitty-session-%s\n' "$current_user"
}

kitty_to="$(discover_kitty_to)"

sanitize_name() {
    local value="$1"
    local sanitized

    sanitized="$(printf '%s' "$value" | tr -cs 'A-Za-z0-9._-' '_' | sed 's/^_*//; s/_*$//')"
    printf '%s' "${sanitized:-window}"
}

save_session_file() {
    local tmp_file

    mkdir -p "$state_dir"
    tmp_file="$(mktemp "$state_dir/last.session.XXXXXX")"
    if ! "$kitty_bin" @ --to "$kitty_to" ls --output-format=session > "$tmp_file"; then
        rm -f "$tmp_file"
        printf 'Unable to reach kitty at %s\n' "$kitty_to" >&2
        return 1
    fi
    mv "$tmp_file" "$session_file"
}

save_text_snapshots() {
    local snapshot_dir="$snapshot_root/$timestamp"
    local windows
    local window_id
    local title
    local safe_title

    command -v jq >/dev/null 2>&1 || return 0
    windows="$("$kitty_bin" @ --to "$kitty_to" ls 2>/dev/null | jq -r '.[]?.tabs[]?.windows[]? | [.id, (.title // "window")] | @tsv' 2>/dev/null || true)"
    [[ -n "$windows" ]] || return 0

    mkdir -p "$snapshot_dir"
    while IFS=$'\t' read -r window_id title; do
        [[ -n "$window_id" ]] || continue
        safe_title="$(sanitize_name "$title")"
        "$kitty_bin" @ --to "$kitty_to" get-text --extent=all --match "id:$window_id" > "$snapshot_dir/window-$window_id-$safe_title.txt" 2>/dev/null || true
    done <<< "$windows"
}

cleanup_snapshots() {
    local count

    [[ -d "$snapshot_root" ]] || return 0

    if [[ "$keep_days" =~ ^[0-9]+$ ]]; then
        find "$snapshot_root" -mindepth 1 -maxdepth 1 -type d -mtime "+$keep_days" -exec rm -rf {} +
    fi

    [[ "$keep_count" =~ ^[0-9]+$ ]] || return 0
    count="$(find "$snapshot_root" -mindepth 1 -maxdepth 1 -type d | wc -l)"
    if (( count <= keep_count )); then
        return 0
    fi

    find "$snapshot_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
        | sort -r \
        | tail -n "+$((keep_count + 1))" \
        | while IFS= read -r old_snapshot; do
            [[ -n "$old_snapshot" ]] || continue
            rm -rf "${snapshot_root:?}/$old_snapshot"
        done
}

main() {
    save_session_file
    save_text_snapshots
    cleanup_snapshots
    printf 'Saved kitty session to %s\n' "$session_file"
}

main "$@"
