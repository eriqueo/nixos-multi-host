# hyprland.nix - Dedicated Hyprland Configuration
{ config, pkgs, lib, osConfig, ... }:

let
  # Import Nordic theme from the main config (you'll pass this in)
  # For now, defining it here - you can import it later
  nordic-blue = {
    bg = "#2e3440";
    bg-alt = "#3b4252";
    bg-darker = "#1a1d23";
    fg = "#eceff4";
    fg-alt = "#d8dee9";
    fg-dim = "#4c566a";
    accent = "#5e81ac";
    accent-bright = "#81a1c1";
    accent-dim = "#4c7398";
    red = "#bf616a";
    orange = "#d08770";
    yellow = "#ebcb8b";
    green = "#a3be8c";
    purple = "#b48ead";
    border = "#434c5e";
    selection = "#4c566a";
    urgent = "#bf616a";
  };
  
  theme = nordic-blue;
  
  fonts = {
    mono = "CaskaydiaCove Nerd Font";
    sans = "Inter";
    size = {
      normal = "13";
      large = "15";
    };
  };
in

{
  # Hyprland configuration (desktop only)
  wayland.windowManager.hyprland = lib.mkIf (osConfig.desktop or false) {
    enable = true;
    settings = {
      # Startup applications
      exec-once = [
        "waybar"
        "swaynotificationcenter"
        "hypridle"
        "hyprpaper"
      ];
      
      # Modifier key
      "$mod" = "SUPER";
      
      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      
      # Key bindings
      bind = [
        # Terminal and system
        "$mod, Return, exec, kitty"
        "$mod SHIFT, L, exec, hyprlock"
        "$mod, N, exec, notify-send 'Test' 'Notification system working'"
        "$mod, grave, exec, swaync-client -t -sw"
        
        # Monitor layout switching
        "$mod SHIFT, bracketleft, exec, hyprctl keyword monitor 'eDP-1,2560x1600@165,0x0,1.60' && hyprctl keyword monitor 'DP-2,1920x1080@60,2560x0,1'"
        "$mod SHIFT, bracketright, exec, hyprctl keyword monitor 'DP-2,1920x1080@60,0x0,1' && hyprctl keyword monitor 'eDP-1,2560x1600@165,1920x0,1.60'"
        
        # Window focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        # Window management
        "$mod, F, fullscreen"
        "$mod, Q, killactive"
        "$mod, V, togglefloating"
        
        # Send window to workspace
        "CTRL $mod, 1, movetoworkspace, 1"
        "CTRL $mod, 2, movetoworkspace, 2"
        "CTRL $mod, 3, movetoworkspace, 3"
        "CTRL $mod, 4, movetoworkspace, 4"
        "CTRL $mod, 5, movetoworkspace, 5"
        "CTRL $mod, left, movetoworkspace, -1"
        "CTRL $mod, right, movetoworkspace, +1"
        
        # Switch to workspace
        "CTRL $mod ALT, 1, workspace, 1"
        "CTRL $mod ALT, 2, workspace, 2"
        "CTRL $mod ALT, 3, workspace, 3"
        "CTRL $mod ALT, 4, workspace, 4"
        "CTRL $mod ALT, 5, workspace, 5"
        "CTRL $mod ALT, left, workspace, -1"
        "CTRL $mod ALT, right, workspace, +1"
        
        # Alternative focus
        "$mod SHIFT, left, movefocus, l"
        "$mod SHIFT, right, movefocus, r"
        "$mod SHIFT, up, movefocus, u"
        "$mod SHIFT, down, movefocus, d"
        
        # Move windows
        "$mod ALT, left, movewindow, l"
        "$mod ALT, right, movewindow, r"
        "$mod ALT, up, movewindow, u"
        "$mod ALT, down, movewindow, d"
        
        # Window cycling
        "ALT, Tab, cyclenext"
        "ALT SHIFT, Tab, cyclenext, prev"
        
        # Screenshots
        ", Print, exec, hyprshot -m region -o ~/Pictures/screenshots/"
        "CTRL, Print, exec, hyprshot -m output -o ~/Pictures/screenshots/"
        "SHIFT, Print, exec, hyprshot -m region -o ~/Pictures/screenshots/ --clipboard-only"
        
        # Applications
        "$mod, Space, exec, wofi --show drun"
        "$mod, E, exec, dolphin"
        "$mod, B, exec, brave"
        
        # Function keys
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ -5%"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];
      
      # Input configuration
      input = {
        follow_mouse = 0;
        kb_layout = "us";
        
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
        };
      };
      
      # Visual configuration
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(5e81ac) rgb(81a1c1) 45deg";
        "col.inactive_border" = "rgb(434c5e)";
        layout = "dwindle";
      };
      
      # Decoration with Nordic theme
      decoration = {
        rounding = 8;
        
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
          ignore_opacity = true;
          noise = 0.0117;
          contrast = 1.0;
          brightness = 1.0;
          xray = false;
        };

        # Nordic shadow settings
        shadow = {
          enabled = true;
          range = 6;
          render_power = 3;
          offset = "0 2";
          color = "rgba(${builtins.substring 1 6 theme.bg-darker}80)";
          color_inactive = "rgba(${builtins.substring 1 6 theme.bg-darker}40)";
        };
        
        # Dimming inactive windows
        dim_inactive = false;
        dim_strength = 0.1;
      };
      
      # Nordic animations
      animations = {
        enabled = true;
        
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1" 
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
        ];
        
        animation = [
          "windows, 1, 6, wind, slide"
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 1, liner"
          "borderangle, 1, 30, liner, loop"
          "fade, 1, 10, default"
          "workspaces, 1, 5, wind"
        ];
      };
      
      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
      };
      
      # Misc settings
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 0;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
      };
    };
  };

  # Waybar configuration (desktop only)
  programs.waybar = lib.mkIf (osConfig.desktop or false) {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
    systemd.enable = false;
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 4;
        
        modules-left = [ "hyprland/workspaces"  ];
        modules-center = [ "clock" "hyprland/window" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];
        
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            urgent = "";
            focused = "";
            default = "";
          };
          persistent-workspaces = {
            "*" = 5; # Show 5 workspaces on all monitors
          };
        };
        
        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };
        
        clock = {
          timezone = "America/Denver";
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        
        cpu = {
          format = "{usage}% ";
          tooltip = false;
          interval = 1;
        };
        
        memory = {
          format = "{}% ";
          interval = 1;
        };
        
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          on-click = "nm-connection-editor";
          tooltip-format = "{ifname} via {gwaddr}";
        };
        
        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };
        
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };
        
        tray = {
          spacing = 10;
        };
      };
    };
    
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "${fonts.mono}", monospace;
        font-size: ${fonts.size.normal}px;
        min-height: 0;
      }
      
      window#waybar {
        background-color: ${theme.bg};
        border-bottom: 2px solid ${theme.accent};
        color: ${theme.fg};
        opacity: 0.95;
      }
      
      window#waybar.hidden {
        opacity: 0.2;
      }
      
      #workspaces {
        margin: 0 4px;
      }
      
      #workspaces button {
        padding: 0 8px;
        background-color: transparent;
        color: ${theme.fg-alt};
        border-bottom: 3px solid transparent;
        border-radius: 0;
      }
      
      #workspaces button:hover {
        background: ${theme.bg-alt};
        color: ${theme.fg};
      }
      
     #workspaces button.active {
        background-color: ${theme.accent};
        color: ${theme.bg};
        border-bottom: 2px solid ${theme.accent-bright};
      }
      
     #workspaces button.urgent {
         background-color: ${theme.urgent};
         color: ${theme.fg};
       }
      
      #window,
      #clock,
      #battery,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
       padding: 0 10px;
       color: ${theme.fg};
       background: ${theme.bg-alt};
       margin: 2px;
       border-radius: 4px;
      }
      
      #window {
        background: transparent;
        margin: 0 4px;
        color: ${theme.accent};
        font-weight: bold;
      }
      
      #clock {
        background: ${theme.accent};
        color: ${theme.bg};
        font-weight: bold;
      }
          
      #battery {
        background: ${theme.green};
        color: ${theme.bg};
      }
          
      #battery.charging, #battery.plugged {
        background: ${theme.accent-bright};
        color: ${theme.bg};
      }
      
      @keyframes blink {
        to {
          background-color: ${theme.urgent};
          color: #000000;
        }
      }
      
      #battery.warning:not(.charging) {
         background: ${theme.yellow};
         color: ${theme.bg};
      }
          
      #battery.critical:not(.charging) {
         background: ${theme.red};
         color: ${theme.fg};
         animation: blink 0.5s linear infinite alternate;
      }
      
     #cpu {
         background: ${theme.accent-dim};
         color: ${theme.fg};
      }
          
      #memory {
         background: ${theme.purple};
         color: ${theme.fg};
      }
          
      #network {
         background: ${theme.accent-bright};
         color: ${theme.bg};
      }
          
      #network.disconnected {
         background: ${theme.red};
         color: ${theme.fg};
      }
      
      #pulseaudio {
         background: ${theme.yellow};
         color: ${theme.bg};
      }
    
      #pulseaudio.muted {
         background: ${theme.fg-dim};
         color: ${theme.fg};
      }
    
      #tray {
         background: ${theme.bg-alt};
      }
      
      #tray > .passive {
        -gtk-icon-effect: dim;
      }
      
      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: ${theme.red};
      }
    '';
  };
}
