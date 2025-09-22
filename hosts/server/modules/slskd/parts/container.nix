# modules/server/slskd/parts/container.nix
# Returns the attribute set for the virtualisation.oci-containers definition.
{ config, lib, pkgs, configFile }:

let
  hotRoot = "/mnt/hot";
  mediaRoot = "/mnt/media";
in
{
  image = "ghcr.io/slskd/slskd:latest";
  autoStart = true;

  extraOptions = [
    "--network=media-network"
  ];

  cmd = [ "--config" "/slskd.yml" ];

  ports = [
    "127.0.0.1:5031:5030"
    "0.0.0.0:50300:50300/tcp"
  ];

  volumes = [
    "${mediaRoot}/music:/music:ro"
    "${hotRoot}/downloads/incomplete:/downloads/incomplete"
    "${hotRoot}/downloads/complete:/downloads/complete"
    "/etc/slskd/slskd.yml:/slskd.yml:ro"
  ];

  environment = {
    PUID = "1000";
    PGID = "1000";
    TZ = "America/Denver";
  };
}