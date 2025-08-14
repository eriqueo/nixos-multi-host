{ config, lib, pkgs, ... }:

let
  cfg = config.hwc.networking.mediaNetwork;
in
{
  options.hwc.networking.mediaNetwork = {
    enable = lib.mkEnableOption "Create a shared Podman network for media services";
    name = lib.mkOption {
      type = lib.types.str;
      default = "media-network";
      description = "Name of the Podman network used by media containers";
    };
  };

  config = lib.mkIf cfg.enable {
    # Single authoritative creator of the media network
    systemd.services.hwc-media-network = {
      description = "Create shared Podman media network";
      after = [ "podman.service" ];
      requires = [ "podman.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.bash}/bin/bash"
          "-lc"
          ''
            set -euo pipefail
            if ! ${pkgs.podman}/bin/podman network exists ${cfg.name}; then
              ${pkgs.podman}/bin/podman network create ${cfg.name}
            fi
          ''
        ];
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
