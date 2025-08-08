{ config, lib, pkgs, ... }:

let
  mediaNet = config.hwc.networking.mediaNetwork.name or "media-network";

  # Build a minimal image that includes a Python WITH packages
  py = pkgs.python311.withPackages (ps: [
    ps.fastapi
    ps.uvicorn
    ps.pydantic
    ps.httpx
    ps.aiofiles
    ps.youtube-transcript-api
    ps.python-slugify
    ps.yt-dlp
  ]);

  transcriptImage = pkgs.dockerTools.buildImage {
    name = "hwc/transcript-api";
    tag = "latest";
    contents = [ py pkgs.bash pkgs.coreutils ];
    config = {
      # We run the host-mounted script using the bundled interpreter
      Cmd = [ "${py}/bin/python3" "/app/yt-transcript-api.py" ];
      WorkingDir = "/app";
      ExposedPorts = { "8099/tcp" = { }; };
      Env = [
        "PYTHONUNBUFFERED=1"
      ];
    };
  };

  # Paths & env
  TRANSCRIPTS_ROOT = "/mnt/media/transcripts";
  HOT_ROOT         = "/mnt/hot";
in
{
  # Ensure our network exists first
  systemd.services."podman-transcript-api".after = [ "hwc-media-network.service" "load-transcript-image.service" ];
  systemd.services."podman-transcript-api".requires = [ "load-transcript-image.service" ];

  # Load the built image once (and keep it cached)
  systemd.services.load-transcript-image = {
    description = "Load transcript container image";
    after = [ "podman.service" ];
    requires = [ "podman.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman load -i ${transcriptImage}";
    };
    wantedBy = [ "multi-user.target" ];
  };

  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.transcript-api = {
    image = "localhost/hwc/transcript-api:latest";
    autoStart = true;
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ   = config.time.timeZone or "UTC";
      TRANSCRIPTS_ROOT = TRANSCRIPTS_ROOT;
      HOT_ROOT         = HOT_ROOT;
      LANGS            = "en,en-US,en-GB";
      API_HOST         = "0.0.0.0";
      API_PORT         = "8099";
      RATE_LIMIT       = "10";
      FREE_SPACE_GB_MIN = "5";
      RETENTION_DAYS    = "90";
      WEBHOOKS          = "1";
      PYTHONUNBUFFERED  = "1";
    };
    ports = [ "8099:8099" ];
    volumes = [
      "/etc/nixos/scripts:/app:ro"               # expects yt-transcript-api.py here
      "${TRANSCRIPTS_ROOT}:${TRANSCRIPTS_ROOT}"
      "${HOT_ROOT}:${HOT_ROOT}"
      "/opt/transcript:/config"
      "/etc/localtime:/etc/localtime:ro"
    ];
    extraOptions = [
      "--network=${mediaNet}"
    ];
  };

  # Simple weekly cleanup timer (unchanged behavior)
  systemd.services.transcript-cleanup = {
    description = "Cleanup old transcript files";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "transcript-cleanup" ''
        set -euo pipefail
        RETENTION_DAYS=${lib.escapeShellArg (toString 90)}
        TRANSCRIPTS_ROOT=${lib.escapeShellArg TRANSCRIPTS_ROOT}
        if [[ -d "$TRANSCRIPTS_ROOT" ]]; then
          find "$TRANSCRIPTS_ROOT" -type f -name "*.md"  -mtime +$RETENTION_DAYS -delete || true
          find "$TRANSCRIPTS_ROOT" -type f -name "*.zip" -mtime +$RETENTION_DAYS -delete || true
          find "$TRANSCRIPTS_ROOT" -type d -empty -delete || true
        fi
      '';
    };
  };

  systemd.timers.transcript-cleanup = {
    description = "Weekly transcript cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Local firewall: we expose 8099 to localhost only via Caddy/Tailscale upstreams as desired
  networking.firewall.allowedTCPPorts = lib.mkDefault [ ];
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8099 ];
}
