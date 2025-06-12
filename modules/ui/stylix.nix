# modules/ui/stylix.nix
{ config, pkgs, ... }:

{
  stylix = {
    enable       = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    fonts = {
		monospace = { package = pkgs.nerd-fonts.caskaydia-cove; ... };
	    sans      = { package = pkgs.fira; ... };
	    emoji     = { package = pkgs.twemoji-color-font; ... };
      };
    };
  };

  stylix.targets.firefox.profileNames = [ "3bp09ufp.default" ];
}
