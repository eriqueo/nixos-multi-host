# hosts/server/modules/media-containers.nix (merged)
{ config, lib, pkgs, ... }:

let
  # Paths: keep current /opt/downloads/* layout to avoid breaking existing configs
  cfgRoot   = "/opt/downloads";
  hotRoot   = "/mnt/hot";
  mediaRoot = "/mnt/media";

  # Helper for per-service config volumes
  configVol = service: "${cfgRoot}/${service}:/config";

  # Standard env
  mediaServiceEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ   = config.time.timeZone or "America/Denver";
  };

  # Networking
  mediaNetworkName   = "media-network";
  mediaNetworkOptions = [ "--network=${mediaNetworkName}" ];
  vpnNetworkOptions   = [ "--network=container:gluetun" ];

  # GPU passthrough (kept as-is)
  nvidiaGpuOptions = [
    "--device=/dev/nvidia0:/dev/nvidia0:rwm"
    "--device=/dev/nvidiactl:/dev/nvidiactl:rwm"
    "--device=/dev/nvidia-modeset:/dev/nvidia-modeset:rwm"
    "--device=/dev/nvidia-uvm:/dev/nvidia-uvm:rwm"
    "--device=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools:rwm"
    "--device=/dev/dri:/dev/dri:rwm"
  ];
  intelGpuOptions = [ "--device=/dev/dri:/dev/dri" ];

  nvidiaEnv = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
  };


  # Volume helpers
  hotCache          = service: "${hotRoot}/cache/${service}:/cache";

  # Download paths for container volume mounts
  torrentDownloads  = "${hotRoot}/downloads:/downloads";
  usenetDownloads   = "${hotRoot}/downloads:/downloads";


  # Builders
  buildMediaServiceContainer = { name, image, mediaType, extraVolumes ? [], extraOptions ? [], environment ? {} }: {
    inherit image;
    autoStart = true;
    extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ extraOptions ++ [
      "--memory=2g" "--cpus=1.0" "--memory-swap=4g"
    ];
    environment = mediaServiceEnv // nvidiaEnv // environment;
    ports = {
      "sonarr"  = [ "127.0.0.1:8989:8989" ];
      "radarr"  = [ "127.0.0.1:7878:7878" ];
      "lidarr"  = [ "127.0.0.1:8686:8686" ];
    }.${name} or [];
    volumes = [
      (configVol name)
      "${mediaRoot}/${mediaType}:/${mediaType}"
      "${hotRoot}/downloads:/hot-downloads"
      "${hotRoot}/manual/${mediaType}:/manual"
      "${hotRoot}/quarantine/${mediaType}:/quarantine"
      "${hotRoot}/processing/${name}-temp:/processing"
    ] ++ extraVolumes;
  };

  buildDownloadContainer = { name, image, downloadPath, network ? "vpn", extraVolumes ? [], extraOptions ? [], environment ? {} }: {
    inherit image;
    autoStart = true;
    dependsOn = if network == "vpn" then [ "gluetun" ] else [];
    extraOptions = (if network == "vpn" then vpnNetworkOptions else mediaNetworkOptions) ++ nvidiaGpuOptions ++ extraOptions ++ [
      "--memory=2g" "--cpus=1.0" "--memory-swap=4g"
    ];
    environment = mediaServiceEnv // nvidiaEnv // environment;
    ports = {
      # only gluetun exposes these, so downloaders don't bind ports directly
      "qbittorrent" = [ ];
      "sabnzbd"     = [ ];
    }.${name} or [];
    volumes = [ (configVol name) downloadPath ] ++ extraVolumes;
  };
in
{
  ####################################################################
  # 0. Secrets
  ####################################################################
  sops.secrets.vpn_username = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/username";
    mode = "0400"; owner = "root"; group = "root";
  };
  sops.secrets.vpn_password = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/password";
    mode = "0400"; owner = "root"; group = "root";
  };
  sops.secrets.arr_api_keys_env = {
    sopsFile = ../../../secrets/arr_api_keys.env;
    format = "dotenv";
    mode = "0400"; owner = "root"; group = "root";
  };



  ####################################################################
  # 1. Media network + unit ordering
  ####################################################################
  systemd.services.init-media-network = {
    description = "Create media-network";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = let podman = "${pkgs.podman}/bin/podman"; in ''
      if ! ${podman} network ls --format "{{.Name}}" | grep -qx ${mediaNetworkName}; then
        ${podman} network create ${mediaNetworkName}
      else
        echo "${mediaNetworkName} exists"
      fi
    '';
  };

  # Ensure containers start after network/gluetun as needed
  systemd.services."podman-gluetun".after  = [ "network-online.target" "init-media-network.service" ];
  systemd.services."podman-gluetun".wants  = [ "network-online.target" ];
  systemd.services."podman-sonarr".after   = [ "init-media-network.service" ];
  systemd.services."podman-radarr".after   = [ "init-media-network.service" ];
  systemd.services."podman-lidarr".after   = [ "init-media-network.service" ];
  systemd.services."podman-prowlarr".after = [ "init-media-network.service" ];
# OLD slskd dependencies (COMMENTED OUT)
  # systemd.services."podman-slskd" = {
  #   after = [ "init-media-network.service" "slskd-config-seeder.service" ];
  #   wants = [ "slskd-config-seeder.service" ];
  # };
  systemd.services."podman-soularr" = {
    after = [ "init-media-network.service" "podman-lidarr.service" "podman-slskd.service" ];
    requires = [ "podman-lidarr.service" ];
    serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-for-lidarr" ''
      for i in 1 1 2 3 5 8; do
        if ${pkgs.curl}/bin/curl -sf -H "X-Api-Key: e70370fd157849b09ceb7e159b11eb4e" \
          "http://localhost:8686/lidarr/api/v1/system/status" >/dev/null 2>&1; then
          echo "Lidarr is ready"
          exit 0
        fi
        echo "Waiting for Lidarr... ($i)"
        sleep $i
      done
      echo "Lidarr failed to become ready"
      exit 1
    '';
  };
  systemd.services."podman-qbittorrent".after = [ "podman-gluetun.service" ];
  systemd.services."podman-sabnzbd".after     = [ "podman-gluetun.service" ];

  # Build gluetun env file from SOPS before gluetun starts
  systemd.services.gluetun-env-setup = {
    description = "Generate Gluetun env from SOPS";
    before   = [ "podman-gluetun.service" ];
    wantedBy = [ "podman-gluetun.service" ];
    wants    = [ "sops-install-secrets.service" ];
    after    = [ "sops-install-secrets.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p ${cfgRoot}
      VPN_USERNAME=$(cat ${config.sops.secrets.vpn_username.path})
      VPN_PASSWORD=$(cat ${config.sops.secrets.vpn_password.path})
      cat > ${cfgRoot}/.env <<EOF
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=openvpn
OPENVPN_USER=$VPN_USERNAME
OPENVPN_PASSWORD=$VPN_PASSWORD
SERVER_COUNTRIES=Netherlands
HEALTH_VPN_DURATION_INITIAL=30s
EOF
      chmod 600 ${cfgRoot}/.env
      chown root:root ${cfgRoot}/.env
    '';
  };

  ####################################################################
  # 2. Containers (Podman)
  ####################################################################
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      # VPN base (exposes downloaders’ UIs on localhost only)
      gluetun = {
        image = "qmcgaw/gluetun:latest";
        autoStart = true;
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
          "--network=${mediaNetworkName}"
          "--network-alias=gluetun"
        ];
        ports = [
          "127.0.0.1:8080:8080"  # qBittorrent UI
          "127.0.0.1:8081:8085"  # SABnzbd (container uses 8085 internally)
        ];
        volumes = [ "${cfgRoot}/gluetun:/gluetun" ];
        environmentFiles = [ "${cfgRoot}/.env" ];
        environment = { TZ = config.time.timeZone or "America/Denver"; };
      };

      # Download clients (share gluetun’s netns)
      qbittorrent = buildDownloadContainer {
        name = "qbittorrent";
        image = "lscr.io/linuxserver/qbittorrent";
        downloadPath = torrentDownloads;
        network = "vpn";
        extraVolumes = [ (hotCache "qbittorrent") "${mediaRoot}:/cold-media" ];
        environment = { WEBUI_PORT = "8080"; };
      };

      sabnzbd = buildDownloadContainer {
        name = "sabnzbd";
        image = "lscr.io/linuxserver/sabnzbd:latest";
        downloadPath = usenetDownloads;
        network = "vpn";
        extraVolumes = [
          "${hotRoot}/cache:/incomplete-downloads"
          "/opt/downloads/scripts:/config/scripts:ro"
        ];
      };

      # *arr apps
      lidarr = buildMediaServiceContainer {
        name = "lidarr"; image = "lscr.io/linuxserver/lidarr:latest"; mediaType = "music";
      };
      sonarr = buildMediaServiceContainer {
        name = "sonarr"; image = "lscr.io/linuxserver/sonarr:latest"; mediaType = "tv";
      };
      radarr = buildMediaServiceContainer {
        name = "radarr"; image = "lscr.io/linuxserver/radarr:latest"; mediaType = "movies";
      };
      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ [ "--memory=1g" "--cpus=0.5" ];
        environment = mediaServiceEnv // nvidiaEnv;
        ports = [ "127.0.0.1:9696:9696" ];
        volumes = [ (configVol "prowlarr") ];
      };



      # Soularr (no web UI; /data contains config.ini)
      soularr = {
        image = "docker.io/mrusse08/soularr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions ++ [ "--memory=1g" "--cpus=0.5" ];
        volumes = [
          (configVol "soularr")
          "${cfgRoot}/soularr:/data"
          "${hotRoot}/downloads:/downloads"
          "${cfgRoot}/soularr/app:/app"
        ];
        dependsOn = [ "lidarr" ];
      };

      # Navidrome - Enable reverse proxy support for Caddy subpath
      navidrome = {
        image = "deluan/navidrome";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = {
          ND_MUSICFOLDER   = "/music";
          ND_DATAFOLDER    = "/data";
          ND_LOGLEVEL      = "info";
          ND_SESSIONTIMEOUT= "24h";
          # No ND_BASEURL - run at root for direct access
          ND_INITIAL_ADMIN_USER = "admin";
          ND_INITIAL_ADMIN_PASSWORD = "il0wwlm?";
        };
        ports = [ "0.0.0.0:4533:4533" ];
        volumes = [ (configVol "navidrome") "${mediaRoot}/music:/music:ro" ];
      };
    };
  };

  ####################################################################
  # 3. Config seeders & helpers
  ####################################################################





  # Seed Soularr /data/config.ini from SOPS env
  systemd.services.soularr-config = {
    description = "Seed Soularr /data/config.ini from SOPS env";
    wantedBy = [ "podman-soularr.service" ];
    before   = [ "podman-soularr.service" ];
    after    = [ "sops-install-secrets.service" ];
    wants    = [ "sops-install-secrets.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      echo "--- Running soularr-config seeder (Final Version) ---"

      SECRETS_FILE="${config.sops.secrets.arr_api_keys_env.path}"
      CONFIG_FILE="${cfgRoot}/soularr/config.ini"

      # Forcefully remove the old config file to ensure changes are applied
      echo "Removing old config file at $CONFIG_FILE..."
      rm -f "$CONFIG_FILE"

      # Robustly get keys from the secrets file
      LIDARR_API_KEY=$(grep '^LIDARR_API_KEY=' "$SECRETS_FILE" | cut -d'=' -f2)
      SLSKD_API_KEY=$(grep '^SLSKD_API_KEY=' "$SECRETS_FILE" | cut -d'=' -f2)

      echo "DEBUG: LIDARR Key found: $([ -n "$LIDARR_API_KEY" ] && echo 'yes' || echo 'no')"
      echo "DEBUG: SLSKD Key found:  $([ -n "$SLSKD_API_KEY" ] && echo 'yes' || echo 'no')"

      mkdir -p "${cfgRoot}/soularr"
      echo "Writing new config file to $CONFIG_FILE..."
      # This version provides download_dir under [Lidarr] as the error demands
      cat > "$CONFIG_FILE" <<EOF
[Lidarr]
host_url = http://lidarr:8686/lidarr
api_key  = "$LIDARR_API_KEY"
download_dir = /downloads/music/complete

[Slskd]
host_url = http://slskd:5030
api_key  = "$SLSKD_API_KEY"
download_dir = /downloads/music/complete

[General]
interval = 300
EOF
      chmod 600 "$CONFIG_FILE"
      echo "Config file written successfully."
      echo "--- soularr-config seeder finished ---"
    '';
  };





  ####################################################################
  # CADDY REVERSE PROXY CONFIGURATION
  ####################################################################
  # Caddy reverse proxy for all services
  services.caddy = {
    enable = true;
    virtualHosts = {
      "hwc.ocelot-wahoo.ts.net".extraConfig = ''
      # Obsidian LiveSync proxy: strip /sync prefix and forward to CouchDB
      @sync path /sync*
      handle @sync {
        uri strip_prefix /sync
        reverse_proxy 127.0.0.1:5984 {
          # preserve the Host header for CouchDB auth
          header_up Host {host}
          # rewrite any CouchDB redirect back under /sync
          header_down Location ^/(.*)$ /sync/{1}
        }
      }

      # Download clients (VPN-routed)
      handle_path /qbt/* {
        reverse_proxy localhost:8080
      }
      handle_path /sab/* {
        reverse_proxy localhost:8081
      }

      # Media services
      handle_path /media/* {
        reverse_proxy localhost:8096
      }

      # Immich - Direct port exposure (no subpath proxy due to SvelteKit issues)
      # HTTPS access: https://hwc.ocelot-wahoo.ts.net:2283 (Tailscale HTTPS)
      # Local access: http://192.168.1.13:2283 (direct)
      # Both use same database/credentials

      # Navidrome - strip /navidrome prefix for direct backend access
      handle_path /navidrome/* {
        reverse_proxy 127.0.0.1:4533
      }

      # *ARR stack - Keep UrlBase in apps, DO NOT strip prefix in Caddy
      # Apps have UrlBase=/app, Caddy passes paths as-is - no conflict

      # ---- Sonarr
      handle /sonarr { redir /sonarr/ 301 }
      route /sonarr* {
        reverse_proxy localhost:8989 {
          header_up Host {host}
          header_up X-Forwarded-Host {host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Port {server_port}
          header_up X-Forwarded-For {remote}
          header_up X-Real-IP {remote}
        }
      }

      # ---- Radarr
      handle /radarr { redir /radarr/ 301 }
      route /radarr* {
        reverse_proxy localhost:7878 {
          header_up Host {host}
          header_up X-Forwarded-Host {host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Port {server_port}
          header_up X-Forwarded-For {remote}
          header_up X-Real-IP {remote}
        }
      }

      # ---- Lidarr
      handle /lidarr { redir /lidarr/ 301 }
      route /lidarr* {
        reverse_proxy localhost:8686 {
          header_up Host {host}
          header_up X-Forwarded-Host {host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Port {server_port}
          header_up X-Forwarded-For {remote}
          header_up X-Real-IP {remote}
        }
      }

      # ---- Prowlarr
      handle /prowlarr { redir /prowlarr/ 301 }
      route /prowlarr* {
        reverse_proxy localhost:9696 {
          header_up Host {host}
          header_up X-Forwarded-Host {host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Port {server_port}
          header_up X-Forwarded-For {remote}
          header_up X-Real-IP {remote}
        }
      }

      # slskd (Soulseek daemon) - preserve /slskd prefix for application-level base path
      handle /slskd/* {
        reverse_proxy 127.0.0.1:5031
      }

      # Business services
      handle /business* {
        reverse_proxy localhost:8000
      }
      handle /dashboard* {
        reverse_proxy localhost:8501
      }

      # Private notification service - strip /notify prefix for mobile app compatibility
      handle_path /notify/* {
        reverse_proxy localhost:8282
      }

      # Monitoring services
      handle_path /grafana/* {
        reverse_proxy localhost:3000
      }
      handle_path /prometheus/* {
        reverse_proxy localhost:9090
      }
    '';

    };
  };

  # Firewall: only expose HTTP/S publicly, other services only on Tailscale
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5984 8000 8501 8282 2283 ]; # slskd via Caddy proxy only
  };

  # Fix config file permissions for container access
  systemd.services.arr-config-permissions = {
    description = "Fix *arr config file permissions for container access";
    after = [ "network-online.target" ];
    before = [ "podman-sonarr.service" "podman-radarr.service" "podman-lidarr.service" "podman-prowlarr.service" "podman-sabnzbd.service" "podman-qbittorrent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Fix ownership for all *arr config directories and files
      for app in sonarr radarr lidarr prowlarr sabnzbd qbittorrent gluetun; do
        if [ -d "${cfgRoot}/$app" ]; then
          chown -R 1000:1000 "${cfgRoot}/$app"
          echo "Fixed permissions for $app config"
        fi
      done

      # Fix permissions for media storage directories
      echo "Setting up media directory permissions..."

      # Create missing directories if they don't exist
      mkdir -p "${hotRoot}/downloads" "${hotRoot}/cache" "${hotRoot}/processing" "${hotRoot}/quarantine"
      mkdir -p "${hotRoot}/processing/lidarr-temp" "${hotRoot}/quarantine/music"
      mkdir -p "${mediaRoot}/music" "${mediaRoot}/movies" "${mediaRoot}/tv"

      # Set proper ownership and permissions for hot storage
      chown -R 1000:1000 "${hotRoot}/downloads" "${hotRoot}/cache" "${hotRoot}/processing" "${hotRoot}/quarantine"
      chmod -R 775 "${hotRoot}/downloads" "${hotRoot}/cache" "${hotRoot}/processing" "${hotRoot}/quarantine"

      # Set proper ownership and permissions for media storage
      chown -R 1000:1000 "${mediaRoot}/music" "${mediaRoot}/movies" "${mediaRoot}/tv"
      chmod -R 775 "${mediaRoot}/music" "${mediaRoot}/movies" "${mediaRoot}/tv"

      echo "Media directory permissions fixed successfully"
    '';
  };

  # After you set creds, you can run this to enforce auth
  systemd.services.arr-auth-enforce = {
    description = "Enforce AuthenticationRequired=Enabled for all *arr";
    after = [ "podman-sonarr.service" "podman-radarr.service" "podman-lidarr.service" "podman-prowlarr.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      enforce() {
        f="${cfgRoot}/$1/config.xml"; [ -f "$f" ] || return 0
        ${pkgs.gnused}/bin/sed -E \
          -e "s|<AuthenticationRequired>.*</AuthenticationRequired>|<AuthenticationRequired>Enabled</AuthenticationRequired>|g" -i "$f"
        echo "Enforced auth in $f"
      }
      for a in sonarr radarr lidarr prowlarr; do enforce "$a"; done
    '';
  };

  ####################################################################
  # 4. Storage automation & monitoring
  ####################################################################
  systemd.services.media-cleanup = {
    description = "Clean up old downloads and temporary files";
    startAt = "daily";
    script = ''
      ROOT_DL="${hotRoot}/downloads"
      ROOT_Q="${hotRoot}/quarantine"
      ROOT_P="${hotRoot}/processing"

      # Remove only temp/partial files
      ${pkgs.findutils}/bin/find "$ROOT_DL" -type f \( -name "*.part" -o -name "*.!qB" -o -name ".___padding_file_*" \) -mtime +7 -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find "$ROOT_Q" -type f -mtime +14 -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find "$ROOT_P" -type f -mtime +3 -delete 2>/dev/null || true

      # Remove only empty subdirectories, never roots
      ${pkgs.findutils}/bin/find "$ROOT_DL" -mindepth 2 -type d -empty -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find "$ROOT_Q"  -mindepth 2 -type d -empty -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find "$ROOT_P"  -mindepth 2 -type d -empty -delete 2>/dev/null || true

      USAGE=$(${pkgs.coreutils}/bin/df ${hotRoot} | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '''{print $5}''' | ${pkgs.gnused}/bin/sed '''s/%//''')
      if [ "$USAGE" -gt 80 ]; then
        echo "WARNING: Hot storage is $USAGE% full" | ${pkgs.util-linux}/bin/logger -t media-cleanup
      fi
    '';
  };

  systemd.services.media-migration = {
    description = "Migrate completed media from hot to cold storage";
    startAt = "hourly";
    script = ''
      safe_move() {
        local src="$1"; local dest="$2"
        if [ -d "$src" ] && [ "$(${pkgs.coreutils}/bin/ls -A "$src" 2>/dev/null)" ]; then
          ${pkgs.coreutils}/bin/mkdir -p "$dest"
          ${pkgs.rsync}/bin/rsync -av --remove-source-files "$src/" "$dest/"
          ${pkgs.findutils}/bin/find "$src" -type d -empty -delete 2>/dev/null || true
        fi
      }
      safe_move "${hotRoot}/downloads/tv/complete"     "${mediaRoot}/tv"
      safe_move "${hotRoot}/downloads/movies/complete" "${mediaRoot}/movies"
      safe_move "${hotRoot}/downloads/music/complete"  "${mediaRoot}/music"
      safe_move "${hotRoot}/processing/sonarr-temp/complete"  "${mediaRoot}/tv"
      safe_move "${hotRoot}/processing/radarr-temp/complete"  "${mediaRoot}/movies"
      safe_move "${hotRoot}/processing/lidarr-temp/complete"  "${mediaRoot}/music"
    '';
  };

  systemd.services.storage-monitor = {
    description = "Prometheus textfile metrics for storage and queues";
    startAt = "*:*:0/30";
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/node_exporter/textfile_collector
      HOT_USAGE=$(${pkgs.coreutils}/bin/df ${hotRoot}   | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $5}' | ${pkgs.gnused}/bin/sed 's/%//')
      HOT_FREE=$(${pkgs.coreutils}/bin/df ${hotRoot}    | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $4}')
      COLD_USAGE=$(${pkgs.coreutils}/bin/df ${mediaRoot}| ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $5}' | ${pkgs.gnused}/bin/sed 's/%//')
      COLD_FREE=$(${pkgs.coreutils}/bin/df ${mediaRoot} | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $4}')
      DOWNLOAD_COUNT=$(${pkgs.findutils}/bin/find ${hotRoot}/downloads -name "*.part" -o -name "*.!qB" | ${pkgs.coreutils}/bin/wc -l)
      PROCESSING_COUNT=$(${pkgs.findutils}/bin/find ${hotRoot}/processing -type f | ${pkgs.coreutils}/bin/wc -l)
      QUARANTINE_COUNT=$(${pkgs.findutils}/bin/find ${hotRoot}/quarantine -type f | ${pkgs.coreutils}/bin/wc -l)
      cat > /var/lib/node_exporter/textfile_collector/media_storage.prom << EOF
# HELP media_storage_usage_percentage Storage usage percentage
# TYPE media_storage_usage_percentage gauge
media_storage_usage_percentage{tier="hot"} $HOT_USAGE
media_storage_usage_percentage{tier="cold"} $COLD_USAGE
# HELP media_storage_free_bytes Storage free space in bytes
# TYPE media_storage_free_bytes gauge
media_storage_free_bytes{tier="hot"} $(($HOT_FREE * 1024))
media_storage_free_bytes{tier="cold"} $(($COLD_FREE * 1024))
# HELP media_queue_files_total Number of files in queues
# TYPE media_queue_files_total gauge
media_queue_files_total{queue="download"} $DOWNLOAD_COUNT
media_queue_files_total{queue="processing"} $PROCESSING_COUNT
media_queue_files_total{queue="quarantine"} $QUARANTINE_COUNT
EOF
    '';
  };

  systemd.services.arr-health-monitor = {
    description = "Monitor *arr application health";
    startAt = "*:*:0/60";
    serviceConfig.EnvironmentFile = "${config.sops.secrets.arr_api_keys_env.path}";
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/node_exporter/textfile_collector
      check() {
        local name="$1" port="$2" ep="$3" key="$4"
        if [ -n "$key" ]; then
          HDR="-H \"X-Api-Key: $key\""
        else
          HDR=""
        fi
        if ${pkgs.curl}/bin/curl -s -f $HDR "http://localhost:$port$ep" >/dev/null 2>&1; then
          echo "media_service_up{service=\"$name\"} 1"
        else
          echo "media_service_up{service=\"$name\"} 0"
        fi
      }
      {
        echo "# HELP media_service_up Service availability (1=up, 0=down)"
        echo "# TYPE media_service_up gauge"
        check "sonarr" "8989" "/api/v3/system/status" "$SONARR_API_KEY"
        check "radarr" "7878" "/api/v3/system/status" "$RADARR_API_KEY"
        check "lidarr" "8686" "/api/v1/system/status" "$LIDARR_API_KEY"
        check "prowlarr" "9696" "/api/v1/system/status" "$PROWLARR_API_KEY"
        check "qbittorrent" "8080" "/api/v2/app/version"
        check "navidrome" "4533" "/ping"
      } > /var/lib/node_exporter/textfile_collector/media_services.prom
    '';
  };

  systemd.services.sabnzbd-hostname-setup = {
    description = "Configure SABnzbd hostname whitelist for reverse proxy access";
    after = [ "podman-sabnzbd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; User = "root"; };
    script = ''
      sleep 30
      f="${cfgRoot}/sabnzbd/sabnzbd.ini"
      if [ -f "$f" ]; then
        if grep -q "^host_whitelist" "$f"; then
          sed -i 's/^host_whitelist.*/host_whitelist = sabnzbd,localhost,127.0.0.1,gluetun,hwc.ocelot-wahoo.ts.net,192.168.1.13/' "$f"
        else
          if grep -q "^\[misc\]" "$f"; then
            sed -i '/^\[misc\]/a host_whitelist = sabnzbd,localhost,127.0.0.1,gluetun,hwc.ocelot-wahoo.ts.net,192.168.1.13' "$f"
          else
            echo -e "\n[misc]\nhost_whitelist = sabnzbd,localhost,127.0.0.1,gluetun,hwc.ocelot-wahoo.ts.net,192.168.1.13" >> "$f"
          fi
        fi
        systemctl restart podman-sabnzbd.service || true
      fi
    '';
  };
}
