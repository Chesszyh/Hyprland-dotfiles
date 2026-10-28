#!/usr/bin/env bash

colors=()
for _ in {1..10}; do
    colors+=("\"0xff$(openssl rand -hex 3)\"")
done
joined=$(IFS=,; printf '%s' "${colors[*]}")
hyprctl eval "hl.config({ general = { col = { active_border = { colors = {$joined}, angle = 270 } } } })"
