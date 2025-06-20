# -----------------------------------------------------------------------------
# FILE: modules/home-manager/ui/hyprland.nix (WINDOW MANAGER)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

let
  wallpaperPath = "/etc/nixos/modules/home-manager/assets/wallpapers/nord-mountains.jpg";
  
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
        "DP-1,1920x1080@60,0x0,1"
        "eDP-1,2560x1600@165,1920x0,1"
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

        # Move windows to workspaces (SUPER + CTRL + numbers)
        "$mod CTRL, 1, movetoworkspace, 1"
        "$mod CTRL, 2, movetoworkspace, 2"
        "$mod CTRL, 3, movetoworkspace, 3"
        "$mod CTRL, 4, movetoworkspace, 4"
        "$mod CTRL, 5, movetoworkspace, 5"
        "$mod CTRL, 6, movetoworkspace, 6"
        "$mod CTRL, 7, movetoworkspace, 7"
        "$mod CTRL, 8, movetoworkspace, 8"
        "$mod CTRL, W, movetoworkspace, 1"
        "$mod CTRL, E, movetoworkspace, 2"
        "$mod CTRL, J, movetoworkspace, 3"
        "$mod CTRL, O, movetoworkspace, 4"
        "$mod CTRL, K, movetoworkspace, 5"
        "$mod CTRL, C, movetoworkspace, 6"
        "$mod CTRL, M, movetoworkspace, 7"
        "$mod CTRL, R, movetoworkspace, 8"

        # Switch to workspaces (SUPER + CTRL + ALT + numbers)
        "$mod CTRL ALT, 1, workspace, 1"
        "$mod CTRL ALT, 2, workspace, 2"
        "$mod CTRL ALT, 3, workspace, 3"
        "$mod CTRL ALT, 4, workspace, 4"
        "$mod CTRL ALT, 5, workspace, 5"
        "$mod CTRL ALT, 6, workspace, 6"
        "$mod CTRL ALT, 7, workspace, 7"
        "$mod CTRL ALT, 8, workspace, 8"
        "$mod CTRL ALT, W, workspace, 1"
        "$mod CTRL ALT, E, workspace, 2"
        "$mod CTRL ALT, J, workspace, 3"
        "$mod CTRL ALT, O, workspace, 4"
        "$mod CTRL ALT, K, workspace, 5"
        "$mod CTRL ALT, C, workspace, 6"
        "$mod CTRL ALT, M, workspace, 7"
        "$mod CTRL ALT, R, workspace, 8"
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
