
# -----------------------------------------------------------------------------
# FILE: modules/home-manager/ui/waybar.nix (STATUS BAR)
# -----------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

let
  colors = (import ../../../shared/colors/deep-nord.nix).colors;
  
  # GPU Management Scripts
  gpuStatus = pkgs.writeScriptBin "gpu-status" ''
    #!/usr/bin/env bash
    # Check current GPU status and return JSON for waybar
    
    GPU_MODE_FILE="/tmp/gpu-mode"
    DEFAULT_MODE="intel"
    
    # Initialize mode file if it doesn't exist
    if [[ ! -f "$GPU_MODE_FILE" ]]; then
      echo "$DEFAULT_MODE" > "$GPU_MODE_FILE"
    fi
    
    CURRENT_MODE=$(cat "$GPU_MODE_FILE" 2>/dev/null || echo "$DEFAULT_MODE")
    
    # Get current GPU renderer
    CURRENT_GPU=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs || echo "Unknown")
    
    # Get GPU power consumption (if available)
    NVIDIA_POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "0")
    
    case "$CURRENT_MODE" in
      "intel")
        ICON="󰢮"
        CLASS="intel"
        TOOLTIP="Intel Mode: $CURRENT_GPU"
        ;;
      "nvidia")
        ICON="󰾲" 
        CLASS="nvidia"
        TOOLTIP="NVIDIA Mode: $CURRENT_GPU ($NVIDIA_POWER W)"
        ;;
      "performance")
        ICON="⚡"
        CLASS="performance"
        TOOLTIP="Performance Mode: Auto-GPU Selection ($NVIDIA_POWER W)"
        ;;
      *)
        ICON="󰢮"
        CLASS="intel"
        TOOLTIP="Intel Mode (Default): $CURRENT_GPU"
        ;;
    esac
    
    # Output JSON for waybar
    echo "{\"text\": \"$ICON\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
  '';
  
  gpuToggle = pkgs.writeScriptBin "gpu-toggle" ''
    #!/usr/bin/env bash
    # Toggle between GPU modes
    
    GPU_MODE_FILE="/tmp/gpu-mode"
    CURRENT_MODE=$(cat "$GPU_MODE_FILE" 2>/dev/null || echo "intel")
    
    case "$CURRENT_MODE" in
      "intel")
        echo "performance" > "$GPU_MODE_FILE"
        notify-send "GPU Mode" "Switched to Performance Mode ⚡" -i gpu-card
        ;;
      "performance")
        echo "intel" > "$GPU_MODE_FILE"
        notify-send "GPU Mode" "Switched to Intel Mode 󰢮" -i gpu-card
        ;;
      *)
        echo "intel" > "$GPU_MODE_FILE"
        notify-send "GPU Mode" "Reset to Intel Mode 󰢮" -i gpu-card
        ;;
    esac
    
    # Refresh waybar
    pkill -SIGUSR1 waybar 2>/dev/null || true
  '';
  
  gpuLaunch = pkgs.writeScriptBin "gpu-launch" ''
    #!/usr/bin/env bash
    # Launch application with appropriate GPU based on current mode
    
    if [[ $# -eq 0 ]]; then
      echo "Usage: gpu-launch <application> [args...]"
      exit 1
    fi
    
    GPU_MODE_FILE="/tmp/gpu-mode"
    CURRENT_MODE=$(cat "$GPU_MODE_FILE" 2>/dev/null || echo "intel")
    
    # Check if next-nvidia flag exists (for right-click override)
    NEXT_NVIDIA_FILE="/tmp/gpu-next-nvidia"
    if [[ -f "$NEXT_NVIDIA_FILE" ]]; then
      rm "$NEXT_NVIDIA_FILE"
      exec nvidia-offload "$@"
    fi
    
    case "$CURRENT_MODE" in
      "performance")
        # In performance mode, use NVIDIA for intensive apps, Intel for light ones
        case "$1" in
          blender|gimp|inkscape|kdenlive|obs|steam|wine|chromium|firefox|librewolf)
            exec nvidia-offload "$@"
            ;;
          *)
            exec "$@"
            ;;
        esac
        ;;
      "nvidia")
        exec nvidia-offload "$@"
        ;;
      *)
        exec "$@"
        ;;
    esac
  '';
  
  gpuMenu = pkgs.writeScriptBin "gpu-menu" ''
    #!/usr/bin/env bash
    # Right-click GPU menu
    
    CHOICE=$(echo -e "Launch next app with NVIDIA\nView GPU usage\nOpen nvidia-settings\nToggle Performance Mode" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "GPU Options:")
    
    case "$CHOICE" in
      "Launch next app with NVIDIA")
        touch /tmp/gpu-next-nvidia
        notify-send "GPU Mode" "Next app will use NVIDIA 󰾲" -i gpu-card
        ;;
      "View GPU usage")
        ${pkgs.kitty}/bin/kitty --title "GPU Monitor" -e ${pkgs.nvtopPackages.full}/bin/nvtop &
        ;;
      "Open nvidia-settings")
        nvidia-settings &
        ;;
      "Toggle Performance Mode")
        gpu-toggle
        ;;
    esac
  '';
  
  # System monitoring scripts
  diskUsage = pkgs.writeScriptBin "disk-usage-gui" ''
    #!/usr/bin/env bash
    ${pkgs.baobab}/bin/baobab &
  '';
  
  systemMonitor = pkgs.writeScriptBin "system-monitor" ''
    #!/usr/bin/env bash
    ${pkgs.kitty}/bin/kitty --title "System Monitor" -e ${pkgs.btop}/bin/btop &
  '';
  
  networkSettings = pkgs.writeScriptBin "network-settings" ''
    #!/usr/bin/env bash
    ${pkgs.networkmanagerapplet}/bin/nm-connection-editor &
  '';
  
  powerSettings = pkgs.writeScriptBin "power-settings" ''
    #!/usr/bin/env bash
    # Try different power management GUIs
    if command -v gnome-power-statistics >/dev/null 2>&1; then
      gnome-power-statistics &
    elif command -v xfce4-power-manager-settings >/dev/null 2>&1; then
      xfce4-power-manager-settings &
    else
      ${pkgs.kitty}/bin/kitty --title "Power Info" -e sh -c "${pkgs.acpi}/bin/acpi -V && ${pkgs.powertop}/bin/powertop --dump && read" &
    fi
  '';
  
  sensorViewer = pkgs.writeScriptBin "sensor-viewer" ''
    #!/usr/bin/env bash
    if command -v mission-center >/dev/null 2>&1; then
      mission-center &
    else
      ${pkgs.kitty}/bin/kitty --title "Sensors" -e sh -c "${pkgs.lm_sensors}/bin/sensors && read" &
    fi
  '';
  
in

{
  # Waybar dependencies
  home.packages = with pkgs; [
    pavucontrol
    swaynotificationcenter
    wlogout  # Power menu
    
    # GPU management scripts
    gpuStatus
    gpuToggle
    gpuLaunch
    gpuMenu
    
    # System monitoring tools
    diskUsage
    systemMonitor
    networkSettings
    powerSettings
    sensorViewer
    
    # Additional GUI tools
    baobab              # Disk usage analyzer
    networkmanagerapplet # Network settings
    nvtopPackages.full   # GPU usage monitor
    mission-center      # Hardware sensors and system monitor GUI
    btop                # System monitor
  ];

  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    
    settings = [{
      layer = "top";
      position = "top";
      height = 60;
      spacing = 4;
      
      modules-left = [
        "hyprland/workspaces"
      ];
      
      modules-center = [
        "hyprland/window"
        "clock"
      ];
      
      modules-right = [
        "custom/gpu"
        "custom/disk"
        "idle_inhibitor"
        "mpd"
        "pulseaudio"
        "network"
        "memory"
        "cpu"
        "temperature"
        "battery"
        "tray"
        "custom/notification"
        "custom/power"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = false;
        warp-on-scroll = false;
        format = "{icon}";
        format-icons = {
          "1" = "󰈹"; "2" = "󰭹"; "3" = "󰏘"; "4" = "󰎞";
          "5" = "󰕧"; "6" = "󰊢"; "7" = "󰋩"; "8" = "󰚌";
          "11" = "󰈹"; "12" = "󰭹"; "13" = "󰏘"; "14" = "󰎞";
          "15" = "󰕧"; "16" = "󰊢"; "17" = "󰋩"; "18" = "󰚌";
          active = "";
          default = "";
        };
      };

      "hyprland/window" = {
        format = "{title}";
        max-length = 50;
        separate-outputs = true;
      };

      mpd = {
        format = "{stateIcon} {artist} - {title}";
        format-disconnected = "󰝛";
        format-stopped = "󰓛";
        unknown-tag = "N/A";
        interval = 5;
        state-icons = {
          paused = "";
          playing = "";
        };
        tooltip-format = "MPD: {artist} - {title}";
        tooltip-format-disconnected = "MPD disconnected";
      };

      tray = {
        spacing = 10;
      };

      clock = {
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format = "{:%H:%M}";
        format-alt = "{:%Y-%m-%d}";
      };

      memory = {
        interval = 30;
        format = "󰍛 {used:0.1f}G";
        max-length = 10;
        tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G ({percentage}%)";
        on-click = "system-monitor";
      };

      cpu = {
        interval = 10;
        format = "󰻠 {usage}%";
        tooltip-format = "CPU Usage: {usage}% ({load})";
        on-click = "system-monitor";
      };

      temperature = {
        thermal-zone = 2;
        critical-threshold = 80;
        format = " {temperatureC}°C";
        format-critical = " {temperatureC}°C";
        tooltip-format = "CPU Temperature: {temperatureC}°C";
        on-click = "sensor-viewer";
      };

      battery = {
        states = {
          good = 95;
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰂄 {capacity}%";
        format-icons = ["󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
        tooltip-format = "Battery: {capacity}% ({time})";
        on-click = "power-settings";
      };

      network = {
        format-wifi = "󰤨 {essid}";
        format-ethernet = "󰈀";
        format-linked = "󰈀 No IP";
        format-disconnected = "󰤭";
        tooltip-format = "{ifname} via {gwaddr}";
        on-click = "network-settings";
      };

      pulseaudio = {
        scroll-step = 1;
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = {
          default = ["󰕿" "󰖀" "󰕾"];
        };
        on-click = "pavucontrol";
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
        tooltip-format-activated = "Idle inhibitor active";
        tooltip-format-deactivated = "Idle inhibitor inactive";
      };

      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='red'><sup></sup></span>";
          none = "";
          dnd-notification = "<span foreground='red'><sup></sup></span>";
          dnd-none = "";
          inhibited-notification = "<span foreground='red'><sup></sup></span>";
          inhibited-none = "";
          dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
          dnd-inhibited-none = "";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };

      "custom/gpu" = {
        format = "{icon}";
        return-type = "json";
        exec = "gpu-status";
        interval = 5;
        on-click = "gpu-toggle";
        on-click-right = "gpu-menu";
        tooltip = true;
      };
      
      "custom/disk" = {
        format = "󰋊 {percentage}%";
        return-type = "json";
        exec = pkgs.writeShellScript "disk-usage" ''
          USAGE=$(df / | awk 'NR==2 {print int($5)}' | sed 's/%//')
          TOOLTIP="Disk Usage: $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
          echo "{\"text\": \"$USAGE\", \"percentage\": $USAGE, \"tooltip\": \"$TOOLTIP\"}"
        '';
        interval = 30;
        on-click = "disk-usage-gui";
        tooltip = true;
      };

      "custom/power" = {
        format = "󰐥";
        tooltip = false;
        on-click = "wlogout || systemctl poweroff";
      };
    }];

    style = ''
     * {
       font-family: "JetBrainsMono Nerd Font", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
       font-size: 16px;
       border: none;
       border-radius: 0;
       min-height: 0;
       margin: 0;
       padding: 0;
     }
     
     window#waybar {
       background: rgba(40, 40, 40, 0.95); /* Gruvbox Material background */
       color: ${colors.css.foreground};
       border-bottom: 2px solid ${colors.css.accent};
       transition-property: background-color;
       transition-duration: 0.5s;
     }
     
     window#waybar.hidden {
       opacity: 0.2;
     }
     
     /* Workspaces */
     #workspaces {
       margin: 0 4px;
       background: transparent;
     }
     
     #workspaces button {
       padding: 4px 8px;
       background: transparent;
       color: ${colors.css.accent};
       border: none;
       border-bottom: 2px solid transparent;
       border-radius: 0;
       transition: all 0.3s ease-in-out;
       min-width: 24px;
     }
     
     #workspaces button:hover {
       background: rgba(125, 174, 163, 0.2);
       border-bottom: 2px solid ${colors.css.accent};
       box-shadow: none;
     }
     
     #workspaces button.active {
       background: rgba(125, 174, 163, 0.3);
       color: ${colors.css.accent};
       border-bottom: 2px solid ${colors.css.accent};
       font-weight: bold;
     }
     
     #workspaces button.urgent {
       background: rgba(234, 105, 98, 0.3);
       color: ${colors.css.error};
       border-bottom: 2px solid ${colors.css.error};
       animation: blink 1s linear infinite alternate;
     }
     
     /* Window title */
     #window {
       margin: 0 8px;
       color: #d8dee9;
       font-weight: normal;
     }
     
     /* Center modules */
     #clock {
       margin: 0 8px;
       color: ${colors.css.foreground};
       font-weight: bold;
       background: rgba(76, 86, 106, 0.4);
       padding: 0 12px;
       border-radius: 8px;
     }
     
     /* Right modules */
     #memory,
     #cpu,
     #temperature,
     #battery,
     #network,
     #pulseaudio,
     #mpd,
     #idle_inhibitor,
     #tray,
     #custom-gpu,
     #custom-disk,
     #custom-notification,
     #custom-power {
       margin: 0 2px;
       padding: 0 8px;
       background: rgba(76, 86, 106, 0.4);
       border-radius: 8px;
       font-weight: 500;
     }
     
     /* Individual module colors */
     #memory {
       color: #a3be8c;
     }
     
     #cpu {
       color: #ebcb8b;
     }
     
     #temperature {
       color: #81a1c1;
     }
     
     #temperature.critical {
       color: #bf616a;
       background: rgba(191, 97, 106, 0.3);
       animation: blink 1s linear infinite alternate;
     }
     
     #battery {
       color: #88c0d0;
     }
     
     #battery.charging {
       color: #a3be8c;
       background: rgba(163, 190, 140, 0.2);
     }
     
     #battery.warning:not(.charging) {
       color: #ebcb8b;
       background: rgba(235, 203, 139, 0.2);
       animation: blink 1s linear infinite alternate;
     }
     
     #battery.critical:not(.charging) {
       color: #bf616a;
       background: rgba(191, 97, 106, 0.3);
       animation: blink 1s linear infinite alternate;
     }
     
     #network {
       color: #5e81ac;
     }
     
     #network.disconnected {
       color: #bf616a;
       background: rgba(191, 97, 106, 0.2);
     }
     
     #pulseaudio {
       color: #b48ead;
     }
     
     #pulseaudio.muted {
       color: #4c566a;
       background: rgba(76, 86, 106, 0.6);
     }
     
     #mpd {
       color: #d08770;
     }
     
     #mpd.disconnected {
       color: #4c566a;
     }
     
     #mpd.stopped {
       color: #4c566a;
     }
     
     #mpd.paused {
       color: #d08770;
       font-style: italic;
     }
     
     #custom-power {
       color: #bf616a;
       margin-right: 8px;
       font-size: 14px;
     }
     
     #idle_inhibitor {
       color: #ebcb8b;
     }
     
     #idle_inhibitor.activated {
       background: rgba(235, 203, 139, 0.3);
       color: #ebcb8b;
     }
     
     #custom-notification {
       color: #81a1c1;
       font-size: 16px;
     }
     
     #custom-notification.notification {
       background: rgba(191, 97, 106, 0.3);
       animation: blink 1s linear infinite alternate;
     }

     #custom-gpu {
       color: #7daea3;
       font-size: 16px;
     }
     
     #custom-gpu.intel {
       color: #81a1c1;
       background: rgba(129, 161, 193, 0.2);
     }
     
     #custom-gpu.nvidia {
       color: #76b900;
       background: rgba(118, 185, 0, 0.2);
     }
     
     #custom-gpu.performance {
       color: #ebcb8b;
       background: rgba(235, 203, 139, 0.3);
       animation: gpu-pulse 2s ease-in-out infinite alternate;
     }
     
     #custom-disk {
       color: #d08770;
     }
     
     #custom-disk.warning {
       color: #ebcb8b;
       background: rgba(235, 203, 139, 0.2);
     }
     
     #custom-disk.critical {
       color: #bf616a;
       background: rgba(191, 97, 106, 0.3);
       animation: blink 1s linear infinite alternate;
     }

     #custom-power:hover {
       background: rgba(191, 97, 106, 0.3);
       color: #ffffff;
     }
     
     #tray {
       background: transparent;
       margin-right: 4px;
     }
     
     #tray > .passive {
       -gtk-icon-effect: dim;
     }
     
     #tray > .needs-attention {
       -gtk-icon-effect: highlight;
       background-color: #bf616a;
       border-radius: 8px;
     }
     
     /* Animations */
     @keyframes blink {
       to {
         background-color: #bf616a;
         color: #2e3440;
       }
     }
     
     @keyframes gpu-pulse {
       0% {
         background: rgba(235, 203, 139, 0.2);
       }
       100% {
         background: rgba(235, 203, 139, 0.4);
       }
     }
     
     /* Tooltip styling */
     tooltip {
       background: rgba(46, 52, 64, 0.95);
       border: 1px solid #4c566a;
       border-radius: 8px;
       padding: 8px;
     }
     
     tooltip label {
       color: #e5e9f0;
     }
     
     /* Focus effects */
     button:focus {
       background-color: rgba(136, 192, 208, 0.2);
       outline: none;
     }
     '';
  };

  # Fix waybar crashing by ensuring proper Wayland environment in systemd service
  systemd.user.services.waybar = {
    Unit = {
      Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors";
      Documentation = "https://github.com/Alexays/Waybar/wiki/";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
      Requisite = "graphical-session.target";
    };
    
    Service = {
      # Critical: Set Wayland environment variables for proper display access
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_CURRENT_DESKTOP=Hyprland" 
        "XDG_SESSION_DESKTOP=Hyprland"
        "XDG_SESSION_TYPE=wayland"
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
      
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecReload = "kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = "1";
      
      # Additional restart configuration to handle crashes better
      StartLimitBurst = 3;
      StartLimitInterval = 10;
    };
    
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}