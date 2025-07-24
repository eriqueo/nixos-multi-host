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
      foreground = "colors.foreground";
      background = "colors.background";
      selection_foreground = "colors.background";
      selection_background = "colors.selection_bg";
      
      # Cursor
      cursor = "colors.foreground";
      cursor_text_color = "colors.background";
      
      # URL color
      url_color = "colors.selection_bg";
      
      # Normal colors
      color0 = colors.color0;  # black
      color1 = colors.color1;  # red
      color2 = colors.color2;  # green
      color3 = colors.color3;  # yellow
      color4 = colors.color4;  # blue
      color5 = colors.color5;  # magenta
      color6 = "colors.selection_bg";  # cyan
      color7 = "colors.foreground";  # white
      
      # Bright colors
      color8 = colors.color8;   # bright black
      color9 = colors.color9;   # bright red
      color10 = colors.color10;  # bright green
      color11 = colors.color11;  # bright yellow
      color12 = colors.color12;  # bright blue
      color13 = colors.color13;  # bright magenta
      color14 = colors.color14;  # bright cyan
      color15 = "colors.foreground";  # bright white
      
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
