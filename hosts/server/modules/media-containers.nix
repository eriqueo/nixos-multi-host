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
  systemd.services."podman-slskd".after    = [ "init-media-network.service" ];
  systemd.services."podman-soularr".after  = [ "init-media-network.service" ];
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
        extraVolumes = [ "${hotRoot}/cache:/incomplete-downloads" ];
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

      # slskd
      slskd = {
        image = "slskd/slskd:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = mediaServiceEnv // {
          SLSKD_USERNAME = "eriqueok";
          SLSKD_PASSWORD = "il0wwlm?";
          SLSKD_SLSK_USERNAME = "eriqueok";
          SLSKD_SLSK_PASSWORD = "il0wwlm?";
        };
        ports = [ "127.0.0.1:5030:5030" ];
        cmd = [ "--config" "/config/slskd.yml" ];
        volumes = [
          (configVol "slskd")
          "${hotRoot}/downloads:/downloads"
          "${mediaRoot}/music:/data/music:ro"
          "${mediaRoot}/music-soulseek:/data/music-soulseek:ro"
          "${mediaRoot}/music:/data/downloads"
        ];
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
        ];
        dependsOn = [ "slskd" "lidarr" ];
      };

      # Navidrome
      navidrome = {
        image = "deluan/navidrome";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = {
          ND_MUSICFOLDER   = "/music";
          ND_DATAFOLDER    = "/data";
          ND_LOGLEVEL      = "info";
          ND_SESSIONTIMEOUT= "24h";
        };
        ports = [ "127.0.0.1:4533:4533" ];
        volumes = [ (configVol "navidrome") "${mediaRoot}/music:/music:ro" ];
      };
    };
  };

  ####################################################################
  # 3. Config seeders & helpers
  ####################################################################
  # Seed Soularr /data/config.ini from SOPS env (dummy keys ok; replace later)
  systemd.services.soularr-config = {
    description = "Seed Soularr /data/config.ini from SOPS env";
    wantedBy = [ "podman-soularr.service" ];
    before   = [ "podman-soularr.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      mkdir -p ${cfgRoot}/soularr
      . ${config.sops.secrets.arr_api_keys_env.path} || true
      cfg=${cfgRoot}/soularr/config.ini
      cat > "$cfg" <<EOF
[Lidarr]
host_url = http://lidarr:8686
api_key  = ''${LIDARR_API_KEY:-dummy-lidarr}
download_dir = /downloads

[Slskd]
host_url = http://slskd:5030
api_key  = ''${SLSKD_API_KEY:-dummy-sls}
download_dir = /downloads

[General]
interval = 300
EOF
      chmod 600 "$cfg"
    '';
  };

  # URL base + local-only bypass so you can log in and set creds via WebUI
  systemd.services.arr-urlbase-local-bypass = {
    description = "Set UrlBase + local-only auth bypass to configure creds";
    after = [ "podman-sonarr.service" "podman-radarr.service" "podman-lidarr.service" "podman-prowlarr.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      edit() {
        f="${cfgRoot}/$1/config.xml"; [ -f "$f" ] || return 0
        tmp="$(mktemp)"
        ${pkgs.gnused}/bin/sed -E \
          -e "s|<UrlBase>.*</UrlBase>|<UrlBase>/$1</UrlBase>|g" \
          -e "s|<AuthenticationRequired>.*</AuthenticationRequired>|<AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>|g" \
          "$f" > "$tmp"
        mv "$tmp" "$f"
        echo "Patched $f"
      }
      for a in sonarr radarr lidarr prowlarr; do edit "$a"; done
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
      ${pkgs.findutils}/bin/find ${hotRoot}/downloads -type f -mtime +30 -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find ${hotRoot}/quarantine -type f -mtime +7 -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find ${hotRoot}/processing -type f -mtime +1 -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find ${hotRoot}/downloads -type d -empty -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find ${hotRoot}/quarantine -type d -empty -delete 2>/dev/null || true
      ${pkgs.findutils}/bin/find ${hotRoot}/processing -type d -empty -delete 2>/dev/null || true
      USAGE=$(${pkgs.coreutils}/bin/df ${hotRoot} | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gawk}/bin/awk '{print $5}' | ${pkgs.gnused}/bin/sed 's/%//')
      if [ "$USAGE" -gt 80 ]; then
        echo "WARNING: Hot storage is ''${USAGE}% full" | ${pkgs.util-linux}/bin/logger -t media-cleanup
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
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/node_exporter/textfile_collector
      check() {
        local name="$1" port="$2" ep="$3"
        if ${pkgs.curl}/bin/curl -s -f "http://localhost:$port$ep" >/dev/null 2>&1; then
          echo "media_service_up{service=\"$name\"} 1"
        else
          echo "media_service_up{service=\"$name\"} 0"
        fi
      }
      {
        echo "# HELP media_service_up Service availability (1=up, 0=down)"
        echo "# TYPE media_service_up gauge"
        check "sonarr" "8989" "/api/v3/system/status"
        check "radarr" "7878" "/api/v3/system/status"
        check "lidarr" "8686" "/api/v1/system/status"
        check "prowlarr" "9696" "/api/v1/system/status"
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
