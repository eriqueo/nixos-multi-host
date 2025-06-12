#!/bin/sh

# Startup script to launch applications on specific Hyprland workspaces with delays

hyprctl dispatch exec '[workspace 1 silent] librewolf' &
sleep 2
hyprctl dispatch exec '[workspace 2 silent] electron-mail' &
sleep 2
hyprctl dispatch exec '[workspace 3 silent] librewolf --new-window https://jobtread.com' &
sleep 2
hyprctl dispatch exec '[workspace 4 silent] obsidian' &
sleep 2
hyprctl dispatch exec '[workspace 5 silent] code' &
sleep 2
# Add more apps as needed, following the pattern above
