# -----------------------------------------------------------------------------
# FILE: modules/home-manager/ui/hyprland.nix (WINDOW MANAGER)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

let
  colors = (import ../../../shared/colors/deep-nord.nix).colors;
in

let
  wallpaperPath = "/etc/nixos/hosts/laptop/modules/assets/wallpapers/nord-mountains.jpg";
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

      # Decoration (rounded corners, blur, etc.)
      decoration = {
        rounding = 12;
        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };
        shadow = {
          enabled = true;
          range = 8;
          render_power = 2;
          color = "rgba(0, 0, 0, 0.4)";
        };
        dim_inactive = false;
      };

      # Animation settings
      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
        ];
        animation = [
          "windows,1,4,easeOutQuint,slide"
          "windowsOut,1,4,easeInOutCubic,slide"
          "border,1,10,default"
          "fade,1,4,default"
          "workspaces,1,4,easeOutQuint,slide"
        ];
      };

      # General settings
      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgba(7daea3ff) rgba(89b482ff) 45deg"; # Gruvbox Material soft teal gradient
        "col.inactive_border" = "rgba(45403daa)"; # Gruvbox Material muted gray
        layout = "dwindle";
        resize_on_border = true;
      };

      # Dwindle layout settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
      };

      # Miscellaneous settings
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 1;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
      };

      windowrulev2 = [
        # Browser rules
        "tile,class:^(Chromium-browser)$,title:^.*JobTread.*$"
        "workspace 3,class:^(Chromium-browser)$,title:^.*JobTread.*$"
        "tile,class:^(chromium-.*|Chromium-.*)$"
        
        # Floating windows
        "float,class:^(pavucontrol)$"
        "float,class:^(blueman-manager)$"
        "size 800 600,class:^(pavucontrol)$"
        
        # Opacity rules
        "opacity 0.95,class:^(kitty)$"
        "opacity 0.90,class:^(thunar)$"
        
        # Workspace assignments
        "workspace 2,class:^(LibreWolf)$"
        "workspace 4,class:^(obsidian)$"
        "workspace 5,class:^(electron-mail)$"
        
        # Picture-in-picture
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"
        "size 640 360,title:^(Picture-in-Picture)$"
        
        # No shadows for certain windows
        "noshadow,floating:0"
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
        "$mod, O, exec, obsidian"
        "$mod, E, exec, electron-mail"
        "$mod, N, exec, kitty nvim"
        "$mod SHIFT, M, exec, monitor-toggle"
        "$mod, TAB, exec, workspace-overview"
        "$mod, T, togglefloating"
        # Screenshots
        ", Print, exec, hyprshot -m region -o ~/Pictures/01-screenshots"
        "SHIFT, Print, exec, hyprshot -m region -c"
        "CTRL, Print, exec, hyprshot -m window -o ~/Pictures/01-screenshots"
        "ALT, Print, exec, hyprshot -m output -o ~/Pictures/01-screenshots"

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
        
        # Volume controls
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        
        # Brightness controls
        ", XF86MonBrightnessUp, exec, brightnessctl set 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
        
        # Clipboard history
        "$mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
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
