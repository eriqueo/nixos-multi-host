# modules/server/slskd/index.nix
{ config, lib, pkgs, ... }:

let
  # ... (let block is unchanged)
  slskdConfigSet = import ./parts/config.nix;
  slskdCaddyCfg  = import ./parts/caddy.nix;
  slskdYamlString = pkgs.lib.generators.toYAML {} slskdConfigSet;
  slskdContainer = import ./parts/container.nix {
    inherit config lib pkgs;
    yamlConfig = slskdYamlString;
  };
in
{
  virtualisation.oci-containers.containers.slskd = slskdContainer;

  # CORRECTED CADDY CONFIGURATION
  # Simply define the string to be added. The NixOS module system
  # will automatically concatenate this with definitions from other modules.
  services.caddy.virtualHosts."hwc.ocelot-wahoo.ts.net".extraConfig = slskdCaddyCfg;

  systemd.services."podman-soularr".after = [ "podman-slskd.service" ];
  systemd.services."podman-soularr".wants = [ "podman-slskd.service" ];
}
