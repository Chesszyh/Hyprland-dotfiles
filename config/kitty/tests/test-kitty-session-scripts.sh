#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAVE_SCRIPT="$ROOT_DIR/scripts/kitty-session-save.sh"
RESTORE_SCRIPT="$ROOT_DIR/scripts/kitty-session-restore.sh"

TEST_TMP=""

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local expected="$2"

    grep -F -- "$expected" "$file" >/dev/null || fail "expected $file to contain: $expected"
}

assert_file_exists() {
    local file="$1"

    [[ -f "$file" ]] || fail "expected file to exist: $file"
}

reset_tmp() {
    if [[ -n "$TEST_TMP" && -d "$TEST_TMP" ]]; then
        rm -rf "$TEST_TMP"
    fi
    TEST_TMP="$(mktemp -d)"
}

cleanup() {
    if [[ -n "$TEST_TMP" && -d "$TEST_TMP" ]]; then
        rm -rf "$TEST_TMP"
    fi
}
trap cleanup EXIT

write_fake_kitty() {
    local fake_bin="$1"
    local log_file="$2"

    mkdir -p "$fake_bin"
    cat > "$fake_bin/kitty" <<'FAKE_KITTY'
#!/usr/bin/env bash
set -euo pipefail

{
    printf 'CALL'
    for arg in "$@"; do
        printf '\t%s' "$arg"
    done
    printf '\n'
} >> "$KITTY_FAKE_LOG"

if [[ "${1:-}" == "@" ]]; then
    shift
    if [[ "${1:-}" == "--to" ]]; then
        shift 2
    fi

    case "${1:-}" in
        ls)
            shift
            if [[ " $* " == *" --output-format=session "* ]]; then
                printf 'new_tab Saved\ncd /tmp\nlaunch zsh\n'
            else
                printf '[{"id":1,"tabs":[{"id":2,"title":"main","windows":[{"id":3,"title":"shell"},{"id":4,"title":"ssh host"}]}]}]\n'
            fi
            ;;
        get-text)
            printf 'snapshot for %s\n' "$*"
            ;;
    esac
fi
FAKE_KITTY
    chmod +x "$fake_bin/kitty"
    : > "$log_file"
}

run_with_fake_kitty() {
    local state_dir="$1"
    local fake_bin="$2"
    shift 2

    KITTY_FAKE_LOG="$TEST_TMP/kitty.log" \
    KITTY_SESSION_STATE_DIR="$state_dir" \
    KITTY_SESSION_TO="unix:/tmp/test-kitty-session" \
    KITTY_SESSION_TIMESTAMP="20260414_010101" \
    KITTY_SESSION_KEEP_DAYS="9999" \
    PATH="$fake_bin:$PATH" \
    "$@"
}

run_with_fake_kitty_listen_env() {
    local state_dir="$1"
    local fake_bin="$2"
    shift 2

    KITTY_FAKE_LOG="$TEST_TMP/kitty.log" \
    KITTY_SESSION_STATE_DIR="$state_dir" \
    KITTY_LISTEN_ON="unix:/tmp/test-kitty-session-with-pid-12345" \
    KITTY_SESSION_TIMESTAMP="20260414_010101" \
    KITTY_SESSION_KEEP_DAYS="9999" \
    PATH="$fake_bin:$PATH" \
    "$@"
}

run_with_fake_kitty_socket_discovery() {
    local state_dir="$1"
    local fake_bin="$2"
    local socket_glob="$3"
    shift 3

    KITTY_FAKE_LOG="$TEST_TMP/kitty.log" \
    KITTY_SESSION_STATE_DIR="$state_dir" \
    KITTY_SESSION_SOCKET_GLOB="$socket_glob" \
    KITTY_SESSION_TIMESTAMP="20260414_010101" \
    KITTY_SESSION_KEEP_DAYS="9999" \
    PATH="$fake_bin:$PATH" \
    "$@"
}

test_restore_without_session_launches_plain_kitty() {
    reset_tmp
    local fake_bin="$TEST_TMP/bin"
    local state_dir="$TEST_TMP/state"
    local log_file="$TEST_TMP/kitty.log"

    write_fake_kitty "$fake_bin" "$log_file"
    mkdir -p "$state_dir"

    run_with_fake_kitty "$state_dir" "$fake_bin" "$RESTORE_SCRIPT"

    assert_file_contains "$log_file" "CALL"
    if grep -F -- "--session" "$log_file" >/dev/null; then
        fail "restore should not use --session when last.session is missing"
    fi
}

test_restore_with_session_uses_saved_file() {
    reset_tmp
    local fake_bin="$TEST_TMP/bin"
    local state_dir="$TEST_TMP/state"
    local log_file="$TEST_TMP/kitty.log"

    write_fake_kitty "$fake_bin" "$log_file"
    mkdir -p "$state_dir"
    printf 'new_tab saved\n' > "$state_dir/last.session"

    run_with_fake_kitty "$state_dir" "$fake_bin" "$RESTORE_SCRIPT"

    assert_file_contains "$log_file" $'CALL\t--session'
    assert_file_contains "$log_file" "$state_dir/last.session"
}

test_save_writes_session_and_snapshots() {
    reset_tmp
    local fake_bin="$TEST_TMP/bin"
    local state_dir="$TEST_TMP/state"
    local log_file="$TEST_TMP/kitty.log"

    write_fake_kitty "$fake_bin" "$log_file"

    run_with_fake_kitty "$state_dir" "$fake_bin" "$SAVE_SCRIPT"

    assert_file_exists "$state_dir/last.session"
    assert_file_contains "$state_dir/last.session" "new_tab Saved"
    assert_file_exists "$state_dir/snapshots/20260414_010101/window-3-shell.txt"
    assert_file_exists "$state_dir/snapshots/20260414_010101/window-4-ssh_host.txt"
    assert_file_contains "$log_file" $'CALL\t@\t--to\tunix:/tmp/test-kitty-session\tls\t--output-format=session'
    assert_file_contains "$log_file" $'CALL\t@\t--to\tunix:/tmp/test-kitty-session\tget-text\t--extent=all\t--match\tid:3'
}

test_save_prefers_kitty_listen_on_from_launched_shortcut() {
    reset_tmp
    local fake_bin="$TEST_TMP/bin"
    local state_dir="$TEST_TMP/state"
    local log_file="$TEST_TMP/kitty.log"

    write_fake_kitty "$fake_bin" "$log_file"

    run_with_fake_kitty_listen_env "$state_dir" "$fake_bin" "$SAVE_SCRIPT"

    assert_file_exists "$state_dir/last.session"
    assert_file_contains "$log_file" $'CALL\t@\t--to\tunix:/tmp/test-kitty-session-with-pid-12345\tls\t--output-format=session'
}

test_save_discovers_pid_suffixed_config_socket() {
    reset_tmp
    local fake_bin="$TEST_TMP/bin"
    local state_dir="$TEST_TMP/state"
    local log_file="$TEST_TMP/kitty.log"
    local socket_dir="$TEST_TMP/sockets"

    write_fake_kitty "$fake_bin" "$log_file"
    mkdir -p "$socket_dir"
    : > "$socket_dir/kitty-session-chesszyh-111"
    sleep 1
    : > "$socket_dir/kitty-session-chesszyh-222"

    run_with_fake_kitty_socket_discovery "$state_dir" "$fake_bin" "$socket_dir/kitty-session-chesszyh-*" "$SAVE_SCRIPT"

    assert_file_exists "$state_dir/last.session"
    assert_file_contains "$log_file" $'CALL\t@\t--to\tunix:'"$socket_dir"$'/kitty-session-chesszyh-222\tls\t--output-format=session'
}

test_save_limits_snapshot_count() {
    reset_tmp
    local fake_bin="$TEST_TMP/bin"
    local state_dir="$TEST_TMP/state"

    write_fake_kitty "$fake_bin" "$TEST_TMP/kitty.log"
    mkdir -p "$state_dir/snapshots/20260414_000001"
    mkdir -p "$state_dir/snapshots/20260414_000002"
    mkdir -p "$state_dir/snapshots/20260414_000003"

    KITTY_SESSION_KEEP_COUNT="2" run_with_fake_kitty "$state_dir" "$fake_bin" "$SAVE_SCRIPT"

    local count
    count="$(find "$state_dir/snapshots" -mindepth 1 -maxdepth 1 -type d | wc -l)"
    [[ "$count" == "2" ]] || fail "expected 2 snapshot directories, got $count"
    [[ -d "$state_dir/snapshots/20260414_010101" ]] || fail "expected newest snapshot to be retained"
    [[ -d "$state_dir/snapshots/20260414_000003" ]] || fail "expected most recent old snapshot to be retained"
}

main() {
    test_restore_without_session_launches_plain_kitty
    test_restore_with_session_uses_saved_file
    test_save_writes_session_and_snapshots
    test_save_prefers_kitty_listen_on_from_launched_shortcut
    test_save_discovers_pid_suffixed_config_socket
    test_save_limits_snapshot_count
    printf 'PASS: kitty session script tests\n'
}

main "$@"
