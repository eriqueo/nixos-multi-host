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

  # slskd Caddy configuration is now handled in media-containers.nix

  systemd.services."podman-soularr".after = [ "podman-slskd.service" ];
  systemd.services."podman-soularr".wants = [ "podman-slskd.service" ];
}
