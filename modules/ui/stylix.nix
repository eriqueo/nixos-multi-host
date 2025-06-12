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
          size    = 12;
        };
        sans = {
          package = pkgs.fira;
          size    = 11;
        };
        emoji = {
          package = pkgs.twemoji-color-font;
          size    = 13;
        };
      };
    };
  };
}
