{ config, pkgs, lib, osConfig, ... }:
let
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
  fonts = {
    mono = "CaskaydiaCove Nerd Font";
    sans = "Inter";
    size = {
      normal = "13";
      large = "15";
    };
  };
  theme = nordic-blue;
in

{
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [ 
    waybar wofi mako grim slurp wl-clipboard
	pavucontrol brightnessctl
    kitty imv kdePackages.kdeconnect-kde zathura
    firefox brave networkmanager
    vscode obsidian libreoffice
    protonmail-bridge
    vlc qbittorrent thunderbird
    gimp inkscape blender
    blueman timeshift udiskie redshift
    hyprshot hyprpaper hyprlock hypridle
    ffmpeg-full
    ollama
  ];
	wayland.windowManager.hyprland = {
		  enable = true;
		  extraConfig = ''
		    # Mouse settings
		    input {
		      kb_layout = us
		      follow_mouse = 1
		      touchpad {
		        natural_scroll = true
		      }
		    }
		    
		    # Monitor setup
		    monitor = eDP-1, 2560x1600@165, 1920x0, 1.6
		    
		    # Startup applications
		    exec-once = waybar
		    
		    # Variables
		    $mod = SUPER
		    
		    # Window/Session Management
		    bind = $mod, Return, exec, kitty
		    bind = $mod, Q, killactive
		    bind = $mod, F, fullscreen
		    bind = $mod, Space, exec, wofi --show drun
		    bind = $mod, B, exec, librewolf
		    bind = $mod, E, exec, electronmail
		    
		    # Screenshots
		    bind = , Print, exec, hyprshot -m region -o ~/Pictures/Screenshots
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
		    
		    # Switch to workspaces (SUPER + CTRL + ALT + numbers)
		    bind = $mod CTRL ALT, 1, workspace, 1
		    bind = $mod CTRL ALT, 2, workspace, 2
		    bind = $mod CTRL ALT, 3, workspace, 3
		    bind = $mod CTRL ALT, 4, workspace, 4
		    bind = $mod CTRL ALT, 5, workspace, 5
		    bind = $mod CTRL ALT, 6, workspace, 6
		    bind = $mod CTRL ALT, 7, workspace, 7
		    bind = $mod CTRL ALT, 8, workspace, 8
		  '';
		settings = {
		exec-once = [
		 "swaynotificationcenter"
		 "hypridle"
		 "hyprpaper"
		 ];
		monitor = [ "eDP-1, 2560x1600@165, 1920x0, 1.6" ];
		input.kb_layout = "us";
		input.touchpad.natural_scroll = true;
		workspace = [
		    "1, name:Web"
		    "2, name:Email" 
		    "3, name:JT"
		    "4, name:Notes"
		    "5, name:Code"
		    "6, name:Media"
		    "7, name:Misc"
		    "8, name:AI"
		  ];
		general = {
			gaps_in = 5;
			gaps_out = 10;
			border_size = 2;
				"col.active_border" = "rgba(5e81acee)";    # Fixed: rgba format
			    "col.inactive_border" = "rgba(434c5eaa)";  # Fixed: rgba format
			layout = "dwindle";
		};
		decoration.rounding = 8;
		};
	};

	programs.waybar = {
		enable = true;
		systemd.enable = true;
		settings = {
			mainBar = {
				layer = "top";
				position = "top";
				height = 34;
				modules-left = [ "hyprland/workspaces" ];
				modules-center = [ "clock" ];
				modules-right = [ "pulseaudio" "battery" "tray" ];
				"hyprland/workspaces" = {
				        disable-scroll = true;
				        all-outputs = true;
				        format = "{name}";
				        format-icons = {
				          "1" = "Web";  # Web
				          "2" = "Email";   # Terminal  
				          "3" = "JT";  # Music
				          "4" = "Notes";   # Chat
				          "5" = "Code";   # Files
				          "6" = "Media";   # Code
				          "7" = "Misc";   # Games
				          "8" = "AI";   # System
				        };
				        persistent_workspaces = {
				          "*" = 8;
				        };
				      };
				      
				      clock = {
				        format = "{:%H:%M}";
				        format-alt = "{:%Y-%m-%d}";
				      };
				      
				      pulseaudio = {
				        format = "{volume}% {icon}";
				        format-muted = " ";
				        format-icons = ["" "" ""];
				        on-click = "pavucontrol";
				      };
				      
				      battery = {
				        format = "{capacity}% {icon}";
				        format-icons = ["" "" "" "" ""];
				        states = {
				          warning = 30;
				          critical = 15;
				        };
				      };
				      
				      tray = { 
				        spacing = 10; 
				      };
				    };
				  };
	
		style = ''
		* {
			font-family: "${fonts.mono}", monospace;
			font-size: ${fonts.size}px;
		}
		window#waybar {
			background-color: ${theme.bg};
			color: ${theme.fg};
		}
		#workspaces button.active {
			background-color: ${theme.accent};
			color: ${theme.bg};
		}
		#battery.critical:not(.charging) {
			background: ${theme.urgent};
			color: ${theme.fg};
		}
		'';
	};

	services.hyprpaper = {
	  enable = true;
	  settings = {
	    ipc = "on";
	    splash = false;
	    
	    preload = [ "~/Pictures/wallpaper.jpg" ];  # Put your wallpaper here
	    wallpaper = [ "eDP-1,~/Pictures/wallpaper.jpg" ];
	  };
	};
	
	programs.firefox = {
	enable = true;
	package = pkgs.librewolf;
	policies = {
		DisableTelemetry = true;
		Preferences = {
		"privacy.resistFingerprinting" = false;
		# ... other preferences
		};
		ExtensionSettings = {
		"uBlock0@raymondhill.net" = {
			install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
			installation_mode = "force_installed";
		};
		};
	};
	};

	programs.chromium = {
	enable = true;
	package = pkgs.ungoogled-chromium;
	};



  # Enable Home Manager self-management
  programs.home-manager.enable = true;
}
