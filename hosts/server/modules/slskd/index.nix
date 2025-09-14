# modules/server/slskd/index.nix
{ config, lib, pkgs, ... }:

let
  # Import the parts
  slskdConfigSet = import ./parts/config.nix;
  slskdCaddyCfg  = import ./parts/caddy.nix;

  # Convert the Nix attribute set to a YAML string using generators
  slskdYamlString = pkgs.lib.generators.toYAML {} slskdConfigSet;

  # Import the container definition, passing the generated YAML to it
  slskdContainer = import ./parts/container.nix {
    inherit config lib pkgs;
    yamlConfig = slskdYamlString;
  };
in
{
  # This module doesn't need an enable option unless you want one.

  # Define the container using the imported definition
  virtualisation.oci-containers.containers.slskd = slskdContainer;

  # Add the Caddy configuration to your existing virtual host
  services.caddy.virtualHosts."hwc.ocelot-wahoo.ts.net".extraConfig =
    config.services.caddy.virtualHosts."hwc.ocelot-wahoo.ts.net".extraConfig + slskdCaddyCfg;

  # Ensure soularr depends on the correct service
  systemd.services."podman-soularr".after = [ "podman-slskd.service" ];
  systemd.services."podman-soularr".wants = [ "podman-slskd.service" ];
}
