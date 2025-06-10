{ config, pkgs, lib, osConfig, ... }:

{
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [ 
    waybar wofi mako grim slurp wl-clipboard
	pavucontrol brightnessctl
    kdePackages.konsole kdePackages.dolphin kdePackages.kate kdePackages.yakuake kdePackages.gwenview kdePackages.kdeconnect-kde kdePackages.ark kdePackages.okular
    firefox brave
    vscode obsidian libreoffice
    protonmail-bridge
    vlc qbittorrent discord telegram-desktop thunderbird
    gimp inkscape blender
    blueman timeshift udiskie redshift
    ffmpeg-full
    ollama
  ];
  wayland.windowManager.hyprland = {
  	enable = true;
  	settings = {
  		exec-once = "waybar &";
  		"%mod" = "SUPER";
  		bind = [
  			"%mod, Return, exec, konsole"
  			"%mod, Q, killactive"
  			"%mod, F, fullscreen"
  			"%mod, Space, exec, wofi --show drun "
  		];
  	};
  };

  

  # Enable Home Manager self-management
  programs.home-manager.enable = true;
}
