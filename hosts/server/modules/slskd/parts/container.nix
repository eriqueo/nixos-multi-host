# modules/server/slskd/parts/container.nix
# Returns the attribute set for the virtualisation.oci-containers definition.
{ config, lib, pkgs, yamlConfig }:

let
  # These paths should be defined in your main configuration
  # and passed down, but for a self-contained module, we can
  # redefine them or assume they exist.
  hotRoot   = "/mnt/hot";
  mediaRoot = "/mnt/media";
  configFile = pkgs.writeText "slskd.yml" yamlConfig;
in
{
  image = "ghcr.io/slskd/slskd:0.23.2";
  autoStart = true;

  extraOptions = [
    "--network=media-network"
    "--mount=type=bind,source=${
      pkgs.writeText "slskd.yml" yamlConfig
    },destination=/app/slskd.yml,readonly"
  ];

  ports = [ "127.0.0.1:5030:5030" ];

  volumes = [
    "${mediaRoot}/music:/music:ro"
    "${hotRoot}/downloads/incomplete:/downloads/incomplete"
    "${hotRoot}/downloads/complete:/downloads/complete"
  ];

  environment = {
    PUID = "1000";
    PGID = "1000";
    TZ   = "America/Denver";
  };
}
