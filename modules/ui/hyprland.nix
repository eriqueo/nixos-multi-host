# modules/ui/hyprland.nix
# Consolidated Hyprland configuration with inlined startup script and bindings
{ config, pkgs, lib, ... }:

let
  # Inlined startup script (replaces startup.sh)
  hyprStartup = pkgs.writeScriptBin "hypr-startup" ''
     #!/usr/bin/env bash
     # Wait until Hyprland is ready
     until hyprctl monitors > /dev/null 2>&1; do
       sleep 0.2
     done
     
     # Background services (only ones that are configured)
     wl-paste --type text --watch cliphist store &
     wl-paste --type image --watch cliphist store &
     sleep 2
     
     # Start waybar (home-manager handles config files)
     pkill waybar
     sleep 1
     waybar >/dev/null 2>&1 &
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
   '';
in
{
  # Enable Hyprland the modern way
  programs.hyprland = {
    enable = true;
  };

  # Optional: Enable XWayland if needed
  programs.hyprland.xwayland.enable = true;

  # User-level Hyprland configuration using home-manager
  environment.etc."hypr/hyprland.conf".text = ''
    # Monitor setup
    monitor = DP-1,1920x1080@60,0x0,1
    monitor = eDP-1,2560x1600@165,1920x0,1

    # Launch startup script on first seat activation
    exec-once = ${hyprStartup}/bin/hypr-startup

    # Arrange monitors
    # input tweaks
    input {
        kb_layout = us
        follow_mouse = 1
        touchpad {
            natural_scroll = true
        }
    }

    # Variables (from bindings.sh)
    $mod = SUPER
    
    # Window/Session Management
    bind = $mod, Return, exec, kitty
    bind = $mod, Q, killactive
    bind = $mod, F, fullscreen
    bind = $mod, Space, exec, wofi --show drun
    bind = $mod, B, exec, librewolf
    bind = $mod, E, exec, electron-mail
    
    # Screenshots - FIXED paths
    bind = , Print, exec, hyprshot -m region -o ~/Pictures/01-screenshots
    bind = SHIFT, Print, exec, hyprshot -m region -c
    
    # Focus movement (SUPER + arrows)
    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d
    
    # Window movement within workspace (SUPER + ALT + arrows)
    bind = $mod ALT, left, movewindow, l
    bind = $mod ALT, right, movewindow, r
    bind = $mod ALT, up, movewindow, u
    bind = $mod ALT, down, movewindow, d
    
    # Move windows to workspaces (SUPER + CTRL + numbers)
    bind = $mod CTRL, 1, movetoworkspace, 1
    bind = $mod CTRL, 2, movetoworkspace, 2
    bind = $mod CTRL, 3, movetoworkspace, 3
    bind = $mod CTRL, 4, movetoworkspace, 4
    bind = $mod CTRL, 5, movetoworkspace, 5
    bind = $mod CTRL, 6, movetoworkspace, 6
    bind = $mod CTRL, 7, movetoworkspace, 7
    bind = $mod CTRL, 8, movetoworkspace, 8
    bind = $mod CTRL, W, movetoworkspace, 1
    bind = $mod CTRL, E, movetoworkspace, 2
    bind = $mod CTRL, J, movetoworkspace, 3
    bind = $mod CTRL, O, movetoworkspace, 4
    bind = $mod CTRL, K, movetoworkspace, 5
    bind = $mod CTRL, C, movetoworkspace, 6
    bind = $mod CTRL, M, movetoworkspace, 7
    bind = $mod CTRL, R, movetoworkspace, 8
    
    # Switch to workspaces (SUPER + CTRL + ALT + numbers)
    bind = $mod CTRL ALT, 1, workspace, 1
    bind = $mod CTRL ALT, 2, workspace, 2
    bind = $mod CTRL ALT, 3, workspace, 3
    bind = $mod CTRL ALT, 4, workspace, 4
    bind = $mod CTRL ALT, 5, workspace, 5
    bind = $mod CTRL ALT, 6, workspace, 6
    bind = $mod CTRL ALT, 7, workspace, 7
    bind = $mod CTRL ALT, 8, workspace, 8
    bind = $mod CTRL ALT, W, workspace, 1
    bind = $mod CTRL ALT, E, workspace, 2
    bind = $mod CTRL ALT, J, workspace, 3
    bind = $mod CTRL ALT, O, workspace, 4
    bind = $mod CTRL ALT, K, workspace, 5
    bind = $mod CTRL ALT, C, workspace, 6
    bind = $mod CTRL ALT, M, workspace, 7
    bind = $mod CTRL ALT, R, workspace, 8
    bind = $mod CTRL ALT, left, workspace, e-1
    bind = $mod CTRL ALT, right, workspace, e+1
  '';

  # Install the startup script into system packages
  environment.systemPackages = [
    hyprStartup
  ];
}
