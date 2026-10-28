#!/usr/bin/env bash
set -euo pipefail

service=hypridle-inhibit.service

case "${1:-}" in
    status)
        if systemctl --user is-active --quiet "$service"; then
            printf '{"text":"","class":"activated","tooltip":"已禁止自动锁屏；点击恢复"}\n'
        else
            printf '{"text":"","class":"deactivated","tooltip":"自动锁屏已开启；点击禁止"}\n'
        fi
        ;;
    toggle)
        if systemctl --user is-active --quiet "$service"; then
            systemctl --user stop "$service"
            # Start a fresh idle interval after releasing the inhibitor.
            systemctl --user restart hypridle.service
        else
            systemctl --user start "$service"
        fi
        ;;
    *)
        printf 'Usage: %s {status|toggle}\n' "$0" >&2
        exit 2
        ;;
esac
