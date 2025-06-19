# modules/ui/hyprland.nix
# Consolidated Hyprland configuration with inlined startup script and bindings
{ config, pkgs, lib, ... }:

let
  # Inlined startup script (replaces startup.sh)
  # Monitor toggle script
  monitorToggle = pkgs.writeScriptBin "monitor-toggle" ''
    #!/usr/bin/env bash
    
    # Get list of connected monitors
    MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
    LAPTOP=$(echo "$MONITORS" | grep -E "(eDP|LVDS)" | head -1)
    EXTERNAL=$(echo "$MONITORS" | grep -v -E "(eDP|LVDS)" | head -1)
    
    if [[ -z "$EXTERNAL" ]]; then
        echo "No external monitor detected"
        exit 1
    fi
    
    # Get current positions
    LAPTOP_POS=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$LAPTOP\") | .x")
    EXTERNAL_POS=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$EXTERNAL\") | .x")
    
    # Get monitor specs
    LAPTOP_SPEC=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$LAPTOP\") | \"\(.width)x\(.height)@\(.refreshRate)\"")
    EXTERNAL_SPEC=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$EXTERNAL\") | \"\(.width)x\(.height)@\(.refreshRate)\"")
    LAPTOP_WIDTH=$(echo "$LAPTOP_SPEC" | cut -d'x' -f1)
    EXTERNAL_WIDTH=$(echo "$EXTERNAL_SPEC" | cut -d'x' -f1)
    
    if [[ $LAPTOP_POS -eq 0 ]]; then
        # Laptop is on left, move external to left
        echo "Moving external monitor to left"
        hyprctl keyword monitor "$EXTERNAL,$EXTERNAL_SPEC,0x0,1"
        hyprctl keyword monitor "$LAPTOP,$LAPTOP_SPEC,${EXTERNAL_WIDTH}x0,1"
    else
        # Laptop is on right, move external to right  
        echo "Moving external monitor to right"
        hyprctl keyword monitor "$LAPTOP,$LAPTOP_SPEC,0x0,1"
        hyprctl keyword monitor "$EXTERNAL,$EXTERNAL_SPEC,${LAPTOP_WIDTH}x0,1"
    fi
  '';
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
  
  # Launch apps directly to specific workspaces (no switching)
  hyprctl dispatch exec '[workspace 1 silent] librewolf' &
  sleep 1
  hyprctl dispatch exec '[workspace 2 silent] electron-mail' &
  sleep 1
  hyprctl dispatch exec '[workspace 3 silent] chromium --app=https://jobtread.com' &
  sleep 1
  hyprctl dispatch exec '[workspace 4 silent] obsidian' &
  sleep 1
  hyprctl dispatch exec '[workspace 5 silent] kitty' &
  sleep 1
  hyprctl dispatch exec '[workspace 6 silent] code' &
  sleep 1
  hyprctl dispatch exec '[workspace 7 silent] qbittorrent' &
  
  # Stay on workspace 1
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
    bind = $mod SHIFT, M, exec, monitor-toggle

    
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
	bind = $mod ALT, H, layoutmsg, orientationleft   # H for horizontal split  
	bind = $mod ALT, V, layoutmsg, orientationtop    # V for vertical split
	    
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
	    
	# Monitor-aware workspace switching (SUPER + CTRL + ALT + numbers)  
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
    monitorToggle
  ];
  system.activationScripts.hyprlandConfig = ''
    mkdir -p /home/eric/.config/hypr
    chown eric:users /home/eric/.config/hypr
    ln -sf /etc/hypr/hyprland.conf /home/eric/.config/hypr/hyprland.conf
    chown -h eric:users /home/eric/.config/hypr/hyprland.conf
  '';
}
