# hosts/server/modules/media-containers-v2.nix
# Updated container configuration with GPU acceleration and hot/cold storage tiers
{ config, lib, pkgs, ... }:

let
  # Helper function for config volumes
  configVol = service: "/opt/downloads/${service}:/config";
  
  # Standard environment for media services
  mediaServiceEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = "America/Denver";
  };
  
  # Network options
  mediaNetworkOptions = [ "--network=media-network" ];
  vpnNetworkOptions = [ "--network=container:gluetun" ];
  
  # GPU options - Direct device access without runtime
  nvidiaGpuOptions = [ 
    "--device=/dev/nvidia0:/dev/nvidia0:rwm"
    "--device=/dev/nvidiactl:/dev/nvidiactl:rwm" 
    "--device=/dev/nvidia-modeset:/dev/nvidia-modeset:rwm"
    "--device=/dev/nvidia-uvm:/dev/nvidia-uvm:rwm"
    "--device=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools:rwm"
    "--device=/dev/dri:/dev/dri:rwm"
  ];
  intelGpuOptions = [ "--device=/dev/dri:/dev/dri" ];
  
  # GPU environment
  nvidiaEnv = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
  };
  
  intelEnv = {
    LIBVA_DRIVER_NAME = "nvidia";
    VDPAU_DRIVER = "nvidia";
  };
  
  # Volume patterns
  hotCache = service: "/mnt/hot/cache/${service}:/cache";
  torrentDownloads = "/mnt/hot/downloads/torrents:/downloads";
  usenetDownloads = "/mnt/hot/downloads/usenet:/downloads";
  coldMedia = "/mnt/media:/cold-media";
  localtime = "/etc/localtime:/etc/localtime:ro";
  
  # Container builders
  buildMediaServiceContainer = { name, image, mediaType, extraVolumes ? [], extraOptions ? [], environment ? {} }: {
    inherit image;
    autoStart = true;
    extraOptions = mediaNetworkOptions ++ extraOptions;
    environment = mediaServiceEnv // environment;
    ports = {
      "sonarr" = [ "8989:8989" ];
      "radarr" = [ "7878:7878" ];
      "lidarr" = [ "8686:8686" ];
    }.${name} or [];
    volumes = [
      (configVol name)
      "/mnt/media/${mediaType}:/${mediaType}"
      "/mnt/hot/downloads:/hot-downloads"
      "/mnt/hot/manual/${mediaType}:/manual"
      "/mnt/hot/quarantine/${mediaType}:/quarantine"
      "/mnt/hot/processing/${name}-temp:/processing"
    ] ++ extraVolumes;
  };
  
  buildDownloadContainer = { name, image, downloadPath, network ? "vpn", extraVolumes ? [], extraOptions ? [], environment ? {} }: {
    inherit image;
    autoStart = true;
    dependsOn = if network == "vpn" then [ "gluetun" ] else [];
    extraOptions = (if network == "vpn" then vpnNetworkOptions else mediaNetworkOptions) ++ extraOptions;
    environment = mediaServiceEnv // environment;
    ports = {
      "qbittorrent" = [ "8080:8080" ];
      "sabnzbd" = [ "8081:8081" ];
    }.${name} or [];
    volumes = [
      (configVol name)
      downloadPath
    ] ++ extraVolumes;
  };
in

{
  ####################################################################
  # 0. NETWORK SETUP
  ####################################################################
  
  # Create media-network for container communication
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

  ####################################################################
  # 1. CONTAINER ORCHESTRATION WITH GPU SUPPORT
  ####################################################################
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      
      # VPN Gateway (unchanged)
      gluetun = {
        image = "qmcgaw/gluetun";
        autoStart = true;
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
          "--network=media-network"
        ];
        environmentFiles = [ "/opt/downloads/.env" ];
        ports = [ 
          "8080:8080"  # qBittorrent
          "8081:8081"  # SABnzbd
        ];
        volumes = [ "/opt/downloads/gluetun:/gluetun" ];
      };

      # Download Clients - Updated for Hot Storage
      qbittorrent = buildDownloadContainer {
        name = "qbittorrent";
        image = "lscr.io/linuxserver/qbittorrent";
        downloadPath = torrentDownloads;
        network = "vpn";
        extraVolumes = [
          coldMedia
          (hotCache "qbittorrent")
        ];
        environment = { WEBUI_PORT = "8080"; };
      };

      sabnzbd = buildDownloadContainer {
        name = "sabnzbd";
        image = "lscr.io/linuxserver/sabnzbd:latest";
        downloadPath = usenetDownloads;
        network = "vpn";
        extraVolumes = [
          "/mnt/hot/cache:/incomplete-downloads"
        ];
      };

      # Media Management - Updated for Hot/Cold Storage Split
      lidarr = buildMediaServiceContainer {
        name = "lidarr";
        image = "lscr.io/linuxserver/lidarr:latest";
        mediaType = "music";
      };

      sonarr = buildMediaServiceContainer {
        name = "sonarr";
        image = "lscr.io/linuxserver/sonarr:latest";
        mediaType = "tv";
      };

      radarr = buildMediaServiceContainer {
        name = "radarr";
        image = "lscr.io/linuxserver/radarr:latest";
        mediaType = "movies";
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = mediaServiceEnv;
        ports = [ "9696:9696" ];
        volumes = [
          (configVol "prowlarr")
        ];
      };

      # Soulseek Client
      slskd = {
        image = "slskd/slskd";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = mediaServiceEnv // {
          SLSKD__WEB__AUTHENTICATION__USERNAME = "eriqueok";
          SLSKD__WEB__AUTHENTICATION__PASSWORD = "il0wwlm?";
        };
        ports = [ "5030:5030" ];
        cmd = [ "--config" "/config/slskd.yml" ];
        volumes = [
          (configVol "slskd")
          "/mnt/hot/downloads/soulseek:/data/downloads/soulseek"
          "/mnt/media/music:/data/music:ro"
          "/mnt/media/music-soulseek:/data/music-soulseek"
        ];
      };

      # Media Streaming - GPU Accelerated
      # jellyfin = {
      #   image = "lscr.io/linuxserver/jellyfin:latest";
      #   autoStart = true;
      #   extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ intelGpuOptions;
      #   environment = mediaServiceEnv // nvidiaEnv;
      #   ports = [ "8096:8096" ];
      #   volumes = [
      #     (configVol "jellyfin")
      #     "/mnt/media:/media"
      #     (hotCache "jellyfin")
      #   ];
      # };
      # Disabled: Using native Jellyfin service instead to avoid port conflicts

      # Music Streaming
      navidrome = {
        image = "deluan/navidrome";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = {
          ND_MUSICFOLDER = "/music";
          ND_DATAFOLDER = "/data";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
        };
        ports = [ "4533:4533" ];
        volumes = [
          (configVol "navidrome")
          "/mnt/media/music:/music:ro"
        ];
      };

      # Surveillance System - GPU Accelerated
      frigate = {
        image = "ghcr.io/blakeblackshear/frigate:stable";
        autoStart = true;
        extraOptions = [ "--network=host" ] ++ nvidiaGpuOptions ++ [
          "--privileged"
          "--tmpfs=/tmp/cache:size=1g"
          "--shm-size=512m"
          "--memory=6g"
          "--cpus=2.0"
        ];
        environment = {
          FRIGATE_RTSP_PASSWORD = "iL0wwlm?";
          TZ = "America/Denver";
        } // nvidiaEnv // intelEnv;
        volumes = [
          "/opt/surveillance/frigate/config:/config"
          "/mnt/media/surveillance/frigate/media:/media/frigate"
          "/mnt/hot/surveillance/buffer:/tmp/frigate"
          localtime
        ];
        ports = [
          "5000:5000"
          "8554:8554"
          "8555:8555/tcp"
          "8555:8555/udp"
        ];
      };

    };
  };

  # Network setup is now handled by the common module
}
