# modules/scripts.nix

{ lib, pkgs, config, ... }:

let
  # Wrap your existing shell scripts as profile binaries
  hyprStartup  = pkgs.writeScriptBin "hypr-startup" ./scripts/startup.sh;
  hyprBindings = pkgs.writeScriptBin "hypr-bindings" ./scripts/bindings.sh;
in {
  # Expose them to other modules via package set
  packages.hyprlandScripts = {
    startup  = hyprStartup;
    bindings = hyprBindings;
  };

  # Make them available in the system profile
  environment.systemPackages = lib.concatLists [
    [ hyprStartup hyprBindings ]
  ];
}
