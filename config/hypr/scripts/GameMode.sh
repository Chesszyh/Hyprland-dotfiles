#!/usr/bin/env bash
exec python3 "$(dirname "$0")/game_mode.py" "${1:-toggle}"
