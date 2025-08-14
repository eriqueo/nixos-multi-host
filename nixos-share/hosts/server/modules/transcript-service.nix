# hosts/server/modules/transcript-service.nix
# YouTube Transcript extraction service with API and CLI
{ config, lib, pkgs, ... }:

let
  # Standard environment for media services (matching your pattern)
  serviceEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = "America/Denver";
    TRANSCRIPTS_ROOT = "/home/eric/01-documents/01-vaults/04-transcripts";
    HOT_ROOT = "/mnt/hot";
    LANGS = "en,en-US,en-GB";
    API_HOST = "0.0.0.0";
    API_PORT = "8099";
    RATE_LIMIT = "10";
    FREE_SPACE_GB_MIN = "5";
    RETENTION_DAYS = "90";
    WEBHOOKS = "1";
  };

  # Network options (following your media-containers pattern)
  mediaNetworkOptions = [ "--network=media-network" ];

  # Volume patterns (following your storage tier approach)
  configVol = "/opt/transcript:/config";
  transcriptsVol = "/home/eric/01-documents/01-vaults/04-transcripts:/home/eric/01-documents/01-vaults/04-transcripts";
  hotVol = "/mnt/hot:/mnt/hot";
  localtime = "/etc/localtime:/etc/localtime:ro";

  # Container image build (using your existing patterns)
  transcriptImage = pkgs.dockerTools.buildImage {
    name = "hwc/transcript-api";
    tag = "latest";
    
    copyToRoot = pkgs.buildEnv {
      name = "transcript-rootfs";
      paths = with pkgs; [
        python311
        python311Packages.fastapi
        python311Packages.uvicorn
        python311Packages.pydantic
        python311Packages.httpx
        python311Packages.aiofiles
        python311Packages.python-slugify
        yt-dlp
        python311Packages.youtube-transcript-api
        bash
        coreutils
      ];
      pathsToLink = [ "/bin" "/lib" ];
    };
    
    config = {
      Cmd = [ 
        "${pkgs.python311}/bin/python3" 
        "/etc/nixos/scripts/yt-transcript-api.py" 
      ];
      Env = [
        "PYTHONUNBUFFERED=1"
        "PYTHONPATH=/etc/nixos/scripts"
      ];
      ExposedPorts = {
        "8099/tcp" = {};
      };
      WorkingDir = "/";
    };
  };

in

{
  # Install CLI tool system-wide
  environment.systemPackages = with pkgs; [
    # Python dependencies for CLI tool
    python311
    python311Packages.pydantic
    python311Packages.httpx
    python311Packages.aiofiles
    python311Packages.python-slugify
    yt-dlp
    python311Packages.youtube-transcript-api
    
    # Custom CLI wrapper script
    (pkgs.writeShellScriptBin "yt-transcript" ''
      export PYTHONPATH="/etc/nixos/scripts:$PYTHONPATH"
      exec ${pkgs.python311}/bin/python3 /etc/nixos/scripts/yt-transcript.py "$@"
    '')
  ];

  # Create required directories
  systemd.tmpfiles.rules = [
    "d /opt/transcript 0755 root root -"
    "d /home/eric/01-documents/01-vaults/04-transcripts 0755 eric eric -"
    "d /home/eric/01-documents/01-vaults/04-transcripts/individual 0755 eric eric -"
    "d /home/eric/01-documents/01-vaults/04-transcripts/playlists 0755 eric eric -"
    "d /home/eric/01-documents/01-vaults/04-transcripts/api-requests 0755 eric eric -"
    "d /mnt/hot/transcript-temp 0755 root root -"
  ];

  # Create media network for containers (if not already created)
  systemd.services.create-media-network = {
    description = "Create media container network";
    after = [ "podman.service" ];
    requires = [ "podman.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network exists media-network || ${pkgs.podman}/bin/podman network create media-network";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Load container image
  systemd.services.load-transcript-image = {
    description = "Load transcript container image";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman load -i ${transcriptImage}";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Transcript API service
  systemd.services."podman-transcript-api" = {
    description = "YouTube Transcript API Service";
    after = [ "network.target" "podman.service" "create-media-network.service" "load-transcript-image.service" ];
    requires = [ "podman.service" "create-media-network.service" "load-transcript-image.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "forking";
      Restart = "on-failure";
      RestartSec = "30s";
      TimeoutStartSec = "5m";
      
      ExecStartPre = "${pkgs.podman}/bin/podman rm -f transcript-api || true";
      
      ExecStart = toString [
        "${pkgs.podman}/bin/podman run"
        "--name transcript-api"
        "--detach"
        "--publish 8099:8099"
        "--volume /etc/nixos/scripts:/etc/nixos/scripts:ro"
        "--volume ${transcriptsVol}"
        "--volume ${hotVol}"
        "--volume ${configVol}"
        "--volume ${localtime}"
        "--memory=1g"
        "--cpus=0.5"
        "--memory-swap=2g"
      ] ++ mediaNetworkOptions ++ [
        "--env TRANSCRIPTS_ROOT=/home/eric/01-documents/01-vaults/04-transcripts"
        "--env HOT_ROOT=${serviceEnv.HOT_ROOT}"
        "--env API_HOST=${serviceEnv.API_HOST}"
        "--env API_PORT=${serviceEnv.API_PORT}"
        "--env LANGS=${serviceEnv.LANGS}"
        "--env RATE_LIMIT=${serviceEnv.RATE_LIMIT}"
        "--env FREE_SPACE_GB_MIN=${serviceEnv.FREE_SPACE_GB_MIN}"
        "--env RETENTION_DAYS=${serviceEnv.RETENTION_DAYS}"
        "--env WEBHOOKS=${serviceEnv.WEBHOOKS}"
        "--env TZ=${serviceEnv.TZ}"
        "--env PUID=${serviceEnv.PUID}"
        "--env PGID=${serviceEnv.PGID}"
        "--env PYTHONPATH=/etc/nixos/scripts"
        "--env PYTHONUNBUFFERED=1"
        "hwc/transcript-api:latest"
      ];
      
      ExecStop = "${pkgs.podman}/bin/podman stop transcript-api";
    };
  };

  # Cleanup service for old transcripts
  systemd.services.transcript-cleanup = {
    description = "Cleanup old transcript files";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "transcript-cleanup" ''
        # Remove transcript files older than retention period
        RETENTION_DAYS=''${RETENTION_DAYS:-90}
        TRANSCRIPTS_ROOT=''${TRANSCRIPTS_ROOT:-/home/eric/01-documents/01-vaults/04-transcripts}
        
        if [[ -d "$TRANSCRIPTS_ROOT" ]]; then
          echo "Cleaning up transcript files older than $RETENTION_DAYS days..."
          find "$TRANSCRIPTS_ROOT" -type f -name "*.md" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
          find "$TRANSCRIPTS_ROOT" -type f -name "*.zip" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
          find "$TRANSCRIPTS_ROOT" -type d -empty -delete 2>/dev/null || true
          echo "Transcript cleanup completed"
        fi
      '';
    };
    environment = serviceEnv;
  };

  # Schedule cleanup weekly
  systemd.timers.transcript-cleanup = {
    description = "Weekly transcript cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [ 8099 ];
    interfaces."tailscale0".allowedTCPPorts = [ 8099 ];
  };

  # Optional: Basic auth configuration (add API keys via environment or secrets)
  # You can set API_KEYS environment variable for the container to enable auth
}