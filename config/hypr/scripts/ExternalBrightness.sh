#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for External Monitor brightness using ddcutil

iDIR="$HOME/.config/swaync/icons"
notification_timeout=1000
step=10  # INCREASE/DECREASE BY THIS VALUE
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-external-brightness"
brightness_cache_ttl=30
display_connector=""
display_id=""
cached_display_id=""
cached_brightness=""
cached_max_brightness=""
cached_ts=""

cache_key() {
    local raw_key

    raw_key=${display_connector:-default}
    printf '%s\n' "${raw_key//[^[:alnum:]._-]/_}"
}

cache_file() {
    printf '%s/%s.state\n' "$cache_dir" "$(cache_key)"
}

load_cache() {
    local file key value

    cached_display_id=""
    cached_brightness=""
    cached_max_brightness=""
    cached_ts=""
    file=$(cache_file)

    [ -f "$file" ] || return 1

    while IFS='=' read -r key value; do
        case "$key" in
            "display_id")
                cached_display_id=$value
                ;;
            "brightness")
                cached_brightness=$value
                ;;
            "max_brightness")
                cached_max_brightness=$value
                ;;
            "ts")
                cached_ts=$value
                ;;
        esac
    done < "$file"
}

save_cache() {
    local brightness=$1
    local max_brightness=$2
    local file

    mkdir -p "$cache_dir"
    file=$(cache_file)

    cat > "$file" <<EOF
display_id=${display_id}
brightness=${brightness}
max_brightness=${max_brightness}
ts=$(date +%s)
EOF
}

clear_cache() {
    rm -f "$(cache_file)"
    cached_display_id=""
    cached_brightness=""
    cached_max_brightness=""
    cached_ts=""
}

brightness_cache_is_fresh() {
    local now

    [ -n "$cached_ts" ] || return 1
    now=$(date +%s)

    (( now - cached_ts <= brightness_cache_ttl ))
}

resolve_display_id() {
    local connector=$1

    [ -z "$connector" ] && return 0

    load_cache >/dev/null 2>&1 || true
    if [ -n "$cached_display_id" ]; then
        printf '%s\n' "$cached_display_id"
        return 0
    fi

    ddcutil detect --brief | awk -v connector="$connector" '
        /^Display[[:space:]]+[0-9]+/ {
            display = $2
            gsub(/[^0-9]/, "", display)
        }
        /^[[:space:]]*DRM connector:/ || /^[[:space:]]*DRM_connector:/ {
            value = $0
            sub(/^[[:space:]]*DRM connector:[[:space:]]*/, "", value)
            sub(/^[[:space:]]*DRM_connector:[[:space:]]*/, "", value)
            sub(/^card[0-9]+-/, "", value)
            if (value == connector) {
                print display
                exit
            }
        }
    '
}

run_ddcutil() {
    if [ -n "$display_id" ]; then
        ddcutil --display "$display_id" "$@"
    else
        ddcutil "$@"
    fi
}

refresh_brightness_cache() {
    local output current max

    output=$(run_ddcutil getvcp 10 --brief 2>/dev/null) || {
        if [ -n "$display_connector" ]; then
            clear_cache
            display_id=$(resolve_display_id "$display_connector")
            [ -n "$display_id" ] || return 1
            output=$(run_ddcutil getvcp 10 --brief) || return 1
        else
            return 1
        fi
    }

    set -- $output
    current=$4
    max=$5

    [ -n "$current" ] || return 1
    [ -n "$max" ] || max=100

    save_cache "$current" "$max"
    printf '%s %s\n' "$current" "$max"
}

get_brightness_pair() {
    load_cache >/dev/null 2>&1 || true
    if brightness_cache_is_fresh && [ -n "$cached_brightness" ] && [ -n "$cached_max_brightness" ]; then
        [ -n "$display_id" ] || display_id=$cached_display_id
        printf '%s %s\n' "$cached_brightness" "$cached_max_brightness"
        return 0
    fi

    refresh_brightness_cache
}

set_brightness_relative() {
    local delta=$1
    local operator="+"
    local magnitude=$delta

    if (( delta < 0 )); then
        operator="-"
        magnitude=$(( -delta ))
    fi

    run_ddcutil --noverify setvcp 10 "$operator" "$magnitude" 2>/dev/null || {
        if [ -n "$display_connector" ]; then
            clear_cache
            display_id=$(resolve_display_id "$display_connector")
            [ -n "$display_id" ] || return 1
            run_ddcutil --noverify setvcp 10 "$operator" "$magnitude"
        else
            return 1
        fi
    }
}

# Get brightness level (VCP code 10)
get_brightness() {
    get_brightness_pair | awk '{print $1}'
}

# Send notification
send_notification() {
    local brightness=$1
    local level=$(( (brightness + 19) / 20 * 20 ))
    local icon_path="$iDIR/brightness-${level}.png"

    # Ensure icon exists
    [ ! -f "$icon_path" ] && icon_path="$iDIR/brightness-100.png"

    notify-send -e \
        -h string:x-canonical-private-synchronous:ext_brightness_notif \
        -h int:value:"$brightness" \
        -u low \
        -i "$icon_path" \
        "External Monitor" "Brightness: ${brightness}%"
}

# Change brightness
change_brightness() {
    local delta=$1
    local current max new

    read -r current max < <(get_brightness_pair)

    # If ddcutil failed to get brightness, exit
    [ -z "$current" ] && exit 1
    [ -n "$max" ] || max=100

    new=$((current + delta))

    # Clamp between 0 and 100
    (( new < 0 )) && new=0
    (( new > max )) && new=max

    if (( new == current )); then
        send_notification "$new"
        exit 0
    fi

    # Apply relative change without post-write verification to keep repeated keypresses responsive.
    set_brightness_relative "$delta" || exit 1

    save_cache "$new" "$max"
    send_notification "$new"
}

while [ $# -gt 0 ]; do
    case "$1" in
        "--connector")
            shift
            display_connector=${1:-}
            ;;
        "--inc"|"--dec"|"--get")
            action=$1
            ;;
    esac
    shift
done

action=${action:---get}
display_id=$(resolve_display_id "$display_connector")

if [ -n "$display_connector" ] && [ -z "$display_id" ]; then
    notify-send -e -u low "External Monitor" "No DDC/CI display found for ${display_connector}"
    exit 1
fi

case "$action" in
    "--inc")
        change_brightness "$step"
        ;;
    "--dec")
        change_brightness "-$step"
        ;;
    "--get")
        get_brightness
        ;;
    *)
        get_brightness
        ;;
esac
