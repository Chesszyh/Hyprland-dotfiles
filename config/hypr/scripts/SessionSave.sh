#!/usr/bin/env bash
exec python3 "$(dirname "$0")/session.py" save "${1:-auto}"
