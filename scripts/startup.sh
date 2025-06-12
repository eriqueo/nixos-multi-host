#!/bin/sh

# Wait for Hyprland to be ready
until hyprctl monitors > /dev/null 2>&1; do
  sleep 0.5
done

# Launch apps into specific workspaces with delay
hyprctl dispatch exec '[workspace 1 silent] librewolf'
sleep 2
hyprctl dispatch exec '[workspace 2 silent] electron-mail'
sleep 2
hyprctl dispatch exec '[workspace 3 silent] librewolf --new-window https://jobtread.com'
sleep 2
hyprctl dispatch exec '[workspace 4 silent] obsidian'
sleep 2
hyprctl dispatch exec '[workspace 5 silent] code'
