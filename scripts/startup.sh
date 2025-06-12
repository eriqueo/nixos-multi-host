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

# Launch apps on NAMED workspaces
hyprctl dispatch workspace "1:Web"
hyprctl dispatch exec 'librewolf'
sleep 1
hyprctl dispatch workspace "2:Email"
hyprctl dispatch exec 'electron-mail'
sleep 1
hyprctl dispatch workspace "3:JT"
hyprctl dispatch exec 'chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://jobtread.com'
sleep 1
hyprctl dispatch workspace "4:Notes"
hyprctl dispatch exec 'obsidian'
sleep 1
hyprctl dispatch workspace "5:Code"
hyprctl dispatch exec 'kitty'
sleep 1
hyprctl dispatch workspace "6:Media"
hyprctl dispatch exec 'code'
sleep 1
hyprctl dispatch workspace "7:Misc"
hyprctl dispatch exec 'qbittorrent'
sleep 1
hyprctl dispatch workspace "8:AI"
hyprctl dispatch exec 'chromium --ozone-platform=wayland --enable-features=UseOzonePlatform --app=https://claude.ai'

# Return to first workspace
hyprctl dispatch workspace "1:Web"

echo "Startup complete"
