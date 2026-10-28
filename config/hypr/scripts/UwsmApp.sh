#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: UwsmApp.sh <app|background|session> <command> [args...]

  app         Launch interactive applications in app-graphical.slice
  background  Launch background helpers in background-graphical.slice
  session     Launch session-bound helpers as services in session-graphical.slice
EOF
}

if [ $# -lt 2 ]; then
    usage >&2
    exit 1
fi

mode="$1"
shift

case "$mode" in
    app)
        slice="a"
        unit_type="scope"
        ;;
    background)
        slice="b"
        unit_type="scope"
        ;;
    session)
        slice="s"
        unit_type="service"
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac

exec uwsm app -s "$slice" -t "$unit_type" -- "$@"
