# -----------------------------------------------------------------------------
# SERVER CONTAINERS - Heartwood Craft Homeserver
# OCI container definitions for media, business, and surveillance services
# All containers managed via Podman with custom networking
# -----------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # 1. CONTAINER ORCHESTRATION
  ####################################################################
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      # VPN Gateway
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

      # Download Clients
      sabnzbd = {
        image = "lscr.io/linuxserver/sabnzbd:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = [ "--network=container:gluetun" ];
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "America/Denver";
        };
        volumes = [
          "/opt/downloads/sabnzbd:/config"
          "/mnt/media/downloads:/downloads"
          "/mnt/media/incomplete:/incomplete-downloads"
        ];
      };

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
          "/mnt/media:/media"
          "/mnt/media/downloads:/downloads"
        ];
      };

      # Media Management
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
          "/mnt/media:/media"
          "/mnt/media/downloads:/downloads"
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
          "/mnt/media:/media"
          "/mnt/media/downloads:/downloads"
        ];
      };

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
          "/mnt/media:/media"
          "/mnt/media/downloads:/downloads"
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

            # Soulseek daemon (slskd)
      slskd = {
        image = "slskd/slskd:latest";
        autoStart = true;
        ports = [ 
          "5030:5030"   # Web interface
          "50300:50300" # Soulseek port
        ];
        volumes = [
          "/opt/downloads/slskd:/app"
          "/mnt/media:/data"  # Shared with other media apps
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
          SLSKD_REMOTE_CONFIGURATION = "true";
        };
        extraOptions = [ "--network=media-network" ];
      };

      # Soularr bridge script
      soularr = {
        image = "mrusse08/soularr:latest";
        autoStart = true;
        volumes = [
          "/opt/downloads/slskd/downloads:/downloads"  # slskd download folder
          "/opt/downloads/soularr:/data"               # Soularr config
        ];
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = "America/Denver";
          SCRIPT_INTERVAL = "300";  # Run every 5 minutes
        };
        extraOptions = [ "--network=media-network" ];
        dependsOn = [ "slskd" ];
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
          "/mnt/media/music:/music:ro"
        ];
      };

      # Photo Management
      immich = {
        image = "ghcr.io/immich-app/immich-server:release";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
        environment = {
          UPLOAD_LOCATION = "/photos";
          DB_HOSTNAME = "immich-postgres";
          DB_USERNAME = "postgres";
          DB_PASSWORD = "postgres";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "immich-redis";
          TZ = "America/Denver";
        };
        ports = [ "2283:3001" ];
        volumes = [
          "/opt/downloads/immich/upload:/photos"
          "/etc/localtime:/etc/localtime:ro"
        ];
        dependsOn = [ "immich-postgres" "immich-redis" ];
      };

      immich-postgres = {
        image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_DB = "immich";
        };
        volumes = [
          "/opt/downloads/immich/database:/var/lib/postgresql/data"
        ];
      };

      immich-redis = {
        image = "redis:6.2-alpine";
        autoStart = true;
        extraOptions = [ "--network=media-network" ];
      };
    };
  };

  ####################################################################
  # 2. CONTAINER NETWORK SETUP
  ####################################################################
  # Create the media-network for containers
  systemd.tmpfiles.rules = [
  # Soulseek/Soularr directories
  "d /opt/downloads/slskd 0755 eric users -"
  "d /opt/downloads/slskd/downloads 0755 eric users -" 
  "d /opt/downloads/soularr 0755 eric users -"
  "d /mnt/media/music/soulseek 0755 eric users -"
  ];
  systemd.services.init-media-network = {
    description = "Create media-network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = let dockercli = "${pkgs.podman}/bin/podman"; in ''
      # Put a true at the end to prevent getting non-zero return code, which will
      # crash the whole service.
      check=$(${dockercli} network ls | grep "media-network" || true)
      if [ -z "$check" ]; then
        ${dockercli} network create media-network
      else
        echo "media-network already exists in podman"
      fi
    '';
  };
}