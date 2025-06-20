# -----------------------------------------------------------------------------
# FILE: modules/home-manager/ui/hyprland.nix (WINDOW MANAGER)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

let
  wallpaperPath = "/etc/nixos/modules/home-manager/assets/wallpapers/nord-mountains.jpg";
  workspaceOverview = pkgs.writeScriptBin "workspace-overview" ''
    #!/usr/bin/env bash
    
    # Get all workspaces with their contents
    WORKSPACES=$(hyprctl workspaces -j | ${pkgs.jq}/bin/jq -r '
      .[] | 
      if .windows > 0 then
        "\(.id): \(.windows) windows - \(.lastwindowtitle // "empty")"
      else
        "\(.id): empty"
      end
    ' | sort -n)
    
    # Use wofi to select workspace
    SELECTED=$(echo "$WORKSPACES" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Go to workspace:" --lines 10)
    
    if [[ -n "$SELECTED" ]]; then
      WORKSPACE_ID=$(echo "$SELECTED" | cut -d: -f1)
      ${pkgs.hyprsome}/bin/hyprsome workspace "$WORKSPACE_ID"
    fi
  '';
  # Monitor toggle script
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
in
{
  # Install packages needed for Hyprland
  home.packages = with pkgs; [
    # Core Hyprland tools
    wofi
    hyprshot
    hypridle
    hyprpaper
    workspaceOverview
    # Clipboard management
    cliphist
    wl-clipboard
    
    # System tools for Hyprland
    brightnessctl
    networkmanager
    wirelesstools
    
    # Custom scripts
    monitorToggle
  ];

  # Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    
    settings = {
      # Monitor setup
      monitor = [
        "eDP-1,2560x1600@165,0x0,1"      # Laptop at 0,0 (left)
        "DP-1,1920x1080@60,2560x0,1"     # External at 2560,0 (right) 
      ];
      workspace = [
          # Monitor ID 0 (eDP-1) gets workspaces 1-8
          "1,monitor:eDP-1"
          "2,monitor:eDP-1" 
          "3,monitor:eDP-1"
          "4,monitor:eDP-1"
          "5,monitor:eDP-1"
          "6,monitor:eDP-1"
          "7,monitor:eDP-1"
          "8,monitor:eDP-1"
          
          # Monitor ID 1 (DP-1) gets workspaces 11-18  
          "11,monitor:DP-1"
          "12,monitor:DP-1"
          "13,monitor:DP-1"
          "14,monitor:DP-1"
          "15,monitor:DP-1"
          "16,monitor:DP-1"
          "17,monitor:DP-1"
          "18,monitor:DP-1"
        ];

      # Startup applications
      exec-once = [
        "hypr-startup"
        "hyprpaper"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
      };
        windowrulev2 = [
          "tile,class:^(Chromium-browser)$,title:^.*JobTread.*$"
          "workspace 3,class:^(Chromium-browser)$,title:^.*JobTread.*$"
        ];
      # Variables
      "$mod" = "SUPER";

      # Keybindings
      bind = [
        # Window/Session Management
        "$mod, Return, exec, kitty"
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, Space, exec, wofi --show drun"
        "$mod, B, exec, librewolf"
        "$mod, E, exec, electron-mail"
        "$mod SHIFT, M, exec, monitor-toggle"
        "$mod, TAB, exec, workspace-overview"

        # Screenshots
        ", Print, exec, hyprshot -m region -o ~/Pictures/01-screenshots"
        "SHIFT, Print, exec, hyprshot -m region -c"

        # Focus movement (SUPER + arrows)
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Window movement within workspace (SUPER + ALT + arrows)
        "$mod ALT, left, movewindow, l"
        "$mod ALT, right, movewindow, r"
        "$mod ALT, up, movewindow, u"
        "$mod ALT, down, movewindow, d"
        "$mod ALT, H, layoutmsg, orientationleft"
        "$mod ALT, V, layoutmsg, orientationtop"

         # MOVE WINDOWS with hyprsome
        "$mod CTRL, 1, exec, hyprsome move 1"
        "$mod CTRL, 2, exec, hyprsome move 2"
        "$mod CTRL, 3, exec, hyprsome move 3"
        "$mod CTRL, 4, exec, hyprsome move 4"
        "$mod CTRL, 5, exec, hyprsome move 5"
        "$mod CTRL, 6, exec, hyprsome move 6"
        "$mod CTRL, 7, exec, hyprsome move 7"
        "$mod CTRL, 8, exec, hyprsome move 8"
        
        # Letter mappings for moving windows
        "$mod CTRL, W, exec, hyprsome move 1"
        "$mod CTRL, E, exec, hyprsome move 2"
        "$mod CTRL, J, exec, hyprsome move 3"
        "$mod CTRL, O, exec, hyprsome move 4"
        "$mod CTRL, K, exec, hyprsome move 5"
        "$mod CTRL, C, exec, hyprsome move 6"
        "$mod CTRL, M, exec, hyprsome move 7"
        "$mod CTRL, R, exec, hyprsome move 8"

        # WORKSPACE SWITCHING with hyprsome (per-monitor)
        "$mod CTRL ALT, 1, exec, hyprsome workspace 1"
        "$mod CTRL ALT, 2, exec, hyprsome workspace 2"
        "$mod CTRL ALT, 3, exec, hyprsome workspace 3"
        "$mod CTRL ALT, 4, exec, hyprsome workspace 4"
        "$mod CTRL ALT, 5, exec, hyprsome workspace 5"
        "$mod CTRL ALT, 6, exec, hyprsome workspace 6"
        "$mod CTRL ALT, 7, exec, hyprsome workspace 7"
        "$mod CTRL ALT, 8, exec, hyprsome workspace 8"
        
        # Letter mappings for workspace switching
        "$mod CTRL ALT, W, exec, hyprsome workspace 1"
        "$mod CTRL ALT, E, exec, hyprsome workspace 2"
        "$mod CTRL ALT, J, exec, hyprsome workspace 3"
        "$mod CTRL ALT, O, exec, hyprsome workspace 4"
        "$mod CTRL ALT, K, exec, hyprsome workspace 5"
        "$mod CTRL ALT, C, exec, hyprsome workspace 6"
        "$mod CTRL ALT, M, exec, hyprsome workspace 7"
        "$mod CTRL ALT, R, exec, hyprsome workspace 8"
        "$mod CTRL ALT, left, workspace, e-1"
        "$mod CTRL ALT, right, workspace, e+1"
      ];
    };
  };

  # Hyprpaper configuration
  home.file.".config/hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperPath}
    wallpaper = eDP-1,${wallpaperPath}
    wallpaper = DP-1,${wallpaperPath}
    splash = false
  '';
}
