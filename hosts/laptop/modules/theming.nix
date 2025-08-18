{ config, pkgs, lib, ... }:

let
  colors = (import ../../../shared/colors/deep-nord.nix).colors;
in

{
  # Cursor theme
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # GTK theming (Gruvbox Material style)
  gtk = {
    enable = true;
    
    theme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-gtk-theme;
    };
    
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    
    font = {
      name = "Fira Sans";
      size = 11;
      package = pkgs.fira;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-show-hidden-files = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-show-hidden-files = true;
    };
  };

  # Qt theming to match GTK
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  # Fonts
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # Fonts
    fira
    fira-code
    nerd-fonts.caskaydia-cove
    noto-fonts
    noto-fonts-emoji
    
    # Thunar configuration tools
    xfce.xfconf
    
    # Script to configure Thunar via xfconf on first run
    (writeScriptBin "thunar-setup" ''
      #!/usr/bin/env bash
      # Configure Thunar via xfconf
      ${xfce.xfconf}/bin/xfconf-query -c thunar -p /default-view -t string -s "ThunarDetailsView" --create
      ${xfce.xfconf}/bin/xfconf-query -c thunar -p /last-view -t string -s "ThunarDetailsView" --create
      ${xfce.xfconf}/bin/xfconf-query -c thunar -p /misc-show-hidden -t bool -s true --create
      ${xfce.xfconf}/bin/xfconf-query -c thunar -p /last-show-hidden -t bool -s true --create
      ${xfce.xfconf}/bin/xfconf-query -c thunar -p /misc-single-click -t bool -s false --create
      echo "Thunar configured for list view and hidden files"
    '')
  ];

  # Application-specific theming
  
<<<<<<< Updated upstream
  # Thunar file manager configuration using xfconf
  home.file.".config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="thunar" version="1.0">
      <property name="default-view" type="string" value="ThunarDetailsView"/>
      <property name="last-view" type="string" value="ThunarDetailsView"/>
      <property name="misc-show-hidden" type="bool" value="true"/>
      <property name="last-show-hidden" type="bool" value="true"/>
      <property name="misc-single-click" type="bool" value="false"/>
      <property name="misc-text-beside-icons" type="bool" value="false"/>
    </channel>
  '';
  
  
=======
  # Thunar file manager configuration
  home.file.".config/Thunar/thunarrc".text = ''
    [Configuration]
    DefaultView=THUNAR_VIEW_LIST
    LastView=THUNAR_VIEW_LIST
    LastShowHidden=TRUE
    LastDetailsViewColumnOrder=THUNAR_COLUMN_NAME,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_TYPE,THUNAR_COLUMN_DATE_MODIFIED
    LastDetailsViewColumnWidths=200,80,120,150
    LastListViewColumnOrder=THUNAR_COLUMN_NAME,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_TYPE,THUNAR_COLUMN_DATE_MODIFIED
    LastListViewColumnWidths=200,80,120,150
    LastWindowWidth=900
    LastWindowHeight=700
    LastWindowMaximized=FALSE
    MiscVolumeBookmarks=TRUE
    MiscFileSize=THUNAR_FILE_SIZE_BINARY
    MiscDateStyle=THUNAR_DATE_STYLE_SHORT
    MiscRememberGeometry=TRUE
    MiscShowAboutTemplates=TRUE
    MiscSingleClick=FALSE
    ShortcutsIconEmblem=TRUE
    ShortcutsIconSize=THUNAR_ICON_SIZE_SMALLER
    TreeIconEmblem=TRUE
    TreeIconSize=THUNAR_ICON_SIZE_SMALLER
    MiscMiddleClickInTab=FALSE
    MiscRecursivePermissions=THUNAR_RECURSIVE_PERMISSIONS_ASK
    MiscShowFullPathInTitlebar=FALSE
    MiscPathStyleInToolbar=THUNAR_PATH_STYLE_ICONS
  '';
  
  # Alternative Thunar view configuration using xfconf
  home.file.".config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="thunar" version="1.0">
      <property name="default-view" type="string" value="THUNAR_VIEW_LIST"/>
      <property name="misc-show-hidden" type="bool" value="true"/>
      <property name="last-view" type="string" value="THUNAR_VIEW_LIST"/>
    </channel>
  '';
  
>>>>>>> Stashed changes
  # Obsidian CSS theme (for tech vault)
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
}