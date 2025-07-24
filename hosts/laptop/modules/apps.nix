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
      foreground = "#d4be98";
      background = "#282828";
      selection_foreground = "#282828";
      selection_background = "#7daea3";
      
      # Cursor
      cursor = "#d4be98";
      cursor_text_color = "#282828";
      
      # URL color
      url_color = "#7daea3";
      
      # Normal colors
      color0 = "#32302F";  # black
      color1 = "#ea6962";  # red
      color2 = "#a9b665";  # green
      color3 = "#d8a657";  # yellow
      color4 = "#7daea3";  # blue
      color5 = "#d3869b";  # magenta
      color6 = "#89b482";  # cyan
      color7 = "#d4be98";  # white
      
      # Bright colors
      color8 = "#45403d";   # bright black
      color9 = "#ea6962";   # bright red
      color10 = "#a9b665";  # bright green
      color11 = "#d8a657";  # bright yellow
      color12 = "#7daea3";  # bright blue
      color13 = "#d3869b";  # bright magenta
      color14 = "#89b482";  # bright cyan
      color15 = "#d4be98";  # bright white
      
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
