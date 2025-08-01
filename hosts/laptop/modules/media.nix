# hosts/laptop/modules/media.nix
# Media applications and entertainment tools for laptop
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Video players
    vlc               # VLC media player
    mpv               # Lightweight media player
    
    # Audio tools
    picard            # MusicBrainz Picard for music tagging
    
    # Download and torrenting
    qbittorrent       # BitTorrent client
  ];

  # qBittorrent theme configuration 
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

  # MPV configuration for better media playback
  programs.mpv = {
    enable = true;
    config = {
      # Hardware acceleration
      hwdec = "auto-safe";
      vo = "gpu";
      
      # Audio settings
      audio-display = "no";
      
      # Subtitle settings
      sub-auto = "fuzzy";
      sub-file-paths = "sub:subtitles:subs";
      
      # Video settings
      keep-open = true;
      save-position-on-quit = true;
      
      # Interface
      osd-bar = true;
      osd-duration = 2000;
      
      # Network streaming
      ytdl-format = "bestvideo[height<=?1080]+bestaudio/best[height<=?1080]";
    };
    
    # Key bindings
    bindings = {
      "WHEEL_UP" = "seek 10";
      "WHEEL_DOWN" = "seek -10";
      "RIGHT" = "seek 5";
      "LEFT" = "seek -5";
      "UP" = "add volume 5";
      "DOWN" = "add volume -5";
    };
  };
}