# =============================================================================
# Boring-Reliable Media Stack (NixOS + Podman)
# - Caddy reverse proxy on subpaths
# - Servarr apps with UrlBase + Forms auth
# - qBittorrent + SABnzbd egress via Gluetun (VPN)
# - Soularr + slskd
# - Hot (SSD) downloads/processing; cold library on HDD
# =============================================================================
{ config, lib, pkgs, ... }:

let
  # ==== PORTS ================================================================
  ports = {
    sonarr   = 8989;
    radarr   = 7878;
    lidarr   = 8686;
    prowlarr = 9696;

    # Soularr notes:
    # internal port differs by image; default assumed 8989 here.
    soularr_host = 9898;  # host binding
    soularr_ctn  = 8989;  # container listen (adjust if image uses 3000/5055, etc.)

    slskd   = 5030;

    # Gluetun publishes UIs for qBT and SAB to host:
    qbittorrent = 8080;
    sabnzbd     = 8081;   # NOTE: maps to SAB internal 8085
  };

  # ==== NETWORKS =============================================================
  mediaNet = config.hwc.media.networkName;
  mediaNetworkOptions = [ "--network=${mediaNet}" ];
  vpnNetworkOptions   = [ "--network=container:gluetun" ];

  # ==== STORAGE ROOTS ========================================================
  # Configs live under /docker/<name>
  configRoot = "/docker";

  # Hot = SSD (active downloads/processing/cache)
  hotRoot = "/mnt/hot";
  hotDownloads = "${hotRoot}/downloads";
  hotProcessing = "${hotRoot}/processing";
  hotCache = "${hotRoot}/cache";

  # Cold = HDD (final library)
  mediaRoot = "/mnt/media";

  # ==== COMMON ENV ===========================================================
  commonEnv = { PUID = "1000"; PGID = "1000"; TZ = "America/Denver"; };

  # ==== VOLUME HELPERS =======================================================
  configVol = name: "${configRoot}/${name}:/config";

  # *Arr mounts:
  arrVolumes = kind: [
    (configVol kind)
    "${hotDownloads}:/hot-downloads"
    "${hotProcessing}/${kind}:/processing"
    "${hotCache}/${kind}:/cache"
    "${mediaRoot}/tv:/tv"
    "${mediaRoot}/movies:/movies"
    "${mediaRoot}/music:/music"
  ];
in
{
  # =============================================================================
  # ## 1) Secrets (SOPS) – VPN creds for Gluetun
  # =============================================================================
  sops.secrets.vpn_username = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/username"; mode = "0400"; owner = "root";
  };
  sops.secrets.vpn_password = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/password"; mode = "0400"; owner = "root";
  };

  # =============================================================================
  # ## 2) Podman Network + Gluetun Env – must exist before containers
  # =============================================================================

 systemd.services.gluetun-env-setup = {
    description = "Generate Gluetun environment from SOPS secrets";
    before  = [ "podman-gluetun.service" ];
    wants   = [ "sops-install-secrets.service" "hwc-media-network.service" ];
    after   = [ "sops-install-secrets.service" "hwc-media-network.service" ];
    wantedBy = [ "podman-gluetun.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      mkdir -p ${configRoot}
      cat > ${configRoot}/.env <<EOF
  VPN_SERVICE_PROVIDER=protonvpn
  VPN_TYPE=openvpn
  OPENVPN_USER=$(cat ${config.sops.secrets.vpn_username.path})
  OPENVPN_PASSWORD=$(cat ${config.sops.secrets.vpn_password.path})
  SERVER_COUNTRIES=Netherlands
  HEALTH_VPN_DURATION_INITIAL=30s
  EOF
      chmod 600 ${configRoot}/.env
    '';
  };


  # Ensure container units wait for network/env readiness.
  systemd.services."podman-gluetun".after     = [ "hwc-media-network.service" "gluetun-env-setup.service" ];
  systemd.services."podman-sonarr".after      = [ "hwc-media-network.service" ];
  systemd.services."podman-radarr".after      = [ "hwc-media-network.service" ];
  systemd.services."podman-lidarr".after      = [ "hwc-media-network.service" ];
  systemd.services."podman-prowlarr".after    = [ "hwc-media-network.service" ];
  systemd.services."podman-soularr".after     = [ "hwc-media-network.service" ];
  systemd.services."podman-slskd".after       = [ "hwc-media-network.service" ];
  systemd.services."podman-qbittorrent".after = [ "podman-gluetun.service" ];
  systemd.services."podman-sabnzbd".after     = [ "podman-gluetun.service" ];

  # =============================================================================
  # ## 3) Containers (Podman)
  # =============================================================================
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      # --- Gluetun (VPN gateway; publishes qBT/SAB UIs to host) ---------------
      gluetun = {
        image = "qmcgaw/gluetun:latest";
        autoStart = true;
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
          "--network=${mediaNet}"
          "--network-alias=gluetun"
        ];
        environmentFiles = [ "${configRoot}/.env" ];
        ports = [
          "127.0.0.1:${toString ports.qbittorrent}:${toString ports.qbittorrent}"
          "127.0.0.1:${toString ports.sabnzbd}:8085" # host 8081 -> container 8085
        ];
        volumes = [ "${configRoot}/gluetun:/gluetun" ];
      };

      # --- qBittorrent (shares gluetun netns; no host port mapping here) ------
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = vpnNetworkOptions;
        environment = commonEnv // { WEBUI_PORT = toString ports.qbittorrent; };
        volumes = [
          (configVol "qbittorrent")
          "${hotDownloads}/qbittorrent:/downloads"
          "${hotCache}/qbittorrent:/cache"
        ];
      };

      # --- SABnzbd (shares gluetun netns) -------------------------------------
      sabnzbd = {
        image = "lscr.io/linuxserver/sabnzbd:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = vpnNetworkOptions;
        environment = commonEnv;
        volumes = [
          (configVol "sabnzbd")
          "${hotDownloads}/sabnzbd:/downloads"
          "${hotDownloads}/sabnzbd/incomplete:/incomplete-downloads"
        ];
      };

      # --- Sonarr --------------------------------------------------------------
      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:${toString ports.sonarr}:${toString ports.sonarr}" ];
        volumes = arrVolumes "sonarr";
      };

      # --- Radarr --------------------------------------------------------------
      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:${toString ports.radarr}:${toString ports.radarr}" ];
        volumes = arrVolumes "radarr";
      };

      # --- Lidarr --------------------------------------------------------------
      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:${toString ports.lidarr}:${toString ports.lidarr}" ];
        volumes = arrVolumes "lidarr";
      };

      # --- Prowlarr ------------------------------------------------------------
      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:${toString ports.prowlarr}:${toString ports.prowlarr}" ];
        volumes = [
          (configVol "prowlarr")
          "${hotCache}/prowlarr:/cache"
        ];
      };

      # --- slskd ---------------------------------------------------------------
      slskd = {
        image = "slskd/slskd:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv // {
          SLSKD_USERNAME = "admin";
          SLSKD_PASSWORD = "slskd_admin_2024";
        };
        ports = [ "127.0.0.1:${toString ports.slskd}:${toString ports.slskd}" ];
        volumes = [
          (configVol "slskd")
          "${hotDownloads}/slskd:/downloads"
          "${mediaRoot}/music:/music:ro"
        ];
      };

      # --- Soularr -------------------------------------------------------------
       soularr = {
        image = "ghcr.io/theultimatecoders/soularr:latest";
        autoStart = false;  # park until we confirm internal port + image pull
        dependsOn = [ "slskd" "lidarr" ];
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [
          "127.0.0.1:${toString ports.soularr_host}:${toString ports.soularr_ctn}"
        ];
        volumes = [
          (configVol "soularr")
          "${hotDownloads}/slskd:/downloads"
          "${mediaRoot}/music:/music"
        ];
      };
    };
  };

  # =============================================================================
  # ## 4) Caddy – single vhost, subpath proxy, proper headers
  # =============================================================================

  # =============================================================================
  # ## 5) Directories & Firewall
  # =============================================================================
  systemd.tmpfiles.rules = [
    # Config roots
    "d ${configRoot} 0755 root root -"
    "d ${configRoot}/gluetun 0755 1000 1000 -"
    "d ${configRoot}/sonarr 0755 1000 1000 -"
    "d ${configRoot}/radarr 0755 1000 1000 -"
    "d ${configRoot}/lidarr 0755 1000 1000 -"
    "d ${configRoot}/prowlarr 0755 1000 1000 -"
    "d ${configRoot}/soularr 0755 1000 1000 -"
    "d ${configRoot}/slskd 0755 1000 1000 -"
    "d ${configRoot}/qbittorrent 0755 1000 1000 -"
    "d ${configRoot}/sabnzbd 0755 1000 1000 -"

    # Hot storage
    "d ${hotRoot} 0755 1000 1000 -"
    "d ${hotDownloads} 0755 1000 1000 -"
    "d ${hotDownloads}/qbittorrent 0755 1000 1000 -"
    "d ${hotDownloads}/qbittorrent/incomplete 0755 1000 1000 -"
    "d ${hotDownloads}/qbittorrent/complete 0755 1000 1000 -"
    "d ${hotDownloads}/sabnzbd 0755 1000 1000 -"
    "d ${hotDownloads}/sabnzbd/incomplete 0755 1000 1000 -"
    "d ${hotDownloads}/sabnzbd/complete 0755 1000 1000 -"
    "d ${hotDownloads}/slskd 0755 1000 1000 -"
    "d ${hotProcessing} 0755 1000 1000 -"
    "d ${hotProcessing}/sonarr 0755 1000 1000 -"
    "d ${hotProcessing}/radarr 0755 1000 1000 -"
    "d ${hotProcessing}/lidarr 0755 1000 1000 -"
    "d ${hotCache} 0755 1000 1000 -"
    "d ${hotCache}/sonarr 0755 1000 1000 -"
    "d ${hotCache}/radarr 0755 1000 1000 -"
    "d ${hotCache}/lidarr 0755 1000 1000 -"
    "d ${hotCache}/qbittorrent 0755 1000 1000 -"
    "d ${hotCache}/prowlarr 0755 1000 1000 -"

    # Cold library
    "d ${mediaRoot} 0755 1000 1000 -"
    "d ${mediaRoot}/tv 0755 1000 1000 -"
    "d ${mediaRoot}/movies 0755 1000 1000 -"
    "d ${mediaRoot}/music 0755 1000 1000 -"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
