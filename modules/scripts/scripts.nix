# /etc/nixos/modules/scripts/scripts.nix

{ config, pkgs, lib, ... }:

let
  # wrap your .sh files into profile binaries
  hyprStartup  = pkgs.writeScriptBin "hypr-startup" (builtins.readFile ./startup.sh);
  hyprBindings = pkgs.writeScriptBin "hypr-bindings" (builtins.readFile ./bindings.sh);
in {
  # All module configuration MUST live under `config`
  config = {
    # expose them for other modules to reference
    packages.hyprlandScripts = {
      startup  = hyprStartup;
      bindings = hyprBindings;
    };

    # install into the system profile
    environment.systemPackages = lib.mkForce [
      hyprStartup
      hyprBindings
    ];
  };
}
