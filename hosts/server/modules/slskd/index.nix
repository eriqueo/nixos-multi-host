# modules/server/slskd/index.nix
{ config, lib, pkgs, ... }:

let
  slskdConfigSet = import ./parts/config.nix;
  slskdCaddyCfg = import ./parts/caddy.nix;
  yamlFormat = pkgs.formats.yaml {};
  slskdConfigFile = yamlFormat.generate "slskd.yml" slskdConfigSet;
  slskdContainer = import ./parts/container.nix {
    inherit config lib pkgs;
    configFile = slskdConfigFile;
  };
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/slskd 0755 root root -"
  ];

  environment.etc."slskd/slskd.yml" = {
    source = slskdConfigFile;
    mode = "0644";
  };

  virtualisation.oci-containers.containers.slskd = slskdContainer;

  networking.firewall.allowedTCPPorts = [ 50300 ];

  services.caddy.virtualHosts."hwc.ocelot-wahoo.ts.net".extraConfig = slskdCaddyCfg;

  systemd.services."podman-slskd".after = [ "network-online.target" ];
  systemd.services."podman-slskd".wants = [ "network-online.target" ];
}