{ config, pkgs, lib, osConfig, ... }:

{



  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [ 
    wofi mako
	kitty imv kdePackages.kdeconnect-kde zathura
    vscode obsidian libreoffice
    vlc qbittorrent 
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
		    
		    
		    # Variables
		    $mod = SUPER
		    
		    # Window/Session Management
		    bind = $mod, Return, exec, kitty
		    bind = $mod, Q, killactive
		    bind = $mod, F, fullscreen
		    bind = $mod, Space, exec, wofi --show drun
		    bind = $mod, B, exec, librewolf
		    bind = $mod, E, exec, electron-mail
		    
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
		 "wl-paste --type image --watch cliphist store"
		 "wl-paste --type text --watch cliphist store"
		 "librewolf"
		 "electron-mail"
		 "librewolf --new-window https://jobtread.com"
		 "obsidian"
		 "code"
	     # Separate entries for each delayed launch
	    # "sleep 2 && hyprctl dispatch exec '[workspace 1:Web silent] librewolf'"
	    # "sleep 3 && hyprctl dispatch exec '[workspace 2:Email silent] electron-mail'"
		# "sleep 4 && hyprctl dispatch exec '[workspace 3:JT silent] librewolf --new-window https://jobtread.com'"
		# "sleep 5 && hyprctl dispatch exec '[workspace 4:Notes silent] obsidian'"
		# "sleep 6 && hyprctl dispatch exec '[workspace 6:Code silent] code'"
		 ];
		 windowrulev2 = [
		     "workspace 1 silent, class:^(librewolf|firefox)$, title:^((?!JobTread).)*$"
		     "workspace 2 silent, class:^(electron-mail|ElectronMail)$"
		     "workspace 3 silent, class:^(librewolf|firefox)$, title:.*JobTread.*"
		     "workspace 4 silent, class:^(obsidian|Obsidian)$"
		     "workspace 5 silent, class:^(kitty)$"
		     "workspace 6 silent, class:^(vlc|VLC)$"
		     "workspace 7 silent, class:^(code|Code|vscode)$"
		     "workspace 8 silent, class:^(thunar)$"
		   ];
		monitor = [ "eDP-1, 2560x1600@165, 1920x0, 1.6" ];
		input.kb_layout = "us";
		input.touchpad.natural_scroll = true;
		workspace = [
		    "1:Web, default:true"
		    "2:Email, default:true" 
		    "3:JT, default:true"
		    "4:Notes, default:true"
		    "5:Code, default:true"
		    "6:Media, default:true"
		    "7:Misc, default:true"
		    "8:AI, default:true"
		  ];
		general = {
			gaps_in = 5;
			gaps_out = 10;
			border_size = 2;
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
				height = 36;
				modules-left = [ "hyprland/workspaces" ];
				modules-center = [ "clock" ];
				modules-right = [ "pulseaudio" "battery" "tray" ];
				"hyprland/workspaces" = {
				        disable-scroll = true;
				        all-outputs = true;
				        format = "{name}";
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
