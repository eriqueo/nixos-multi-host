# modules/containers/common.nix
# Common container configuration patterns and utilities
{ config, lib, pkgs, ... }:

with lib;

let
  # Configuration defaults
  defaultTimezone = "America/Denver";
  defaultUser = {
    PUID = "1000";
    PGID = "1000";
  };

  # Utility functions for container configurations
  containerUtils = rec {
    # Standard LinuxServer.io environment
    linuxServerEnv = timezone: userConfig: userConfig // {
      TZ = timezone;
    };

    # Standard media service environment
    mediaServiceEnv = linuxServerEnv defaultTimezone defaultUser;

    # VPN container network sharing
    vpnNetworkOptions = [ "--network=container:gluetun" ];

    # Media network options
    mediaNetworkOptions = [ "--network=media-network" ];

    # GPU acceleration options (NVIDIA)
    nvidiaGpuOptions = [
      "--runtime=nvidia"
      "--gpus=all"
    ];

    # GPU acceleration options (Intel)
    intelGpuOptions = [
      "--device=/dev/dri:/dev/dri"
    ];

    # NVIDIA environment variables
    nvidiaEnv = {
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
    };

    # Intel GPU environment variables
    intelEnv = {
      LIBVA_DRIVER_NAME = "nvidia";
      VDPAU_DRIVER = "nvidia";
    };

    # Common surveillance/processing resource limits
    surveillanceOptions = [
      "--privileged"
      "--tmpfs=/tmp/cache:size=1g"
      "--shm-size=512m"
      "--memory=6g"
      "--cpus=2.0"
    ];

    # Standard volume mount patterns
    volumes = {
      # Config directory mount
      config = service: "/opt/downloads/${service}:/config";
      
      # Media library mounts (read-only)
      mediaLibraryRO = type: "/mnt/media/${type}:/${type}:ro";
      mediaLibrary = type: "/mnt/media/${type}:/${type}";
      
      # Hot storage patterns
      hotDownloads = "/mnt/hot/downloads:/hot-downloads";
      hotCache = service: "/mnt/hot/cache/${service}:/cache";
      hotProcessing = service: "/mnt/hot/processing/${service}-temp:/processing";
      hotManual = type: "/mnt/hot/manual/${type}:/manual";
      hotQuarantine = type: "/mnt/hot/quarantine/${type}:/quarantine";
      
      # Cold storage patterns
      coldMedia = "/mnt/media:/cold-media";
      
      # Download client specific
      torrentDownloads = "/mnt/hot/downloads/torrents:/downloads";
      usenetDownloads = "/mnt/hot/downloads/usenet:/downloads";
      usenetIncomplete = "/mnt/hot/cache:/incomplete-downloads";
      
      # Surveillance
      surveillanceMedia = "/mnt/media/surveillance/frigate/media:/media/frigate";
      surveillanceBuffer = "/mnt/hot/surveillance/buffer:/tmp/frigate";
      
      # System
      localtime = "/etc/localtime:/etc/localtime:ro";
    };

    # Standard port mappings
    ports = {
      # Media management
      sonarr = [ "8989:8989" ];
      radarr = [ "7878:7878" ];
      lidarr = [ "8686:8686" ];
      prowlarr = [ "9696:9696" ];
      
      # Download clients
      qbittorrent = [ "8080:8080" ];
      sabnzbd = [ "8081:8081" ];
      
      # Media streaming
      jellyfin = [ "8096:8096" ];
      navidrome = [ "4533:4533" ];
      
      # Surveillance
      frigate = [ "5000:5000" "8554:8554" "8555:8555/tcp" "8555:8555/udp" ];
      homeAssistant = [ "8123:8123" ];
    };

    # Directory creation patterns
    directories = {
      # Base container config directories
      containerConfigs = services: map (service: "d /opt/downloads/${service} 0755 eric users -") services;
      
      # Surveillance directories
      surveillanceBase = [
        "d /opt/surveillance 0755 eric users -"
        "d /opt/surveillance/frigate 0755 eric users -"
        "d /opt/surveillance/frigate/config 0755 eric users -"
        "d /opt/surveillance/home-assistant 0755 eric users -"
        "d /opt/surveillance/home-assistant/config 0755 eric users -"
      ];
      
      # Hot storage structure
      hotStorageBase = [
        "d /mnt/hot 0755 eric users -"
        "d /mnt/hot/downloads 0755 eric users -"
        "d /mnt/hot/cache 0755 eric users -"
        "d /mnt/hot/processing 0755 eric users -"
        "d /mnt/hot/manual 0755 eric users -"
        "d /mnt/hot/quarantine 0755 eric users -"
        "d /mnt/hot/surveillance 0755 eric users -"
        "d /mnt/hot/surveillance/buffer 0755 eric users -"
      ];
      
      # Hot storage by media type
      hotStorageByType = types: flatten (map (type: [
        "d /mnt/hot/downloads/${type} 0755 eric users -"
        "d /mnt/hot/manual/${type} 0755 eric users -"
        "d /mnt/hot/quarantine/${type} 0755 eric users -"
        "d /mnt/hot/processing/${type} 0755 eric users -"
      ]) types);
      
      # Download client specific directories
      downloadClients = [
        "d /mnt/hot/downloads/torrents 0755 eric users -"
        "d /mnt/hot/downloads/usenet 0755 eric users -"
      ];
    };

    # Complete container definition builders
    buildLinuxServerContainer = { name, image, port ? null, volumes, extraOptions ? [], environment ? {}, dependsOn ? [] }: {
      inherit image;
      autoStart = true;
      extraOptions = extraOptions;
      environment = mediaServiceEnv // environment;
      volumes = volumes;
      ports = if port != null then [ port ] else [];
      dependsOn = dependsOn;
    };

    buildMediaServiceContainer = { name, image, mediaType, extraVolumes ? [], extraOptions ? [], environment ? {} }:
      buildLinuxServerContainer {
        inherit name image extraOptions environment;
        port = ports.${name} or null;
        volumes = [
          (volumes.config name)
          (volumes.mediaLibrary mediaType)
          volumes.hotDownloads
          (volumes.hotManual mediaType)
          (volumes.hotQuarantine mediaType)
          (volumes.hotProcessing name)
        ] ++ extraVolumes;
        extraOptions = mediaNetworkOptions ++ extraOptions;
      };

    buildDownloadContainer = { name, image, downloadPath, network ? "vpn", extraVolumes ? [], extraOptions ? [], environment ? {} }:
      buildLinuxServerContainer {
        inherit name image extraOptions environment;
        port = ports.${name} or null;
        volumes = [
          (volumes.config name)
          downloadPath
        ] ++ extraVolumes;
        extraOptions = (if network == "vpn" then vpnNetworkOptions else mediaNetworkOptions) ++ extraOptions;
        dependsOn = if network == "vpn" then [ "gluetun" ] else [];
      };
  };

in

{
  options.containers.common = {
    enable = mkEnableOption "Common container utilities";
    
    defaultTimezone = mkOption {
      type = types.str;
      default = defaultTimezone;
      description = "Default timezone for containers";
    };
    
    defaultUser = mkOption {
      type = types.attrs;
      default = defaultUser;
      description = "Default user/group IDs for containers";
    };
  };

  config = mkIf config.containers.common.enable {
    # Common network setup service
    systemd.services.init-media-network = {
      description = "Create media-network";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = let dockercli = "${pkgs.podman}/bin/podman"; in ''
        check=$(${dockercli} network ls | grep "media-network" || true)
        if [ -z "$check" ]; then
          ${dockercli} network create media-network
        else
          echo "media-network already exists in podman"
        fi
      '';
    };
  };

  # Export utility functions to be used by other modules
  lib.containers = containerUtils;
}