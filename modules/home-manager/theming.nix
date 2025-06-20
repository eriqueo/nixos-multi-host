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

  # GTK theme configuration
  gtk = {
    enable = true;
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # Stylix configuration (if using it for wallpaper)
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    image = ./assets/wallpapers/nord-mountains.jpg;
    
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.caskaydia-cove;
        name = "CaskaydiaCove Nerd Font";
      };
      sansSerif = {
        package = pkgs.fira;
        name = "Fira Sans";
      };
      serif = {
        package = pkgs.fira;
        name = "Fira Sans";
      };
      emoji = {
        package = pkgs.twemoji-color-font;
        name = "Twitter Color Emoji";
      };
    };
    

    fonts.sizes = {
      applications = 11;
      terminal = 12;
      desktop = 11;
      popups = 11;
    };
  };
}