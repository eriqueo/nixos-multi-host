# /etc/nixos/modules/scripts/scripts.nix

{ lib, pkgs, config, ... }:

let
  # Wrap startup.sh as a profile‐binary named "hypr-startup"
  hyprStartup = pkgs.writeScriptBin "hypr-startup" (builtins.readFile ./startup.sh);

  # Wrap bindings.sh as a profile‐binary named "hypr-bindings"
  hyprBindings = pkgs.writeScriptBin "hypr-bindings" (builtins.readFile ./bindings.sh);
in {
  # Expose them under config.packages.hyprlandScripts
  config = {
    packages.hyprlandScripts = {
      startup  = hyprStartup;
      bindings = hyprBindings;
    };
  };

  # Also install them into your system profile so they’re in $PATH
  environment.systemPackages = lib.mkForce [
    hyprStartup
    hyprBindings
  ];
}

