{ config, pkgs, lib, ... }:
let
  base16 = "${pkgs.base16-schemes}/share/themes/nord.yaml";
in {
  config = {
    stylix = {
      enable       = true;
      base16Scheme = base16;
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.caskaydia-cove;
          name    = "CaskaydiaCove Nerd Font";
        };
        sansSerif = {
          package = pkgs.fira;
          name    = "Fira Sans";
        };
        serif = {
          package = pkgs.fira;
          name    = "Fira Sans";
        };
        emoji = {
          package = pkgs.twemoji-color-font;
          name    = "Twitter Color Emoji";
        };
      };
      fonts.sizes = {
        applications = 11;
        terminal     = 12;
        desktop      = 11;
        popups       = 11;
      };
    };
  };
}
