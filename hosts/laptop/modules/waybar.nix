
# -----------------------------------------------------------------------------
# FILE: modules/home-manager/ui/waybar.nix (STATUS BAR)
# -----------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

let
  colors = (import ../../../shared/colors/deep-nord.nix).colors;
in

{
  # Waybar dependencies
  home.packages = with pkgs; [
    pavucontrol
    swaynotificationcenter
    wlogout  # Power menu
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
        "hyprland/window"
      ];
      
      modules-center = [
        "clock"
      ];
      
      modules-right = [
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
      };

      cpu = {
        interval = 10;
        format = "󰻠 {usage}%";
        tooltip = false;
      };

      temperature = {
        thermal-zone = 2;
        critical-threshold = 80;
        format = " {temperatureC}°C";
        format-critical = " {temperatureC}°C";
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
      };

      network = {
        format-wifi = "󰤨 {essid}";
        format-ethernet = "󰈀";
        format-linked = "󰈀 No IP";
        format-disconnected = "󰤭";
        tooltip-format = "{ifname} via {gwaddr}";
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
}