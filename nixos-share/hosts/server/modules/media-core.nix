{ lib, pkgs, config, ... }:
let cfg = config.hwc.media;
in {
  options.hwc.media = {
    enable = lib.mkEnableOption "HWC shared media plumbing";
    networkName = lib.mkOption {
      type = lib.types.str; default = "media-network";
      description = "Shared Podman bridge network for media services.";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.hwc-media-network = {
      description = "Create shared media container network";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -e
        if ! ${pkgs.podman}/bin/podman network exists ${cfg.networkName}; then
          ${pkgs.podman}/bin/podman network create ${cfg.networkName}
        fi
      '';
    };
    # Safety-net: kill any legacy unit name if present
    systemd.services.create-media-network.enable = lib.mkForce false;
  };
}
