#!/bin/bash
 
# Reload Waybar by killing and restarting it
 
if pgrep -x waybar > /dev/null; then
    pkill -12 waybar
    echo "Waybar reloaded."
else
    echo "Waybar not running, starting it..."
    waybar &
fi
 
