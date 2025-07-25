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

  # ================================================================
  # THEME FILES - Consistent Gruvbox Material across all apps
  # ================================================================

  # Obsidian CSS (correct vault path)
  home.file."Documents/01-vaults/00_tech/.obsidian/snippets/gruvbox-material.css".text = ''
    /* Gruvbox Material theme for Obsidian */
    .theme-dark {
      --background-primary: #282828;
      --background-secondary: #32302f;
      --background-modifier-border: #45403d;
      --text-normal: #d4be98;
      --text-muted: #a89984;
      --text-accent: #7daea3;
      --text-accent-hover: #89b482;
      --interactive-accent: #7daea3;
      --interactive-accent-hover: #89b482;
    }
  '';

  # qBittorrent Qt stylesheet
  home.file.".config/qBittorrent/gruvbox-material.qss".text = ''
    /* Gruvbox Material theme for qBittorrent */
    QWidget {
      background-color: #282828;
      color: #d4be98;
      font-family: "CaskaydiaCove Nerd Font";
    }
    
    QMainWindow {
      background-color: #282828;
      color: #d4be98;
    }
    
    QTableView {
      background-color: #32302f;
      alternate-background-color: #3c3836;
      selection-background-color: #7daea3;
      selection-color: #282828;
      gridline-color: #45403d;
    }
    
    QHeaderView::section {
      background-color: #45403d;
      color: #d4be98;
      border: 1px solid #282828;
      padding: 4px;
    }
    
    QMenuBar {
      background-color: #282828;
      color: #d4be98;
    }
    
    QMenuBar::item:selected {
      background-color: #7daea3;
      color: #282828;
    }
    
    QMenu {
      background-color: #32302f;
      color: #d4be98;
      border: 1px solid #45403d;
    }
    
    QMenu::item:selected {
      background-color: #7daea3;
      color: #282828;
    }
  '';

  # LibreOffice dark theme configuration
  home.file.".config/libreoffice/4/user/config/registrymodifications.xcu".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <item oor:path="/org.openoffice.Office.Common/VCL">
        <prop oor:name="PreferredAppearance" oor:op="fuse">
          <value>1</value>
        </prop>
      </item>
    </oor:items>
  '';
}
