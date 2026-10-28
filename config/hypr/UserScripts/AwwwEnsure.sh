#!/usr/bin/env bash

set -euo pipefail

if awww query >/dev/null 2>&1; then
  exit 0
fi

pkill -x awww-daemon 2>/dev/null || true
systemctl --user stop awww-daemon.service >/dev/null 2>&1 || true
systemctl --user reset-failed awww-daemon.service >/dev/null 2>&1 || true

for _ in {1..20}; do
  if ! systemctl --user status awww-daemon.service >/dev/null 2>&1; then
    break
  fi
  sleep 0.05
done

systemd-run --user \
  --unit=awww-daemon \
  --collect \
  --quiet \
  --service-type=exec \
  /usr/bin/awww-daemon --no-cache

for _ in {1..40}; do
  if awww query >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.05
done

exit 1
