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
		extraConfig = builtins.readFile ../../scripts/bindings.sh;
		settings = {
			exec-once = [ "/etc/nixos/scripts/startup.sh" ];
	    	monitor = [ "eDP-1, 2560x1600@165, 1920x0, 1.6" ];
			input =  {
				kb_layout = "us";
				follow_mouse = 1;
				touchpad = {natural_scroll = true;};
			  };		
			#workspace = [
			#      "1:Web, persistent:true"
			 #     "2:Email, persistent:true"
			  #    "3:JT, persistent:true"
			   #   "4:Notes, persistent:true"
			    #  "5:Code, persistent:true"
			     # "6:Media, persistent:true"
			     # "7:Misc, persistent:true"
			     # "8:AI, persistent:true"
			#  ];
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
		systemd.enable = false;
		settings = {
			mainBar = {
				layer = "top";
				position = "top";
				height = 36;
				modules-left = [ "hyprland/workspaces" ];
				modules-center = [ "clock" ];
				modules-right = [ "pulseaudio" "battery" "tray" ];
				"hyprland/workspaces" = {
				  format = "{name}";
				  format_icons = {
				    active = "●";
				    default = "○";
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
    stylix.targets.firefox.profileNames = [ "3bp09ufp.default" ];
    


  # Enable Home Manager self-management
  	programs.home-manager.enable = true;
}
