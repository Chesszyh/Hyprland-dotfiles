#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Not my own work. This was added through Github PR. Credit to original author

#----- Optimized bars animation without much CPU usage increase --------
bar="▁▂▃▄▅▆▇█"
# Strip Cava's delimiter and hide a completely silent frame. Waybar then
# removes the module until audio starts moving again.
dict="s/;//g;s/^0000000000$//"

# Calculate the length of the bar outside the loop
bar_length=${#bar}

# Create dictionary to replace char with bar
for ((i = 0; i < bar_length; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

# Create cava config
config_file="$(mktemp --tmpdir="${XDG_RUNTIME_DIR:-/tmp}" waybar-cava.XXXXXX.conf)"
trap 'rm -f "$config_file"' EXIT
cat >"$config_file" <<EOF
[general]
# Older systems show significant CPU use with default framerate
# Setting maximum framerate to 30  
# You can increase the value if you wish
framerate = 30
bars = 10

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Read stdout from cava and perform substitution in a single sed command
exec cava -p "$config_file" | sed -u "$dict"
