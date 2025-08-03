# hosts/server/modules/media-containers.nix
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
  torrentDownloads = "/mnt/hot/downloads:/downloads";
  usenetDownloads = "/mnt/hot/downloads:/downloads";
  coldMedia = "/mnt/media:/cold-media";
  localtime = "/etc/localtime:/etc/localtime:ro";

  # Container builders
  buildMediaServiceContainer = { name, image, mediaType, extraVolumes ? [], extraOptions ? [], environment ? {} }: {
    inherit image;
    autoStart = true;
    extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ extraOptions ++ [
      "--memory=2g"
      "--cpus=1.0"
      "--memory-swap=4g"
    ];
    environment = mediaServiceEnv // nvidiaEnv // environment;
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
    extraOptions = (if network == "vpn" then vpnNetworkOptions else mediaNetworkOptions) ++ nvidiaGpuOptions ++ extraOptions ++ [
      "--memory=2g"
      "--cpus=1.0"
      "--memory-swap=4g"
    ];
    environment = mediaServiceEnv // nvidiaEnv // environment;
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
  # SOPS secrets configuration for VPN credentials
  sops.secrets.vpn_username = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/username";
    mode = "0400";
    owner = "root";
    group = "root";
  };

  sops.secrets.vpn_password = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/password";
    mode = "0400";
    owner = "root";
    group = "root";
  };

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

  # Systemd service to generate Gluetun environment file from SOPS secrets
  systemd.services.gluetun-env-setup = {
    description = "Generate Gluetun environment file from SOPS secrets";
    before = [ "podman-gluetun.service" ];
    wantedBy = [ "podman-gluetun.service" ];
    wants = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      # Ensure downloads directory exists
      mkdir -p /opt/downloads

      # Read VPN credentials from SOPS secrets
      VPN_USERNAME=$(cat ${config.sops.secrets.vpn_username.path})
      VPN_PASSWORD=$(cat ${config.sops.secrets.vpn_password.path})

      # Generate Gluetun environment file
      cat > /opt/downloads/.env << EOF
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=openvpn
OPENVPN_USER=$VPN_USERNAME
OPENVPN_PASSWORD=$VPN_PASSWORD
SERVER_COUNTRIES=Netherlands
HEALTH_VPN_DURATION_INITIAL=30s
EOF

      # Set proper permissions
      chmod 600 /opt/downloads/.env
      chown root:root /opt/downloads/.env
    '';
  };

  # Systemd service to configure *arr URL bases for reverse proxy
  # Temporarily disabled while debugging container issues
  # systemd.services.arr-urlbase-setup = {
  #   description = "Configure *arr applications URL base for reverse proxy";
  #   after = [ "podman-sonarr.service" "podman-radarr.service" "podman-lidarr.service" "podman-prowlarr.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     User = "root";
  #     Restart = "no";
  #   };
  #   script = ''
  #     # Wait for containers to start and create config files
  #     echo "Waiting for *arr containers to initialize..."
  #     sleep 30
  #
  #     # Function to check if container is running
  #     container_running() {
  #       local container="$1"
  #       ${pkgs.podman}/bin/podman ps --format "table {{.Names}}" | grep -q "^$container$"
  #     }
  #
  #     # Function to update URL base in config.xml
  #     update_urlbase() {
  #       local app="$1"
  #       local urlbase="/$1"
  #       local config_file="/opt/downloads/$app/config.xml"
  #
  #       if [ -f "$config_file" ]; then
  #         echo "Updating $app URL base to $urlbase"
  #         # Use sed to replace empty UrlBase with the correct path
  #         ${pkgs.gnused}/bin/sed -i "s|<UrlBase></UrlBase>|<UrlBase>$urlbase</UrlBase>|g" "$config_file"
  #         echo "Updated $app config"
  #       else
  #         echo "Warning: $config_file not found"
  #       fi
  #     }
  #
  #     # Function to safely restart container
  #     safe_restart_container() {
  #       local service="$1"
  #       echo "Attempting to restart $service..."
  #       if ${pkgs.systemd}/bin/systemctl is-active --quiet "$service"; then
  #         if ${pkgs.systemd}/bin/systemctl restart "$service"; then
  #           echo "Successfully restarted $service"
  #         else
  #           echo "Warning: Failed to restart $service, but continuing..."
  #         fi
  #       else
  #         echo "Warning: $service is not active, skipping restart"
  #       fi
  #     }
  #
  #     # Update each *arr application
  #     update_urlbase "sonarr"
  #     update_urlbase "radarr"
  #     update_urlbase "lidarr"
  #     update_urlbase "prowlarr"
  #
  #     # Restart containers to apply config changes (with error handling)
  #     echo "Restarting *arr containers to apply URL base changes..."
  #     safe_restart_container "podman-sonarr.service"
  #     safe_restart_container "podman-radarr.service"
  #     safe_restart_container "podman-lidarr.service"
  #     safe_restart_container "podman-prowlarr.service"
  #
  #     echo "*arr URL base configuration complete"
  #   '';
  # };

  ####################################################################
  # 1. CONTAINER ORCHESTRATION WITH GPU SUPPORT
  ####################################################################
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {

      # VPN Gateway (removed dependsOn to fix startup)
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
        extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ [
          "--memory=1g"
          "--cpus=0.5"
        ];
        environment = mediaServiceEnv // nvidiaEnv;
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
          SLSKD_USERNAME = "eriqueok";
          SLSKD_PASSWORD = "il0wwlm?";
          SLSKD_SLSK_USERNAME = "eriqueok";
          SLSKD_SLSK_PASSWORD = "il0wwlm?";
        };
        ports = [ "5030:5030" ];
        cmd = [ "--config" "/config/slskd.yml" ];
        volumes = [
          (configVol "slskd")
          "/mnt/hot/downloads:/downloads"
          "/mnt/media/music:/data/music:ro"
          "/mnt/media/music-soulseek:/data/music-soulseek:ro"
          "/mnt/media/music:/data/downloads"
        ];
      };

      soularr = {
        image = "mrusse08/soularr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions ++ [
          "--memory=1g"
          "--cpus=0.5"
        ];
        ports = [ "9898:8989" ];
        environment = mediaServiceEnv // {
          SCRIPT_INTERVAL = "300";
        };
        volumes = [
          (configVol "soularr")
          "/mnt/hot/downloads:/downloads"
        ];
        dependsOn = [ "slskd" "lidarr" ];
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
    };
  };

  ####################################################################
  # 2. STORAGE AUTOMATION AND CLEANUP
  ####################################################################

  # Automated cleanup service
  systemd.services.media-cleanup = {
    description = "Clean up old downloads and temporary files";
    startAt = "daily";
    script = ''
      echo "Starting media cleanup..."

      # Clean old downloads (>30 days)
      ${pkgs.findutils}/bin/find /mnt/hot/downloads -type f -mtime +30 -delete 2>/dev/null || true

      # Clean quarantine (>7 days)
      ${pkgs.findutils}/bin/find /mnt/hot/quarantine -type f -mtime +7 -delete 2>/dev/null || true

      # Clean processing temp files (>1 day)
      ${pkgs.findutils}/bin/find /mnt/hot/processing -type f -mtime +1 -delete 2>/dev/null || true

      # Clean empty directories
      ${pkgs.findutils}/bin/find /mnt/hot/downloads -type d -empty -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find /mnt/hot/quarantine -type d -empty -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find /mnt/hot/processing -type d -empty -delete 2>/dev/null || true

      # Alert if hot storage >80% full
      USAGE=$(${pkgs.coreutils}/bin/df /mnt/hot | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $5}' | ${pkgs.gnused}/bin/sed 's/%//')
      if [ "$USAGE" -gt 80 ]; then
        echo "WARNING: Hot storage is ''${USAGE}% full" | ${pkgs.util-linux}/bin/logger -t media-cleanup
      fi

      echo "Media cleanup completed"
    '';
  };

  # Automated media migration from hot to cold storage
  systemd.services.media-migration = {
    description = "Migrate completed media from hot to cold storage";
    startAt = "hourly";
    script = ''
      echo "Starting media migration..."

      # Function to safely move files
      safe_move() {
        local src="$1"
        local dest="$2"

        if [ -d "$src" ] && [ "$(${pkgs.coreutils}/bin/ls -A "$src" 2>/dev/null)" ]; then
          echo "Migrating from $src to $dest"
          ${pkgs.coreutils}/bin/mkdir -p "$dest"
          ${pkgs.rsync}/bin/rsync -av --remove-source-files "$src/" "$dest/"
          # Remove empty source directories
          ${pkgs.findutils}/bin/find "$src" -type d -empty -delete 2>/dev/null || true
        fi
      }

      # Move completed downloads to cold storage
      safe_move "/mnt/hot/downloads/tv/complete" "/mnt/media/tv"
      safe_move "/mnt/hot/downloads/movies/complete" "/mnt/media/movies"
      safe_move "/mnt/hot/downloads/music/complete" "/mnt/media/music"

      # Move processed files
      safe_move "/mnt/hot/processing/sonarr-temp/complete" "/mnt/media/tv"
      safe_move "/mnt/hot/processing/radarr-temp/complete" "/mnt/media/movies"
      safe_move "/mnt/hot/processing/lidarr-temp/complete" "/mnt/media/music"

      echo "Media migration completed"
    '';
  };

  # Storage monitoring service
  systemd.services.storage-monitor = {
    description = "Monitor storage usage and performance";
    startAt = "*:*:0/30";  # Every 30 seconds
    script = ''
      # Collect storage metrics for Prometheus
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/node_exporter/textfile_collector

      # Hot storage metrics
      HOT_USAGE=$(${pkgs.coreutils}/bin/df /mnt/hot | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $5}' | ${pkgs.gnused}/bin/sed 's/%//')
      HOT_FREE=$(${pkgs.coreutils}/bin/df /mnt/hot | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $4}')
      HOT_TOTAL=$(${pkgs.coreutils}/bin/df /mnt/hot | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $2}')

      # Cold storage metrics
      COLD_USAGE=$(${pkgs.coreutils}/bin/df /mnt/media | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $5}' | ${pkgs.gnused}/bin/sed 's/%//')
      COLD_FREE=$(${pkgs.coreutils}/bin/df /mnt/media | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $4}')
      COLD_TOTAL=$(${pkgs.coreutils}/bin/df /mnt/media | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $2}')

      # Download queue metrics
      DOWNLOAD_COUNT=$(${pkgs.findutils}/bin/find /mnt/hot/downloads -name "*.part" -o -name "*.!qB" | ${pkgs.coreutils}/bin/wc -l)
      PROCESSING_COUNT=$(${pkgs.findutils}/bin/find /mnt/hot/processing -type f | ${pkgs.coreutils}/bin/wc -l)
      QUARANTINE_COUNT=$(${pkgs.findutils}/bin/find /mnt/hot/quarantine -type f | ${pkgs.coreutils}/bin/wc -l)

      # Write metrics
      ${pkgs.coreutils}/bin/cat > /var/lib/node_exporter/textfile_collector/media_storage.prom << EOF
# HELP media_storage_usage_percentage Storage usage percentage
# TYPE media_storage_usage_percentage gauge
media_storage_usage_percentage{tier="hot"} $HOT_USAGE
media_storage_usage_percentage{tier="cold"} $COLD_USAGE

# HELP media_storage_free_bytes Storage free space in bytes
# TYPE media_storage_free_bytes gauge
media_storage_free_bytes{tier="hot"} $(($HOT_FREE * 1024))
media_storage_free_bytes{tier="cold"} $(($COLD_FREE * 1024))

# HELP media_queue_files_total Number of files in various queues
# TYPE media_queue_files_total gauge
media_queue_files_total{queue="download"} $DOWNLOAD_COUNT
media_queue_files_total{queue="processing"} $PROCESSING_COUNT
media_queue_files_total{queue="quarantine"} $QUARANTINE_COUNT
EOF
    '';
  };

  ####################################################################
  # 3. APPLICATION HEALTH MONITORING
  ####################################################################

  # Health check service for *arr applications
  systemd.services.arr-health-monitor = {
    description = "Monitor *arr application health";
    startAt = "*:*:0/60";  # Every minute
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/node_exporter/textfile_collector

      # Function to check service health
      check_service() {
        local service="$1"
        local port="$2"
        local endpoint="$3"

        if ${pkgs.curl}/bin/curl -s -f "http://localhost:$port$endpoint" >/dev/null 2>&1; then
          echo "media_service_up{service=\"$service\"} 1"
        else
          echo "media_service_up{service=\"$service\"} 0"
        fi
      }

      # Check each service
      {
        echo "# HELP media_service_up Service availability (1=up, 0=down)"
        echo "# TYPE media_service_up gauge"
        check_service "sonarr" "8989" "/api/v3/system/status"
        check_service "radarr" "7878" "/api/v3/system/status"
        check_service "lidarr" "8686" "/api/v1/system/status"
        check_service "prowlarr" "9696" "/api/v1/system/status"
        check_service "qbittorrent" "8080" "/api/v2/app/version"
        check_service "navidrome" "4533" "/ping"
      } > /var/lib/node_exporter/textfile_collector/media_services.prom
    '';
  };

  # Network setup is now handled by the common module
}
