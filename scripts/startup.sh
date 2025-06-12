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
pkill waybar
sleep 1
waybar &

# Wait for waybar to start
sleep 2

# Launch apps into their workspaces (remove the space in workspace names)
hyprctl dispatch exec '[workspace 1:Web silent] librewolf'
sleep 1
hyprctl dispatch exec '[workspace 2:Email silent] electron-mail'
sleep 1  
hyprctl dispatch exec '[workspace 3:JT silent] librewolf --new-window https://jobtread.com'
sleep 1
hyprctl dispatch exec '[workspace 4:Notes silent] obsidian'
sleep 1
hyprctl dispatch exec '[workspace 6:Code silent] code'  # Changed to 6 to match your config

echo "Startup script completed"
