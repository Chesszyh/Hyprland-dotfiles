#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Clipboard Manager with Image Preview & Pinning for Dark Angel

# Variables
rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
pin_file="$HOME/.config/dark-angel/clip_pins.txt"
cache_dir="$HOME/.cache/cliphist"
max_history_items=180
thumbnail_prewarm_items=14
mkdir -p "$(dirname "$pin_file")" "$cache_dir"
touch "$pin_file"

msg='Alt+P: Pin/Unpin  |  Alt+O: Open Link  |  Ctrl+Del: Delete  |  Alt+Del: Wipe All'

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

remove_pin() {
    local content="$1"
    local tmp_file="${pin_file}.tmp"

    grep -Fxv "$content" "$pin_file" > "$tmp_file" || true
    mv "$tmp_file" "$pin_file"
}

history_id() {
    local line="$1"

    printf '%s\n' "${line%%[[:space:]]*}"
}

history_content() {
    local line="$1"
    local id

    id=$(history_id "$line")
    printf '%s\n' "${line#"$id"$'\t'}"
}

copy_text() {
    local content="$1"

    if ! printf '%s' "$content" | wl-copy; then
        return 1
    fi
    printf '%s' "$content" | cliphist store >/dev/null 2>&1 || true
}

cache_tmp_file() {
    local prefix="$1"

    mktemp "${cache_dir}/${prefix}.XXXXXX"
}

is_image_history_line() {
    local line="$1"

    [[ "$line" == *"[[ binary data"* && "$line" =~ png|jpg|jpeg|gif|webp ]]
}

thumbnail_path() {
    local id="$1"

    printf '%s/thumb_%s.png\n' "$cache_dir" "$id"
}

render_thumbnail() {
    local id="$1"
    local thumb="$2"
    local tmp_img
    local status=0

    [[ -f "$thumb" ]] && return 0
    [[ "$id" =~ ^[0-9]+$ ]] || return 1

    tmp_img=$(cache_tmp_file "thumb_${id}")
    if ! cliphist decode "$id" > "$tmp_img"; then
        rm -f "$tmp_img"
        return 1
    fi

    if command -v magick >/dev/null 2>&1; then
        magick "$tmp_img" -auto-orient -thumbnail 160x160 "$thumb" >/dev/null 2>&1 || status=$?
    else
        cp "$tmp_img" "$thumb" || status=$?
    fi
    rm -f "$tmp_img"
    return "$status"
}

copy_history_item() {
    local id="$1"
    local tmp_file

    if [[ ! "$id" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    tmp_file=$(cache_tmp_file "copy_${id}")
    if ! cliphist decode "$id" > "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    if ! wl-copy < "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi
    cliphist store < "$tmp_file" >/dev/null 2>&1 || true
    rm -f "$tmp_file"
}

queue_thumbnail() {
    local id="$1"
    local thumb="$2"

    (
        render_thumbnail "$id" "$thumb"
    ) >/dev/null 2>&1 &
}

prewarm_thumbnails() {
    local line id thumb count=0

    while IFS= read -r line; do
        is_image_history_line "$line" || continue

        id=$(history_id "$line")
        thumb=$(thumbnail_path "$id")
        render_thumbnail "$id" "$thumb" || true

        count=$((count + 1))
        [[ "$count" -ge "$thumbnail_prewarm_items" ]] && break
    done < <(cliphist list | sed -n "1,${max_history_items}p")
}

remove_thumbnail() {
    local id="$1"

    [[ "$id" =~ ^[0-9]+$ ]] || return 0
    rm -f -- "$(thumbnail_path "$id")"
}

clear_thumbnail_cache() {
    rm -f -- "$cache_dir"/thumb_* "$cache_dir"/copy_* "$cache_dir"/tmp_* 2>/dev/null || true
}

load_pins() {
    pinned_items=()
    if [[ -s "$pin_file" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && pinned_items+=("$line")
        done < "$pin_file"
    fi
}

is_pinned() {
    local content="$1"
    local pin

    for pin in "${pinned_items[@]}"; do
        [[ "$pin" == "$content" ]] && return 0
    done

    return 1
}

# Function to generate the list for rofi
generate_list() {
    # 1. Output Pins
    local line content id thumb

    load_pins

    for line in "${pinned_items[@]}"; do
        printf '📌 %s\n' "$line"
    done

    # 2. Output History (Deduplicated)
    cliphist list | sed -n "1,${max_history_items}p" | while read -r line; do
        content=$(history_content "$line")

        # Exact match check against pins
        if is_pinned "$content"; then
            continue
        fi

        if is_image_history_line "$line"; then
            id=$(history_id "$line")
            thumb=$(thumbnail_path "$id")
            if [[ -f "$thumb" ]]; then
                printf '%s\0icon\x1f%s\n' "$line" "$thumb"
                continue
            fi
            queue_thumbnail "$id" "$thumb"
        fi
        printf '%s\n' "$line"
    done
}

while true; do
    prewarm_thumbnails

    result=$(
        generate_list | rofi -i -dmenu \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -kb-custom-3 "Alt-p" \
            -kb-custom-4 "Alt-o" \
            -config "$rofi_theme" \
            -p "󰅍" \
            -mesg "$msg" 
    )

    exit_code=$?
    [[ -z "$result" ]] && exit

    # Robust pin detection
    if [[ "$result" == 📌* ]]; then
        is_pin=true
        content="${result#📌 }"
        id=""
    else
        is_pin=false
        id=$(history_id "$result")
        content=$(history_content "$result")
    fi

    case "$exit_code" in
        0) # Enter: Copy
           if $is_pin; then
               copy_text "$content"
           else
               if ! copy_history_item "$id"; then
                   copy_text "$content"
               fi
           fi
           exit ;;
        10) # Ctrl+Del: Delete
           if $is_pin; then
               remove_pin "$content"
           else
               cliphist delete <<<"$result"
               remove_thumbnail "$id"
           fi ;;
        11) # Alt+Del: Wipe
           cliphist wipe
           : > "$pin_file"
           clear_thumbnail_cache ;;
        12) # Alt+P: Pin/Unpin
           if grep -Fxq "$content" "$pin_file" 2>/dev/null; then
               # Unpin
               remove_pin "$content"
           else
               # Pin
               echo "$content" >> "$pin_file"
           fi ;;
        13) # Alt+O: Open
           url=$(echo "$content" | grep -oE "https?://[a-zA-Z0-9\./_-]+")
           if [[ -n "$url" ]]; then
               xdg-open "$url" &
               exit
           fi ;;
        *) exit ;;
    esac
done
