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
  # Create a separate Caddy virtual host for port 5030 access
  services.caddy.virtualHosts.":5030" = {
    extraConfig = slskdCaddyCfg;
  };

  systemd.services."podman-soularr".after = [ "podman-slskd.service" ];
  systemd.services."podman-soularr".wants = [ "podman-slskd.service" ];
}
