# -----------------------------------------------------------------------------
# FILE: modules/home-manager/ui/theming.nix (WALLPAPER & CURSOR)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

{
  # Cursor theme configuration
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    
    theme = {
      name = "Nordic";
      package = pkgs.nordic;
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
    platformTheme = "gtk";
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
}

