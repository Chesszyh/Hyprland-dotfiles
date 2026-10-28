#!/usr/bin/env bash
exec python3 "$(dirname "$0")/minimized.py" minimize "$@"
