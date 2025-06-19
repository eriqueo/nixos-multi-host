# modules/ui/hyprland.nix - Updated with dynamic monitor configuration
{ config, pkgs, lib, ... }:

let
  # Monitor detection and configuration script
  monitorSetup = pkgs.writeScriptBin "monitor-setup" ''
    #!/usr/bin/env bash
    
    # Wait for hyprctl to be available
    until hyprctl monitors > /dev/null 2>&1; do
      sleep 0.5
    done
    
    # Get list of connected monitors
    MONITORS=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name')
    LAPTOP=$(echo "$MONITORS" | grep -E "(eDP|LVDS)" | head -1)
    EXTERNAL=$(echo "$MONITORS" | grep -v -E "(eDP|LVDS)" | head -1)
    
    if [[ -n "$LAPTOP" ]]; then
      # Get laptop monitor specs
      LAPTOP_SPEC=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$LAPTOP\") | \"\(.width)x\(.height)@\(.refreshRate)\"")
      echo "Configuring laptop monitor: $LAPTOP at $LAPTOP_SPEC"
      
      if [[ -n "$EXTERNAL" ]]; then
        # Dual monitor setup - laptop on right, external on left
        EXTERNAL_SPEC=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$EXTERNAL\") | \"\(.width)x\(.height)@\(.refreshRate)\"")
        EXTERNAL_WIDTH=$(echo "$EXTERNAL_SPEC" | cut -d'x' -f1)
        
        echo "Configuring external monitor: $EXTERNAL at $EXTERNAL_SPEC"
        hyprctl keyword monitor "$EXTERNAL,$EXTERNAL_SPEC,0x0,1"
        hyprctl keyword monitor "$LAPTOP,$LAPTOP_SPEC,''${EXTERNAL_WIDTH}x0,1"
      else
        # Single laptop monitor
        echo "Single monitor setup: $LAPTOP"
        hyprctl keyword monitor "$LAPTOP,$LAPTOP_SPEC,0x0,1"
      fi
    else
      echo "No laptop monitor detected, using auto configuration"
      hyprctl keyword monitor ",preferred,auto,1"
    fi
    
    echo "Monitor setup complete"
  '';

  # Monitor toggle script (existing)
  monitorToggle = pkgs.writeScriptBin "monitor-toggle" ''
    #!/usr/bin/env bash
    
    # Get list of connected monitors
    MONITORS=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name')
    LAPTOP=$(echo "$MONITORS" | grep -E "(eDP|LVDS)" | head -1)
    EXTERNAL=$(echo "$MONITORS" | grep -v -E "(eDP|LVDS)" | head -1)
    
    if [[ -z "$EXTERNAL" ]]; then
        echo "No external monitor detected"
        exit 1
    fi
    
    # Get current positions
    LAPTOP_POS=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$LAPTOP\") | .x")
    EXTERNAL_POS=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$EXTERNAL\") | .x")
    
    # Get monitor specs
    LAPTOP_SPEC=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$LAPTOP\") | \"\(.width)x\(.height)@\(.refreshRate)\"")
    EXTERNAL_SPEC=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$EXTERNAL\") | \"\(.width)x\(.height)@\(.refreshRate)\"")
    LAPTOP_WIDTH=$(echo "$LAPTOP_SPEC" | cut -d'x' -f1)
    EXTERNAL_WIDTH=$(echo "$EXTERNAL_SPEC" | cut -d'x' -f1)
    
    if [[ $LAPTOP_POS -eq 0 ]]; then
        # Laptop is on left, move external to left
        echo "Moving external monitor to left"
        hyprctl keyword monitor "$EXTERNAL,$EXTERNAL_SPEC,0x0,1"
        hyprctl keyword monitor "$LAPTOP,$LAPTOP_SPEC,''${EXTERNAL_WIDTH}x0,1"
    else
        # Laptop is on right, move external to right  
        echo "Moving external monitor to right"
        hyprctl keyword monitor "$LAPTOP,$LAPTOP_SPEC,0x0,1"
        hyprctl keyword monitor "$EXTERNAL,$EXTERNAL_SPEC,''${LAPTOP_WIDTH}x0,1"
    fi
  '';

  # Updated startup script
  hyprStartup = pkgs.writeScriptBin "hypr-startup" ''
    #!/usr/bin/env bash
    
    # Wait until Hyprland is ready
    until hyprctl monitors > /dev/null 2>&1; do
      sleep 0.2
    done
    
    # Configure monitors dynamically
    ${monitorSetup}/bin/monitor-setup
    
    # Background services
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
    hyprctl dispatch exec '[workspace 6 silent] vscodium' &
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
    xwayland.enable = true;
  };

  # User-level Hyprland configuration
  environment.etc."hypr/hyprland.conf".text = ''
    # Dynamic monitor setup - will be configured by startup script
    # Fallback configuration for any unrecognized monitors
    monitor = ,preferred,auto,1
    
    # Launch startup script on first seat activation
    exec-once = ${hyprStartup}/bin/hypr-startup
    
    # Input configuration
    input {
        kb_layout = us
        follow_mouse = 1
        touchpad {
            natural_scroll = true
        }
    }

    # Variables
    $mod = SUPER
    
    # Window/Session Management
    bind = $mod, Return, exec, kitty
    bind = $mod, Q, killactive
    bind = $mod, F, fullscreen
    bind = $mod, Space, exec, wofi --show drun
    bind = $mod, B, exec, librewolf
    bind = $mod, E, exec, electron-mail
    bind = $mod, T, exec, thunar
    bind = $mod, O, exec, obsidian
    bind = $mod SHIFT, M, exec, ${monitorToggle}/bin/monitor-toggle

    # Screenshots
    bind = , Print, exec, hyprshot -m region -o ~/Pictures/01-screenshots
    bind = SHIFT, Print, exec, hyprshot -m region --clipboard-only
    
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

  # Install scripts into system packages
  environment.systemPackages = [
    hyprStartup
    monitorSetup
    monitorToggle
  ];
  
  # Create user config directory and symlink
  system.activationScripts.hyprlandConfig = ''
    mkdir -p /home/eric/.config/hypr
    chown eric:users /home/eric/.config/hypr
    ln -sf /etc/hypr/hyprland.conf /home/eric/.config/hypr/hyprland.conf
    chown -h eric:users /home/eric/.config/hypr/hyprland.conf
  '';
}