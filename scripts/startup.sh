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

# Silent app launches per workspace
hyprctl dispatch exec '[workspace 1:Web silent] librewolf'
sleep 1

hyprctl dispatch exec '[workspace 2:Email silent] electron-mail'
sleep 1

hyprctl dispatch exec '[workspace 3:JT silent] chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://jobtread.com'
sleep 1

hyprctl dispatch exec '[workspace 4:Notes silent] obsidian'
sleep 1

hyprctl dispatch exec '[workspace 5:Terminal silent] kitty'
sleep 1

hyprctl dispatch exec '[workspace 6:Code silent] code'
sleep 1

hyprctl dispatch exec '[workspace 7:Misc silent] qbittorrent'
sleep 1

hyprctl dispatch exec '[workspace 8:AI silent] chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://claude.ai'
sleep 1

echo "Silent startup complete"
