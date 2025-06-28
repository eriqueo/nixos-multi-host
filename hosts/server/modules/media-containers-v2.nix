# hosts/server/modules/media-containers-v2.nix
# Updated container configuration with GPU acceleration and hot/cold storage tiers
{ config, lib, pkgs, ... }:

{
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
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = [ "--network=container:gluetun" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
          WEBUI_PORT = "8080";
        };
        volumes = [
          "/opt/downloads/qbittorrent:/config"
          "/mnt/media:/cold-media"                      # Cold storage access for library
          "/mnt/hot/downloads/torrents:/downloads"      # Hot storage for active downloads
          "/mnt/hot/cache:/cache"                       # Hot storage for temp files
        ];
      };

      sabnzbd = {
        image = "lscr.io/linuxserver/sabnzbd:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = [ "--network=container:gluetun" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
        volumes = [
          "/opt/downloads/sabnzbd:/config"
          "/mnt/hot/downloads/usenet:/downloads"        # Hot storage for downloads
          "/mnt/hot/cache:/incomplete-downloads"        # Hot storage for incomplete
        ];
      };

      # Media Management - Updated for Hot/Cold Storage Split
      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
        ports = [ "8686:8686" ];
        volumes = [
          "/opt/downloads/lidarr:/config"
          "/mnt/media/music:/music"                     # Cold storage - final library
          "/mnt/hot/downloads:/hot-downloads"           # Hot storage - active downloads
          "/mnt/hot/manual/music:/manual"               # Hot storage - manual processing
          "/mnt/hot/quarantine/music:/quarantine"       # Hot storage - quarantine
          "/mnt/hot/processing/lidarr-temp:/processing" # Hot storage - temp work
        ];
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
        ports = [ "8989:8989" ];
        volumes = [
          "/opt/downloads/sonarr:/config"
          "/mnt/media/tv:/tv"                           # Cold storage - final library
          "/mnt/hot/downloads:/hot-downloads"           # Hot storage - active downloads
          "/mnt/hot/manual/tv:/manual"                  # Hot storage - manual processing
          "/mnt/hot/quarantine/tv:/quarantine"          # Hot storage - quarantine
          "/mnt/hot/processing/sonarr-temp:/processing" # Hot storage - temp work
        ];
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
        ports = [ "7878:7878" ];
        volumes = [
          "/opt/downloads/radarr:/config"
          "/mnt/media/movies:/movies"                   # Cold storage - final library
          "/mnt/hot/downloads:/hot-downloads"           # Hot storage - active downloads
          "/mnt/hot/manual/movies:/manual"              # Hot storage - manual processing
          "/mnt/hot/quarantine/movies:/quarantine"      # Hot storage - quarantine
          "/mnt/hot/processing/radarr-temp:/processing" # Hot storage - temp work
        ];
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
        };
        ports = [ "9696:9696" ];
        volumes = [
          "/opt/downloads/prowlarr:/config"
        ];
      };

      # Media Streaming - GPU Accelerated
      jellyfin = {
        image = "lscr.io/linuxserver/jellyfin:latest";
        autoStart = true;
        extraOptions = [ 
          "--network=media-network"
          # GPU acceleration for transcoding
          "--device=/dev/dri:/dev/dri"                  # Intel iGPU access
          "--runtime=nvidia"                            # NVIDIA runtime
          "--gpus=all"                                  # All NVIDIA GPUs
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
          # NVIDIA specific environment variables
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
        };
        ports = [ "8096:8096" ];
        volumes = [
          "/opt/downloads/jellyfin:/config"
          "/mnt/media:/media"                           # Cold storage - media libraries
          "/mnt/hot/cache/jellyfin:/cache"              # Hot storage - transcoding cache
        ];
      };

      # Music Streaming
      navidrome = {
        image = "deluan/navidrome";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
        environment = {
          ND_MUSICFOLDER = "/music";
          ND_DATAFOLDER = "/data";
          ND_LOGLEVEL = "info";
          ND_SESSIONTIMEOUT = "24h";
        };
        ports = [ "4533:4533" ];
        volumes = [
          "/opt/downloads/navidrome:/data"
          "/mnt/media/music:/music:ro"                  # Cold storage - music library
        ];
      };

      # Surveillance System - GPU Accelerated
      frigate = {
        image = "ghcr.io/blakeblackshear/frigate:stable";
        autoStart = true;
        extraOptions = [
          "--privileged"
          "--network=host"
          # GPU acceleration for video processing
          "--runtime=nvidia"
          "--gpus=all"
          # Shared memory and resource limits
          "--tmpfs=/tmp/cache:size=1g"
          "--shm-size=512m"
          "--memory=6g"
          "--cpus=2.0"
        ];
        environment = {
          FRIGATE_RTSP_PASSWORD = "iL0wwlm?";
          TZ = "America/Denver";
          # NVIDIA specific for hardware acceleration
          NVIDIA_VISIBLE_DEVICES = "all";
          NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
          # Hardware acceleration environment
          LIBVA_DRIVER_NAME = "nvidia";
          VDPAU_DRIVER = "nvidia";
        };
        volumes = [
          "/opt/surveillance/frigate/config:/config"
          "/mnt/media/surveillance/frigate/media:/media/frigate"     # Cold storage - recordings
          "/mnt/hot/surveillance/buffer:/tmp/frigate"                # Hot storage - buffer
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [
          "5000:5000"
          "8554:8554"
          "8555:8555/tcp"
          "8555:8555/udp"
        ];
      };

      home-assistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        environment = {
          TZ = "America/Denver";
        };
        volumes = [
          "/opt/surveillance/home-assistant/config:/config"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [ "8123:8123" ];
      };
    };
  };

  ####################################################################
  # 2. CONTAINER NETWORK SETUP (unchanged)
  ####################################################################
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
}
