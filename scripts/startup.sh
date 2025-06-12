#!/bin/sh
# Wait for Hyprland to be ready
until hyprctl monitors > /dev/null 2>&1; do
  sleep 0.2
done

# Start background services first
swaynotificationcenter &
hypridle &
hyprpaper &

# Set up clipboard management
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

# Wait a bit for services to initialize
sleep 2

# Restart Waybar explicitly (after background services)
#pkill waybar
#sleep 1
#waybar &

# Wait for waybar to start
#sleep 2

hyprctl dispatch workspace 1
hyprctl dispatch exec 'librewolf'
sleep 1

hyprctl dispatch workspace 2  
hyprctl dispatch exec 'electron-mail'
sleep 1

hyprctl dispatch workspace 3
hyprctl dispatch exec 'chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://jobtread.com'
sleep 1

hyprctl dispatch workspace 4
hyprctl dispatch exec 'obsidian'
sleep 1

hyprctl dispatch workspace 5
hyprctl dispatch exec 'kitty'
sleep 1

hyprctl dispatch workspace 6 
hyprctl dispatch exec 'code'

hyprctl dispatch workspace 7
hyprctl dispatch exec 'qbittorrent'
sleep 1

hyprctl dispatch workspace 8
hyprctl dispatch exec 'chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://claude.ai'


echo "Startup script completed"
