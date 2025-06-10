{ config, pkgs, lib, osConfig, ... }:

{
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [ 
        wofi
  ];
  programs.hyprland = {
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
