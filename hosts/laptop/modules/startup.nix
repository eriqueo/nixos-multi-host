#-----------------------------------------------------------------------------
# FILE : modules/home-manager/ui/startup.nix (SESSION STARTUP)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

let
  hyprStartup = pkgs.writeScriptBin "hypr-startup" ''
    #!/usr/bin/env bash
    
    # Wait until Hyprland is ready
    until hyprctl monitors > /dev/null 2>&1; do
      sleep 0.2
    done
    
    # Background services
    sleep 2
    
    # Start waybar with proper backgrounding
    pkill waybar 2>/dev/null || true
    sleep 1
    setsid waybar >/dev/null 2>&1 &
    sleep 2
    
    # Initialize GPU mode to Intel (default)
    echo "intel" > /tmp/gpu-mode
    
    # Launch apps to workspaces matching keybinding configuration
    hyprctl dispatch exec '[workspace 1 silent] gpu-launch thunar' &        # Workspace 1 - File manager
    sleep 1
    hyprctl dispatch exec '[workspace 2 silent] gpu-launch chromium ' &     # Workspace 2 - Browser
    sleep 1
    hyprctl dispatch exec '[workspace 3 silent] gpu-launch chromium --new-window https://jobtread.com' &  # Workspace 3 - JobTread
    sleep 1
    hyprctl dispatch exec '[workspace 4 silent] gpu-launch electron-mail' & # Workspace 4 - Email
    sleep 1
    hyprctl dispatch exec '[workspace 5 silent] gpu-launch obsidian' &      # Workspace 5 - Notes
    sleep 1
    hyprctl dispatch exec '[workspace 6 silent] nvim' &                     # Workspace 6 - Editor
    sleep 1
    hyprctl dispatch exec '[workspace 7 silent] kitty' &                    # Workspace 7 - Terminal
    sleep 1
    hyprctl dispatch exec '[workspace 8 silent] kitty btop' &               # Workspace 8 - Monitoring
    sleep 1
    
    # Stay on workspace 1
    hyprctl dispatch workspace 1
    echo "Startup complete"
  '';
in
{
  # Install startup script
  home.packages = [ hyprStartup ];
}
