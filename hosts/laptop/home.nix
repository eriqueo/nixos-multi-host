{ config, pkgs, lib, osConfig, ... }:
let
  theme = {
    bg = "#2e3440";
    fg = "#eceff4";
    accent = "#5e81ac";
    urgent = "#bf616a";
  };
  fonts = {
    mono = "CaskaydiaCove Nerd Font";
    size = "13";
  };
in

{
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [ 
    waybar wofi mako grim slurp wl-clipboard
	pavucontrol brightnessctl
    kitty imv kdePackages.kdeconnect-kde engrampa zathura
    firefox brave  
    vscode obsidian libreoffice
    protonmail-bridge
    vlc qbittorrent discord telegram-desktop thunderbird
    gimp inkscape blender
    blueman timeshift udiskie redshift
    hyprshot hyprpaper hyprlock hypridle

    ffmpeg-full
    ollama
  ];
	wayland.windowManager.hyprland = {
		enable = true;
		extraConfig = ''
		$mod = SUPER
		bind = $mod, Return, exec, kitty
		bind = $mod, Q, killactive
		bind = $mod, F, fullscreen
		bind = $mod, Space, exec, wofi --show drun
		bind = , Print, exec, hyprshot -m region -o ~/Pictures/Screenshots
		bind = SHIFT, Print, exec, hyprshot -m region -c

		'';
		settings = {
		exec-once = [ "waybar" ];
		monitor = [ "eDP-1, 2560x1600@165, 1920x0, 1.6" ];
		input.kb_layout = "us";
		input.touchpad.natural_scroll = true;
		general = {
			gaps_in = 5;
			gaps_out = 10;
			border_size = 2;
			"col.active_border" = "(${theme.accent})";
			"col.inactive_border" = "#434c5e#";
			layout = "dwindle";
		};
		decoration.rounding = 8;
		};
	};

	programs.waybar = {
		enable = true;
		settings = {
		mainBar = {
			layer = "top";
			position = "top";
			height = 34;
			modules-left = [ "hyprland/workspaces" ];
			modules-center = [ "clock" ];
			modules-right = [ "pulseaudio" "battery" "tray" ];
			clock.format = "{:%H:%M}";
			pulseaudio.format = "{volume}% {icon}";
			battery.format = "{capacity}% {icon}";
			tray.spacing = 10;
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
	programs.thunar = {
		enable = true;
		plugins = with pkgs.xfce; [
		thunar-archive-plugin
		thunar-volman
		];
	};
    programs.xfconf.enable = true;


  # Enable Home Manager self-management
  programs.home-manager.enable = true;
}
