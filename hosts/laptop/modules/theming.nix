{ config, pkgs, lib, ... }:

let
 # Import our new patched theme package
  deepNordGtkTheme = import ../../../shared/themes/deep-nord-gtk.nix { inherit pkgs; };in

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
      name = "DeepNord-GTK";
      package = deepNordGtkTheme;
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
      name = "CaskaydiaCova Nerd Font";
      size = 14;
      package = pkgs.nerd-fonts.caskaydia-cove;
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

}
