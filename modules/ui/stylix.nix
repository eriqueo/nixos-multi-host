# modules/ui/stylix.nix
{ config, pkgs, ... }:

{
  stylix = {
    enable       = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    fonts = {
      monospace = {
        # …your monospace overrides…
      };
      sans = {
        # …your sans overrides…
      };
    };
  };

  stylix.targets.firefox.profileNames = [ "3bp09ufp.default" ];
}
