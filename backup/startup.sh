#!/usr/bin/env bash


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

# Start waybar
pkill waybar
sleep 1
waybar -c ~/.config/waybar/config.json -s ~/.config/waybar/style.css >/dev/null 2>&1 &
sleep 2

# Create workspaces by switching to them
for i in {1..8}; do
  hyprctl dispatch workspace $i
done

# Launch apps - they'll land on current workspace
hyprctl dispatch workspace 1 && hyprctl dispatch exec 'librewolf' &
sleep 1
hyprctl dispatch workspace 2 && hyprctl dispatch exec 'electron-mail' &
sleep 1
hyprctl dispatch workspace 3 && hyprctl dispatch exec 'chromium --app=https://jobtread.com' &
sleep 1
hyprctl dispatch workspace 4 && hyprctl dispatch exec 'obsidian' &
sleep 1
hyprctl dispatch workspace 5 && hyprctl dispatch exec 'kitty' &
sleep 1
hyprctl dispatch workspace 6 && hyprctl dispatch exec 'code' &
sleep 1
hyprctl dispatch workspace 7 && hyprctl dispatch exec 'qbittorrent' &
sleep 1
hyprctl dispatch workspace 8 && hyprctl dispatch exec 'chromium --app=https://claude.ai' &

# Go back to workspace 1
hyprctl dispatch workspace 1

echo "Startup complete"
