#!/bin/bash

SHADER_DIR="$HOME/.config/hypr/shaders"
CURRENT=$(hyprshade current)

if [[ "$CURRENT" == *"day"* ]] || [[ -z "$CURRENT" ]]; then
    # Switch to night (warm/blue-light reduction)
    hyprshade on night.glsl
    notify-send "🌙 Night Mode" -i night-light -t 2000
else
    # Switch to vibrance
    hyprshade on day.glsl
    notify-send "☀️ Day Mode" -i color-management -t 2000
fi
