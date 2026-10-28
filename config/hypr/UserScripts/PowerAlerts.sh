#!/usr/bin/env bash

set -u

power_supply_dir="${POWER_SUPPLY_DIR:-/sys/class/power_supply}"
adapter="$power_supply_dir/ADP0/online"
battery="$power_supply_dir/BAT0/capacity"
previous_online=""
notification_id=0
last_low_alert=0

notify() {
  local urgency="$1" title="$2" body="$3" sound="$4" id timeout=0
  [[ "$urgency" == normal ]] && timeout=6000
  id=$(notify-send -p -r "$notification_id" -u "$urgency" -t "$timeout" -a "电源提醒" "$title" "$body") && notification_id="$id"
  pw-play "/usr/share/sounds/freedesktop/stereo/$sound.oga" >/dev/null 2>&1 || true
}

while true; do
  if [[ -r "$adapter" && -r "$battery" ]]; then
    read -r online < "$adapter"
    read -r capacity < "$battery"

    if [[ "$online" == 0 && "$previous_online" != 0 ]]; then
      notify critical "外接电源已断开" "当前使用电池，电量 ${capacity}%。请检查电源连接。" power-unplug
    elif [[ "$online" == 1 && "$previous_online" == 0 ]]; then
      notify normal "外接电源已连接" "当前电量 ${capacity}%。" power-plug
      last_low_alert=0
    fi

    if [[ "$online" == 0 && "$capacity" =~ ^[0-9]+$ && "$capacity" -le 10 ]]; then
      now=$(date +%s)
      if (( now - last_low_alert >= 120 )); then
        notify critical "电池电量仅剩 ${capacity}%" "请立即连接外接电源，避免电脑自动关机。" dialog-warning
        last_low_alert="$now"
      fi
    fi
    previous_online="$online"
  fi
  sleep 5
done
