{ config, pkgs, lib, ... }:

let
  colors = (import ../../../shared/colors/deep-nord.nix).colors;
in

{
  # BROWSERS
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;
  };
  
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
  };

  # TERMINAL
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "CaskaydiaCove Nerd Font";
      font_size = 14;
      enable_audio_bell = false;
      window_padding_width = 4;
      
      # Deep Nord color scheme (darker + creamier)
      foreground = "#f2f0e8";
      background = "#1f2329";
      selection_foreground = "#1f2329";
      selection_background = "#88c0d0";
      
      # Cursor
      cursor = "#f2f0e8";
      cursor_text_color = "#1f2329";
      
      # URL color
      url_color = "#88c0d0";
      
      # Normal colors
      color0 = "#3b4252";  # black
      color1 = "#bf616a";  # red
      color2 = "#a3be8c";  # green
      color3 = "#ebcb8b";  # yellow
      color4 = "#81a1c1";  # blue
      color5 = "#b48ead";  # magenta
      color6 = "#88c0d0";  # cyan
      color7 = "#f2f0e8";  # white
      
      # Bright colors
      color8 = "#4c566a";   # bright black
      color9 = "#bf616a";   # bright red
      color10 = "#a3be8c";  # bright green
      color11 = "#ebcb8b";  # bright yellow
      color12 = "#81a1c1";  # bright blue
      color13 = "#b48ead";  # bright magenta
      color14 = "#8fbcbb";  # bright cyan
      color15 = "#f2f0e8";  # bright white
      
      # Window styling to match Hyprland
      background_opacity = "0.95";
    };
   }; 
   programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
   };

  # ALL OTHER APPLICATIONS
  home.packages = with pkgs; [
    # COMMUNICATION
    electron-mail
    
    # PRODUCTIVITY SUITE
    obsidian
    libreoffice
    zathura
    
    # DEVELOPMENT TOOLS
    vscodium
    git
    
    # CREATIVE APPLICATIONS
    gimp
    inkscape
    blender
    
    # MEDIA & ENTERTAINMENT
    vlc
    mpv
    qbittorrent
    picard  # MusicBrainz Picard
    # FILE MANAGEMENT
    imv
    file-roller
    xfce.thunar
    gvfs
    xfce.tumbler
    
    # SYSTEM MAINTENANCE
    blueman
    timeshift
    udiskie
    redshift
    
    # FONTS
    noto-fonts
    noto-fonts-emoji
  ];
}
