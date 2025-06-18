{ config, pkgs, lib, osConfig, ... }:
# ########################################
# File: hosts/laptop/home.nix
# Home-Manager config for user "eric" on your laptop
# ########################################
{
  imports = [
    ../../modules/ui/waybar.nix
  ];	
  # identity & state
  home.username    = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion  = "23.05";
  # let Home-Manager update itself
  programs.home-manager.enable = true;
  # your user‐level GUI and CLI programs
  home.packages = with pkgs; [
    wofi
    mako
    kitty
    imv
    kdePackages.kdeconnect-kde
    zathura
    vscode
    obsidian
    libreoffice
    vlc
    qbittorrent
    gimp
    inkscape
    blender
    blueman
    timeshift
    udiskie
    redshift
    # notifications & clipboard
    swaynotificationcenter
    cliphist
    wl-clipboard
    # hardware tools
    brightnessctl
    networkmanager
    wirelesstools
    acpi
    lm_sensors
  ];
  # ungoogled‐chromium via Home-Manager
  programs.chromium = {
    enable  = true;
    package = pkgs.ungoogled-chromium;
  };
  # Stylix: point Firefox at your profile
  stylix.targets.firefox.profileNames = [ "3bp09ufp.default" ];
  # Waybar assets (pulled in by modules/ui/waybar.nix, no hyprland/UI here)
  # you could also inject dotfiles, e.g. your kitty.conf, via home.file if desired
}
