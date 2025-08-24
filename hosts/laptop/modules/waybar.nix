# -----------------------------------------------------------------------------
# FILE: modules/home-manager/ui/waybar.nix (STATUS BAR) - ENHANCED VERSION
# -----------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

let
  colors = (import ../../../shared/colors/deep-nord.nix).colors;

  # Enhanced GPU Management Scripts with better feedback
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

    # Get current GPU renderer with better detection
    CURRENT_GPU=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs || echo "Unknown")

    # Get GPU power consumption and temperature (if available)
    NVIDIA_POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "0")
    NVIDIA_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "0")

    case "$CURRENT_MODE" in
      "intel")
        ICON="󰢮"
        CLASS="intel"
        TOOLTIP="Intel Mode: $CURRENT_GPU"
        ;;
      "nvidia")
        ICON="󰾲"
        CLASS="nvidia"
        TOOLTIP="NVIDIA Mode: $CURRENT_GPU\nPower: $NVIDIA_POWER W | Temp: $NVIDIA_TEMP°C"
        ;;
      "performance")
        ICON="⚡"
        CLASS="performance"
        TOOLTIP="Performance Mode: Auto-GPU Selection\nNVIDIA: $NVIDIA_POWER W | $NVIDIA_TEMP°C"
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

  # Enhanced workspace switcher with better feedback
  workspaceSwitcher = pkgs.writeScriptBin "workspace-switcher" ''
    #!/usr/bin/env bash
    # Enhanced workspace switching with visual feedback

    if [[ $# -eq 0 ]]; then
      echo "Usage: workspace-switcher <workspace_number>"
      exit 1
    fi

    WORKSPACE=$1

    # Get current workspace
    CURRENT=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.workspace.id' 2>/dev/null || echo "1")

    if [[ "$CURRENT" != "$WORKSPACE" ]]; then
      # Switch workspace
      hyprctl dispatch workspace "$WORKSPACE"

      # Show notification with workspace info
      WORKSPACE_INFO=$(hyprctl workspaces -j | ${pkgs.jq}/bin/jq -r ".[] | select(.id==$WORKSPACE) | \"Workspace $WORKSPACE: \(.windows) windows\"" 2>/dev/null || echo "Workspace $WORKSPACE")
      notify-send "Workspace" "$WORKSPACE_INFO" -t 1000 -i desktop
    fi
  '';

  # System resource monitor with alerts
  resourceMonitor = pkgs.writeScriptBin "resource-monitor" ''
    #!/usr/bin/env bash
    # Monitor system resources and show alerts

    # CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    CPU_NUM=$(echo "$CPU_USAGE" | cut -d'.' -f1 | grep -o '[0-9]*' || echo "0")

    # Memory usage
    MEM_INFO=$(free | grep Mem)
    MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
    MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
    MEM_PERCENT=$(( MEM_USED * 100 / MEM_TOTAL ))

    # Temperature
    TEMP=$(sensors 2>/dev/null | grep -E "(Core 0|Tctl)" | head -1 | awk '{print $3}' | sed 's/+//;s/°C.*//' || echo "0")
    TEMP_NUM=$(echo "$TEMP" | cut -d'.' -f1 | grep -o '[0-9]*' || echo "0")

    # Check for alerts
    ALERTS=""
   if [[ -n "$CPU_NUM" && "$CPU_NUM" =~ ^[0-9]+$ && $CPU_NUM -gt 80 ]]; then
     ALERTS="$ALERTS🔥 CPU: ''${CPU_NUM}% "
   fi
   if [[ -n "$MEM_PERCENT" && "$MEM_PERCENT" =~ ^[0-9]+$ && $MEM_PERCENT -gt 85 ]]; then
     ALERTS="$ALERTS🔥 RAM: ''${MEM_PERCENT}% "
   fi
   if [[ -n "$TEMP_NUM" && "$TEMP_NUM" =~ ^[0-9]+$ && $TEMP_NUM -gt 75 ]]; then
     ALERTS="$ALERTS🔥 TEMP: ''${TEMP_NUM}°C "
   fi
   if [[ -n "$TEMP_NUM" && "$TEMP_NUM" =~ ^[0-9]+$ && $TEMP_NUM -gt 75 ]]; then
     ALERTS="$ALERTS🔥 TEMP: ''${TEMP_NUM}°C "
   fi

  '';

  # Enhanced network status with connection quality
  networkStatus = pkgs.writeScriptBin "network-status" ''
    #!/usr/bin/env bash
    # Enhanced network status with quality indicators

    # Get active connection
    ACTIVE_CONN=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active | head -1)

    if [[ -z "$ACTIVE_CONN" ]]; then
      echo "{\"text\": \"󰤭\", \"class\": \"disconnected\", \"tooltip\": \"No network connection\"}"
      exit 0
    fi

    CONN_NAME=$(echo "$ACTIVE_CONN" | cut -d: -f1)
    CONN_TYPE=$(echo "$ACTIVE_CONN" | cut -d: -f2)
    DEVICE=$(echo "$ACTIVE_CONN" | cut -d: -f3)

    if [[ "$CONN_TYPE" == "wifi" ]]; then
      # Get WiFi signal strength
      SIGNAL=$(nmcli -f IN-USE,SIGNAL dev wifi | grep "^\*" | awk '{print $2}')
      SPEED=$(iw dev "$DEVICE" link 2>/dev/null | grep "tx bitrate" | awk '{print $3 " " $4}' || echo "Unknown")

      if [[ $SIGNAL -gt 75 ]]; then
        ICON="󰤨"
        CLASS="excellent"
      elif [[ $SIGNAL -gt 50 ]]; then
        ICON="󰤥"
        CLASS="good"
      elif [[ $SIGNAL -gt 25 ]]; then
        ICON="󰤢"
        CLASS="fair"
      else
        ICON="󰤟"
        CLASS="poor"
      fi

      TOOLTIP="WiFi: $CONN_NAME\nSignal: $SIGNAL%\nSpeed: $SPEED"
    else
      ICON="󰈀"
      CLASS="ethernet"
      SPEED=$(ethtool "$DEVICE" 2>/dev/null | grep "Speed:" | awk '{print $2}' || echo "Unknown")
      TOOLTIP="Ethernet: $CONN_NAME\nSpeed: $SPEED"
    fi

    echo "{\"text\": \"$ICON\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
  '';

  # Battery health monitor
  batteryHealth = pkgs.writeScriptBin "battery-health" ''
    #!/usr/bin/env bash
    # Monitor battery health and provide detailed info

    BATTERY_PATH="/sys/class/power_supply/BAT0"

    if [[ ! -d "$BATTERY_PATH" ]]; then
      echo "{\"text\": \"󰂑\", \"tooltip\": \"No battery detected\"}"
      exit 0
    fi

    CAPACITY=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "0")
    STATUS=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")
    HEALTH=$(cat "$BATTERY_PATH/health" 2>/dev/null || echo "Unknown")
    CYCLE_COUNT=$(cat "$BATTERY_PATH/cycle_count" 2>/dev/null || echo "Unknown")

    # Calculate time remaining
    if [[ "$STATUS" == "Discharging" ]]; then
      POWER_NOW=$(cat "$BATTERY_PATH/power_now" 2>/dev/null || echo "0")
      ENERGY_NOW=$(cat "$BATTERY_PATH/energy_now" 2>/dev/null || echo "0")

      if [[ $POWER_NOW -gt 0 ]]; then
        TIME_REMAINING=$(( ENERGY_NOW / POWER_NOW ))
        HOURS=$(( TIME_REMAINING ))
        MINUTES=$(( (TIME_REMAINING * 60) % 60 ))
        TIME_STR="${HOURS}h ${MINUTES}m"
      else
        TIME_STR="Unknown"
      fi
    else
      TIME_STR="N/A"
    fi

    # Choose icon based on capacity and status
    if [[ "$STATUS" == "Charging" ]]; then
      ICON="󰂄"
      CLASS="charging"
    elif [[ $CAPACITY -gt 90 ]]; then
      ICON="󰁹"
      CLASS="full"
    elif [[ $CAPACITY -gt 75 ]]; then
      ICON="󰂂"
      CLASS="high"
    elif [[ $CAPACITY -gt 50 ]]; then
      ICON="󰁿"
      CLASS="medium"
    elif [[ $CAPACITY -gt 25 ]]; then
      ICON="󰁼"
      CLASS="low"
    else
      ICON="󰁺"
      CLASS="critical"
    fi

    TOOLTIP="Battery: $CAPACITY%\nStatus: $STATUS\nHealth: $HEALTH\nCycles: $CYCLE_COUNT\nTime: $TIME_STR"

    echo "{\"text\": \"$ICON $CAPACITY%\", \"class\": \"$CLASS\", \"tooltip\": \"$TOOLTIP\"}"
  '';

  # System scripts (keeping existing ones)
  gpuToggle = pkgs.writeScriptBin "gpu-toggle" ''
    #!/usr/bin/env bash
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

    pkill -SIGUSR1 waybar 2>/dev/null || true
  '';

  gpuLaunch = pkgs.writeScriptBin "gpu-launch" ''
    #!/usr/bin/env bash
    if [[ $# -eq 0 ]]; then
      echo "Usage: gpu-launch <application> [args...]"
      exit 1
    fi

    GPU_MODE_FILE="/tmp/gpu-mode"
    CURRENT_MODE=$(cat "$GPU_MODE_FILE" 2>/dev/null || echo "intel")

    NEXT_NVIDIA_FILE="/tmp/gpu-next-nvidia"
    if [[ -f "$NEXT_NVIDIA_FILE" ]]; then
      rm "$NEXT_NVIDIA_FILE"
      exec nvidia-offload "$@"
    fi

    case "$CURRENT_MODE" in
      "performance")
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
  # Enhanced dependencies
  home.packages = with pkgs; [
    pavucontrol
    swaynotificationcenter
    wlogout

    # GPU management scripts
    gpuStatus
    gpuToggle
    gpuLaunch
    gpuMenu

    # Enhanced system monitoring
    workspaceSwitcher
    resourceMonitor
    networkStatus
    batteryHealth
    diskUsage
    systemMonitor
    networkSettings
    powerSettings
    sensorViewer

    # Additional tools for enhanced functionality
    baobab
    networkmanagerapplet
    nvtopPackages.full
    mission-center
    btop
    lm_sensors
    ethtool
    iw

    # Portal packages
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
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
        "hyprland/submap"
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
        "custom/network"
        "memory"
        "cpu"
        "temperature"
        "custom/battery"
        "tray"
        "custom/notification"
        "custom/power"
      ];

      # Enhanced workspaces with better visual feedback
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
          urgent = "";
        };
        persistent-workspaces = {
          "1" = [];
          "2" = [];
          "3" = [];
          "4" = [];
          "5" = [];
          "6" = [];
          "7" = [];
          "8" = [];
        };
        on-click = "activate";
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
      };

      # Show current submap (resize mode, etc.)
      "hyprland/submap" = {
        format = "✨ {}";
        max-length = 8;
        tooltip = false;
      };

      "hyprland/window" = {
        format = "{title}";
        max-length = 50;
        separate-outputs = true;
        rewrite = {
          "(.*) — Mozilla Firefox" = "🌍 $1";
          "(.*) - Google Chrome" = "🌍 $1";
          "(.*) - Chromium" = "🌍 $1";
          "(.*) - Visual Studio Code" = "💻 $1";
          "(.*) - nvim" = "📝 $1";
        };
      };

      # Enhanced MPD with better controls
      mpd = {
        format = "{stateIcon} {artist} - {title}";
        format-disconnected = "󰝛";
        format-stopped = "󰓛";
        unknown-tag = "N/A";
        interval = 2;
        consume-icons = {
          on = " ";
        };
        random-icons = {
          off = "<span color=\"#f53c3c\"></span> ";
          on = " ";
        };
        repeat-icons = {
          on = " ";
        };
        single-icons = {
          on = "1 ";
        };
        state-icons = {
          paused = "";
          playing = "";
        };
        tooltip-format = "MPD (connected)";
        tooltip-format-disconnected = "MPD (disconnected)";
        on-click = "mpc toggle";
        on-click-right = "mpc next";
        on-click-middle = "mpc prev";
        on-scroll-up = "mpc volume +2";
        on-scroll-down = "mpc volume -2";
      };

      tray = {
        spacing = 10;
        icon-size = 18;
      };

      # Enhanced clock with multiple formats
      clock = {
        interval = 1;
        format = "{:%H:%M:%S}";
        format-alt = "{:%Y-%m-%d %H:%M:%S}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "year";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          on-click-right = "mode";
          format = {
            months = "<span color='#ffead3'><b>{}</b></span>";
            days = "<span color='#ecc6d9'><b>{}</b></span>";
            weeks = "<span color='#99ffdd'><b>W{}</b></span>";
            weekdays = "<span color='#ffcc66'><b>{}</b></span>";
            today = "<span color='#ff6699'><b><u>{}</u></b></span>";
          };
        };
        actions = {
          on-click-right = "mode";
          on-click-forward = "tz_up";
          on-click-backward = "tz_down";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
      };

      # Enhanced memory with swap info
      memory = {
        interval = 10;
        format = "󰍛 {used:0.1f}G";
        format-alt = "󰍛 {percentage}%";
        max-length = 10;
        tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G ({percentage}%)\nSwap: {swapUsed:0.1f}G / {swapTotal:0.1f}G";
        on-click = "system-monitor";
        on-click-right = "resource-monitor";
      };

      # Enhanced CPU with load average
      cpu = {
        interval = 5;
        format = "󰻠 {usage}%";
        format-alt = "󰻠 {load}";
        tooltip-format = "CPU Usage: {usage}%\nLoad Average: {load}\nCores: {avg_frequency} MHz";
        on-click = "system-monitor";
        on-click-right = "resource-monitor";
      };

      # Enhanced temperature with multiple sensors
      temperature = {
        thermal-zone = 2;
        hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
        critical-threshold = 80;
        format = " {temperatureC}°C";
        format-critical = " {temperatureC}°C";
        tooltip-format = "CPU Temperature: {temperatureC}°C";
        on-click = "sensor-viewer";
      };

      # Custom enhanced battery module
      "custom/battery" = {
        format = "{}";
        return-type = "json";
        exec = "battery-health";
        interval = 30;
        on-click = "power-settings";
        tooltip = true;
      };

      # Custom enhanced network module
      "custom/network" = {
        format = "{}";
        return-type = "json";
        exec = "network-status";
        interval = 10;
        on-click = "network-settings";
        tooltip = true;
      };

      # Enhanced pulseaudio with device switching
      pulseaudio = {
        scroll-step = 2;
        format = "{icon} {volume}%";
        format-muted = "󰝟 {volume}%";
        format-icons = {
          headphone = "󰋋";
          hands-free = "󱡒";
          headset = "󰋎";
          phone = "";
          portable = "";
          car = "";
          default = ["󰕿" "󰖀" "󰕾"];
        };
        tooltip-format = "{desc}\nVolume: {volume}%";
        on-click = "pavucontrol";
        on-click-right = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +2%";
        on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -2%";
      };

      # Enhanced idle inhibitor
      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
        tooltip-format-activated = "Idle inhibitor active - system won't sleep";
        tooltip-format-deactivated = "Idle inhibitor inactive - system can sleep";
        on-click-right = "systemctl --user restart hypridle";
      };

      # Enhanced notification center
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

      # Enhanced GPU module
      "custom/gpu" = {
        format = "{}";
        return-type = "json";
        exec = "gpu-status";
        interval = 3;
        on-click = "gpu-toggle";
        on-click-right = "gpu-menu";
        tooltip = true;
      };

      # Enhanced disk module with multiple mount points
      "custom/disk" = {
        format = "󰋊 {}%";
        return-type = "json";
        exec = pkgs.writeShellScript "disk-usage-enhanced" ''
          ROOT_USAGE=$(df / | awk 'NR==2 {print int($5)}' | sed 's/%//')
          HOME_USAGE=$(df /home 2>/dev/null | awk 'NR==2 {print int($5)}' | sed 's/%//' || echo "$ROOT_USAGE")

          # Use the higher usage
          USAGE=$(( ROOT_USAGE > HOME_USAGE ? ROOT_USAGE : HOME_USAGE ))

          ROOT_INFO=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')
          HOME_INFO=$(df -h /home 2>/dev/null | awk 'NR==2 {print $3"/"$2" ("$5")"}'|| echo "Same as root")

          TOOLTIP="Root: $ROOT_INFO\nHome: $HOME_INFO"

          if [[ $USAGE -gt 90 ]]; then
            CLASS="critical"
          elif [[ $USAGE -gt 80 ]]; then
            CLASS="warning"
          else
            CLASS="normal"
          fi

          echo "{\"text\": \"$USAGE\", \"percentage\": $USAGE, \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS\"}"
        '';
        interval = 60;
        on-click = "disk-usage-gui";
        on-click-right = "df -h | ${pkgs.wofi}/bin/wofi --dmenu --prompt 'Disk Usage:'";
        tooltip = true;
      };

      # Enhanced power menu
      "custom/power" = {
        format = "󰐥";
        tooltip-format = "Power Menu\nLeft: Logout | Right: Power Options";
        on-click = "wlogout";
        on-click-right = "systemctl poweroff";
        on-click-middle = "systemctl reboot";
      };
    }];

    # Enhanced CSS with better animations and responsiveness
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
       background: rgba(40, 40, 40, 0.95);
       color: ${colors.css.foreground};
       border-bottom: 2px solid ${colors.css.accent};
       transition-property: background-color;
       transition-duration: 0.3s;
     }

     window#waybar.hidden {
       opacity: 0.2;
     }

     /* Enhanced workspaces with better hover effects */
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
       transition: all 0.2s ease-in-out;
       min-width: 24px;
     }

     #workspaces button:hover {
       background: rgba(125, 174, 163, 0.3);
       border-bottom: 2px solid ${colors.css.accent};
       transform: translateY(-1px);
       box-shadow: 0 2px 4px rgba(0,0,0,0.2);
     }

     #workspaces button.active {
       background: rgba(125, 174, 163, 0.4);
       color: ${colors.css.accent};
       border-bottom: 2px solid ${colors.css.accent};
       font-weight: bold;
       transform: scale(1.05);
     }

     #workspaces button.urgent {
       background: rgba(234, 105, 98, 0.4);
       color: ${colors.css.error};
       border-bottom: 2px solid ${colors.css.error};
       animation: urgent-pulse 1s ease-in-out infinite alternate;
     }

     #workspaces button.persistent {
       background: rgba(76, 86, 106, 0.2);
     }

     /* Submap indicator */
     #submap {
       background: rgba(235, 203, 139, 0.3);
       color: #ebcb8b;
       padding: 0 8px;
       margin: 0 4px;
       border-radius: 8px;
       animation: submap-glow 2s ease-in-out infinite alternate;
     }

     /* Enhanced window title with better truncation */
     #window {
       margin: 0 8px;
       color: #d8dee9;
       font-weight: normal;
       transition: color 0.3s ease;
     }

     #window.empty {
       color: #4c566a;
     }

     /* Enhanced clock with hover effects */
     #clock {
       margin: 0 8px;
       color: ${colors.css.foreground};
       font-weight: bold;
       background: rgba(76, 86, 106, 0.4);
       padding: 0 12px;
       border-radius: 8px;
       transition: all 0.3s ease;
     }

     #clock:hover {
       background: rgba(76, 86, 106, 0.6);
       transform: scale(1.02);
     }

     /* Enhanced module styling with hover effects */
     #memory,
     #cpu,
     #temperature,
     #pulseaudio,
     #mpd,
     #idle_inhibitor,
     #tray,
     #custom-gpu,
     #custom-disk,
     #custom-network,
     #custom-battery,
     #custom-notification,
     #custom-power {
       margin: 0 2px;
       padding: 0 8px;
       background: rgba(76, 86, 106, 0.4);
       border-radius: 8px;
       font-weight: 500;
       transition: all 0.3s ease;
     }

     #memory:hover,
     #cpu:hover,
     #temperature:hover,
     #pulseaudio:hover,
     #custom-gpu:hover,
     #custom-disk:hover,
     #custom-network:hover,
     #custom-battery:hover {
       background: rgba(76, 86, 106, 0.6);
       transform: translateY(-1px);
       box-shadow: 0 2px 8px rgba(0,0,0,0.3);
     }

     /* Enhanced individual module colors */
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
       background: rgba(191, 97, 106, 0.4);
       animation: critical-pulse 1s ease-in-out infinite alternate;
     }

     #custom-battery.charging {
       color: #a3be8c;
       background: rgba(163, 190, 140, 0.3);
       animation: charging-pulse 2s ease-in-out infinite alternate;
     }

     #custom-battery.low {
       color: #ebcb8b;
       background: rgba(235, 203, 139, 0.3);
       animation: warning-pulse 1s ease-in-out infinite alternate;
     }

     #custom-battery.critical {
       color: #bf616a;
       background: rgba(191, 97, 106, 0.4);
       animation: critical-pulse 0.5s ease-in-out infinite alternate;
     }

     #custom-network.excellent {
       color: #a3be8c;
       background: rgba(163, 190, 140, 0.2);
     }

     #custom-network.good {
       color: #88c0d0;
       background: rgba(136, 192, 208, 0.2);
     }

     #custom-network.fair {
       color: #ebcb8b;
       background: rgba(235, 203, 139, 0.2);
     }

     #custom-network.poor {
       color: #d08770;
       background: rgba(208, 135, 112, 0.2);
     }

     #custom-network.disconnected {
       color: #bf616a;
       background: rgba(191, 97, 106, 0.3);
       animation: disconnected-pulse 2s ease-in-out infinite alternate;
     }

     #pulseaudio {
       color: #b48ead;
     }

     #pulseaudio.muted {
       color: #4c566a;
       background: rgba(76, 86, 106, 0.6);
       text-decoration: line-through;
     }

     #mpd {
       color: #d08770;
     }

     #mpd.disconnected {
       color: #4c566a;
       opacity: 0.6;
     }

     #mpd.stopped {
       color: #4c566a;
       opacity: 0.8;
     }

     #mpd.paused {
       color: #d08770;
       font-style: italic;
       opacity: 0.8;
     }

     #mpd.playing {
       animation: music-pulse 3s ease-in-out infinite alternate;
     }

     #custom-power {
       color: #bf616a;
       margin-right: 8px;
       font-size: 14px;
     }

     #custom-power:hover {
       background: rgba(191, 97, 106, 0.4);
       color: #ffffff;
       transform: scale(1.1);
     }

     #idle_inhibitor {
       color: #ebcb8b;
     }

     #idle_inhibitor.activated {
       background: rgba(235, 203, 139, 0.4);
       color: #ebcb8b;
       animation: active-pulse 2s ease-in-out infinite alternate;
     }

     #custom-notification {
       color: #81a1c1;
       font-size: 16px;
     }

     #custom-notification.notification {
       background: rgba(191, 97, 106, 0.4);
       animation: notification-bounce 1s ease-in-out infinite alternate;
     }

     #custom-gpu {
       color: #7daea3;
       font-size: 16px;
     }

     #custom-gpu.intel {
       color: #81a1c1;
       background: rgba(129, 161, 193, 0.3);
     }

     #custom-gpu.nvidia {
       color: #76b900;
       background: rgba(118, 185, 0, 0.3);
       animation: nvidia-pulse 3s ease-in-out infinite alternate;
     }

     #custom-gpu.performance {
       color: #ebcb8b;
       background: rgba(235, 203, 139, 0.4);
       animation: performance-pulse 2s ease-in-out infinite alternate;
     }

     #custom-disk {
       color: #d08770;
     }

     #custom-disk.warning {
       color: #ebcb8b;
       background: rgba(235, 203, 139, 0.3);
       animation: warning-pulse 2s ease-in-out infinite alternate;
     }

     #custom-disk.critical {
       color: #bf616a;
       background: rgba(191, 97, 106, 0.4);
       animation: critical-pulse 1s ease-in-out infinite alternate;
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
       background-color: rgba(191, 97, 106, 0.4);
       border-radius: 8px;
       animation: attention-bounce 1s ease-in-out infinite alternate;
     }

     /* Enhanced animations */
     @keyframes urgent-pulse {
       0% { background: rgba(234, 105, 98, 0.3); }
       100% { background: rgba(234, 105, 98, 0.6); }
     }

     @keyframes critical-pulse {
       0% { background: rgba(191, 97, 106, 0.3); }
       100% { background: rgba(191, 97, 106, 0.6); }
     }

     @keyframes warning-pulse {
       0% { background: rgba(235, 203, 139, 0.2); }
       100% { background: rgba(235, 203, 139, 0.4); }
     }

     @keyframes charging-pulse {
       0% { background: rgba(163, 190, 140, 0.2); }
       100% { background: rgba(163, 190, 140, 0.4); }
     }

     @keyframes disconnected-pulse {
       0% { opacity: 0.5; }
       100% { opacity: 1.0; }
     }

     @keyframes nvidia-pulse {
       0% { background: rgba(118, 185, 0, 0.2); }
       100% { background: rgba(118, 185, 0, 0.4); }
     }

     @keyframes performance-pulse {
       0% { background: rgba(235, 203, 139, 0.3); }
       100% { background: rgba(235, 203, 139, 0.5); }
     }

     @keyframes submap-glow {
       0% { box-shadow: 0 0 5px rgba(235, 203, 139, 0.5); }
       100% { box-shadow: 0 0 15px rgba(235, 203, 139, 0.8); }
     }

     @keyframes active-pulse {
       0% { background: rgba(235, 203, 139, 0.3); }
       100% { background: rgba(235, 203, 139, 0.5); }
     }

     @keyframes notification-bounce {
       0% { transform: scale(1); }
       100% { transform: scale(1.1); }
     }

     @keyframes attention-bounce {
       0% { transform: scale(1); }
       100% { transform: scale(1.05); }
     }

     @keyframes music-pulse {
       0% { background: rgba(208, 135, 112, 0.3); }
       100% { background: rgba(208, 135, 112, 0.5); }
     }

     /* Tooltip styling */
     tooltip {
       background: rgba(46, 52, 64, 0.95);
       border: 1px solid #4c566a;
       border-radius: 8px;
       padding: 8px;
       box-shadow: 0 4px 12px rgba(0,0,0,0.3);
     }

     tooltip label {
       color: #e5e9f0;
     }

     /* Focus effects */
     button:focus {
       background-color: rgba(136, 192, 208, 0.3);
       outline: none;
       box-shadow: 0 0 8px rgba(136, 192, 208, 0.5);
     }
     '';
  };

  # Enhanced systemd service
  systemd.user.services.waybar = {
    Unit = {
      Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors";
      Documentation = "https://github.com/Alexays/Waybar/wiki/";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
      Requisite = "graphical-session.target";
    };

    Service = {
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_CURRENT_DESKTOP=Hyprland"
        "XDG_SESSION_DESKTOP=Hyprland"
        "XDG_SESSION_TYPE=wayland"
        "XDG_RUNTIME_DIR=%i"
        "PATH=/run/wrappers/bin:/etc/profiles/per-user/%i/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      ];

      ExecStartPre = "${pkgs.procps}/bin/pkill -f waybar || true";
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";

      Restart = "on-failure";
      RestartSec = "2";
      StartLimitBurst = 3;
      StartLimitInterval = 30;

      KillMode = "mixed";
      KillSignal = "SIGTERM";
      TimeoutStopSec = "10";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Enhanced portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = "*";
  };

  # Clean GTK settings
  home.file.".config/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Adwaita-dark
    gtk-icon-theme-name=Adwaita
    gtk-font-name=Sans 11
    gtk-cursor-theme-name=Adwaita
    gtk-cursor-theme-size=24
    gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=0
    gtk-menu-images=0
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=0
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintfull
    gtk-xft-rgba=rgb
    gtk-application-prefer-dark-theme=1
  '';

  # Enhanced environment variables
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
  };

  # Resource monitoring service
  systemd.user.services.resource-monitor = {
    Unit = {
      Description = "System resource monitoring for Waybar";
      After = "waybar.service";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${resourceMonitor}/bin/resource-monitor";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Timer for resource monitoring
  systemd.user.timers.resource-monitor = {
    Unit = {
      Description = "Run resource monitor every 5 minutes";
      Requires = "resource-monitor.service";
    };

    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}

