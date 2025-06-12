#!/bin/bash

# Wait until Hyprland is ready
until hyprctl monitors > /dev/null 2>&1; do
  sleep 0.2
done

# Background services
swaynotificationcenter &
hypridle &
hyprpaper &
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
sleep 2

# Restart Waybar
pkill waybar
sleep 1
waybar >/dev/null 2>&1 &
sleep 2

# Create the 8 named workspaces first
hyprctl dispatch workspace "1:Web"
hyprctl dispatch workspace "2:Email" 
hyprctl dispatch workspace "3:JT"
hyprctl dispatch workspace "4:Notes"
hyprctl dispatch workspace "5:Code"
hyprctl dispatch workspace "6:Media"
hyprctl dispatch workspace "7:Misc"
hyprctl dispatch workspace "8:AI"

# Launch apps with explicit workspace assignment
hyprctl dispatch exec "[workspace 1:Web silent] librewolf"
hyprctl dispatch exec "[workspace 2:Email silent] electron-mail"
hyprctl dispatch exec "[workspace 3:JT silent] chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://jobtread.com"
hyprctl dispatch exec "[workspace 4:Notes silent] obsidian"
hyprctl dispatch exec "[workspace 5:Code silent] kitty"
hyprctl dispatch exec "[workspace 6:Media silent] code"
hyprctl dispatch exec "[workspace 7:Misc silent] qbittorrent"
hyprctl dispatch exec "[workspace 8:AI silent] chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://claude.ai"

# Go back to first workspace
hyprctl dispatch workspace "1:Web"

echo "Startup complete"
