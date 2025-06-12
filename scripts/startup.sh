#!/bin/sh

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

# Restart Waybar (optional if managed by systemd)
pkill waybar
sleep 1
waybar &
sleep 2

# Silent app launches - window rules handle workspace assignment
hyprctl dispatch exec 'librewolf'
sleep 1
hyprctl dispatch exec 'electron-mail'
sleep 1
hyprctl dispatch exec 'chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://jobtread.com'
sleep 1
hyprctl dispatch exec 'obsidian'
sleep 1
hyprctl dispatch exec 'kitty'
sleep 1
hyprctl dispatch exec 'code'
sleep 1
hyprctl dispatch exec 'qbittorrent'
sleep 1
hyprctl dispatch exec 'chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://claude.ai'
sleep 1


echo "Startup complete"
