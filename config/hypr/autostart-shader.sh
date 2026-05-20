#!/bin/bash
hour=$(date +%H)
if [ "$hour" -ge 20 ] || [ "$hour" -lt 10 ]; then
    hyprshade on night.glsl
else
    hyprshade on day.glsl
fi
