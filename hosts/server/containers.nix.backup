# -----------------------------------------------------------------------------
# SERVER CONTAINERS - Heartwood Craft Homeserver
# OCI container definitions for media, business, and surveillance services
# All containers managed via Podman with custom networking
# UPDATED: Safe media processing with manual/quarantine folders
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
          "/mnt/media/downloads/usenet:/downloads"              # UPDATED: Specific usenet folder
          "/mnt/media/downloads/usenet:/incomplete-downloads"   # UPDATED: Usenet incomplete
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
          "/mnt/media:/media"                                   # Full media access for library
          "/mnt/media/downloads/torrents:/downloads"            # UPDATED: Specific torrents folder
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
          "/mnt/media/downloads/soulseek:/data/downloads/soulseek"  # UPDATED: Specific soulseek folder
          "/mnt/media/music:/data/music"                            # Share existing music library
          "/mnt/media/music-soulseek:/data/music-soulseek"         # Separate soulseek collection
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
          "/mnt/media/downloads/soulseek:/downloads"            # UPDATED: Monitor soulseek downloads
          "/opt/downloads/soularr:/data"                        # Soularr config
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

      # Media Management - Lidarr (Music)
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
          "/mnt/media/music:/music"                             # UPDATED: Final music library
          "/mnt/media/downloads:/downloads"                     # UPDATED: All download folders
          "/mnt/media/manual/music:/manual"                     # UPDATED: Failed imports (SAFE)
          "/mnt/media/quarantine/music:/quarantine"             # UPDATED: Corrupted files (SAFE)
          # RandomNinjaAtk scripts (DISABLED until modified for safety):
          # "/opt/lidarr/custom-services.d:/custom-services.d"
          # "/opt/lidarr/custom-cont-init.d:/custom-cont-init.d"
        ];
      };

      # Media Management - Sonarr (TV)
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
          "/mnt/media/tv:/tv"                                   # UPDATED: Final TV library
          "/mnt/media/downloads:/downloads"                     # UPDATED: All download folders
          "/mnt/media/manual/tv:/manual"                        # UPDATED: Failed imports (SAFE)
          "/mnt/media/quarantine/tv:/quarantine"                # UPDATED: Corrupted files (SAFE)
          # RandomNinjaAtk scripts (DISABLED until modified for safety):
          # "/opt/sonarr/custom-services.d:/custom-services.d"
          # "/opt/sonarr/custom-cont-init.d:/custom-cont-init.d"
        ];
      };

      # Media Management - Radarr (Movies)
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
          "/mnt/media/movies:/movies"                           # UPDATED: Final movies library
          "/mnt/media/downloads:/downloads"                     # UPDATED: All download folders
          "/mnt/media/manual/movies:/manual"                    # UPDATED: Failed imports (SAFE)
          "/mnt/media/quarantine/movies:/quarantine"            # UPDATED: Corrupted files (SAFE)
          # RandomNinjaAtk scripts (DISABLED until modified for safety):
          # "/opt/radarr/custom-services.d:/custom-services.d"
          # "/opt/radarr/custom-cont-init.d:/custom-cont-init.d"
        ];
      };

      # Indexer Management
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
          "/mnt/media/music:/music:ro"                          # Main music library
          "/mnt/media/music-soulseek:/music-soulseek:ro"        # Soulseek collection
        ];
      };

      # Photo Management (Currently disabled)
      # immich = {
      #   image = "ghcr.io/immich-app/immich-server:release";
      #   autoStart = true;
      #   extraOptions = [ "--network=media-network" ];
      #   environment = {
      #     UPLOAD_LOCATION = "/photos";
      #     DB_HOSTNAME = "immich-postgres";
      #     DB_USERNAME = "postgres";
      #     DB_PASSWORD = "postgres";
      #     DB_DATABASE_NAME = "immich";
      #     REDIS_HOSTNAME = "immich-redis";
      #     TZ = "America/Denver";
      #   };
      #   ports = [ "2283:3001" ];
      #   volumes = [
      #     "/opt/downloads/immich/upload:/photos"
      #     "/etc/localtime:/etc/localtime:ro"
      #   ];
      #   dependsOn = [ "immich-postgres" "immich-redis" ];
      # };

      # immich-postgres = {
      #   image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
      #   autoStart = true;
      #   extraOptions = [ "--network=media-network" ];
      #   environment = {
      #     POSTGRES_USER = "postgres";
      #     POSTGRES_PASSWORD = "postgres";
      #     POSTGRES_DB = "immich";
      #   };
      #   volumes = [
      #     "/opt/downloads/immich/database:/var/lib/postgresql/data"
      #   ];
      # };

      # immich-redis = {
      #   image = "redis:6.2-alpine";
      #   autoStart = true;
      #   extraOptions = [ "--network=media-network" ];
      # };
    };
  };

  ####################################################################
  # 2. DIRECTORY STRUCTURE SETUP
  ####################################################################
  systemd.tmpfiles.rules = [
    # Download client directories
    "d /opt/downloads/qbittorrent 0755 eric users -"
    "d /opt/downloads/sabnzbd 0755 eric users -"
    "d /opt/downloads/slskd 0755 eric users -"
    "d /opt/downloads/soularr 0755 eric users -"
    
    # Media download folders by client and category
    "d /mnt/media/downloads 0755 eric users -"
    "d /mnt/media/downloads/torrents 0755 eric users -"
    "d /mnt/media/downloads/torrents/music 0755 eric users -"
    "d /mnt/media/downloads/torrents/movies 0755 eric users -"
    "d /mnt/media/downloads/torrents/tv 0755 eric users -"
    "d /mnt/media/downloads/usenet 0755 eric users -"
    "d /mnt/media/downloads/usenet/music 0755 eric users -"
    "d /mnt/media/downloads/usenet/movies 0755 eric users -"
    "d /mnt/media/downloads/usenet/tv 0755 eric users -"
    "d /mnt/media/downloads/usenet/software 0755 eric users -"
    "d /mnt/media/downloads/soulseek 0755 eric users -"
    
    # SAFE processing folders (NO DELETION)
    "d /mnt/media/manual 0755 eric users -"
    "d /mnt/media/manual/music 0755 eric users -"
    "d /mnt/media/manual/movies 0755 eric users -"
    "d /mnt/media/manual/tv 0755 eric users -"
    "d /mnt/media/quarantine 0755 eric users -"
    "d /mnt/media/quarantine/music 0755 eric users -"
    "d /mnt/media/quarantine/movies 0755 eric users -"
    "d /mnt/media/quarantine/tv 0755 eric users -"
    
    # Final library folders
    "d /mnt/media/music 0755 eric users -"
    "d /mnt/media/movies 0755 eric users -"
    "d /mnt/media/tv 0755 eric users -"
    "d /mnt/media/music-soulseek 0755 eric users -"
    
    # *arr configuration directories
    "d /opt/downloads/lidarr 0755 eric users -"
    "d /opt/downloads/sonarr 0755 eric users -"
    "d /opt/downloads/radarr 0755 eric users -"
    "d /opt/downloads/prowlarr 0755 eric users -"
    "d /opt/downloads/navidrome 0755 eric users -"
  ];

  ####################################################################
  # 3. CONTAINER NETWORK SETUP
  ####################################################################
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
