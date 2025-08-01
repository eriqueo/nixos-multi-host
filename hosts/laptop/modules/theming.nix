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
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
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
    fira
    fira-code
    nerd-fonts.caskaydia-cove
    noto-fonts
    noto-fonts-emoji
  ];

  # Application-specific theming
  
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