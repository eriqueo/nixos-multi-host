# hosts/server/modules/media-stack.nix
# Boring-reliable media stack: Caddy + *arr + Soularr + slskd + Gluetun VPN routing
{ config, lib, pkgs, ... }:

let
  # CONFIGURATION: Update these ports if using different container images
  ports = {
    sonarr = 8989;
    radarr = 7878; 
    lidarr = 8686;
    prowlarr = 9696;
    soularr = 8989;  # Soularr mimics sonarr port internally
    slskd = 5030;
    qbittorrent = 8080;  # Via Gluetun proxy
    sabnzbd = 8081;      # Via Gluetun proxy (container uses 8085 internally)
  };

  # NETWORKING: All services except downloaders use media-net bridge
  mediaNetworkOptions = [ "--network=media-network" ];
  vpnNetworkOptions = [ "--network=container:gluetun" ];
  
  # STORAGE: Standardized paths for consistency
  configRoot = "/docker";  # Container configs under /docker/<name>
  mediaRoot = "/mnt/media"; # Final media library storage
  downloadRoot = "${mediaRoot}/downloads"; # Download staging area

  # HELPERS: Standard environment and volume patterns
  commonEnv = {
    PUID = "1000";
    PGID = "1000"; 
    TZ = "America/Denver";
  };

  # Volume helper: config mount for each service  
  configVol = name: "${configRoot}/${name}:/config";
  
  # Volume helper: media library mounts for *arr apps
  mediaVolumes = [
    "${mediaRoot}/tv:/tv"
    "${mediaRoot}/movies:/movies"
    "${mediaRoot}/music:/music"
  ];
in
{
  # SOPS: VPN credentials encrypted with age/gpg
  sops.secrets.vpn_username = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/username";
    mode = "0400";
    owner = "root";
  };
  
  sops.secrets.vpn_password = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "vpn/protonvpn/password";
    mode = "0400";
    owner = "root";
  };

  # Create media-net bridge (idempotent)
  systemd.services.init-media-network = {
    description = "Create media container network bridge";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if \! ${pkgs.podman}/bin/podman network exists media-network; then
        ${pkgs.podman}/bin/podman network create media-network
        echo "Created media-network bridge"
      else
        echo "media-network bridge already exists"  
      fi
    '';
  };

  # Generate Gluetun env file from SOPS secrets
  systemd.services.gluetun-env-setup = {
    description = "Generate Gluetun environment from SOPS secrets";
    before = [ "podman-gluetun.service" ];
    wantedBy = [ "podman-gluetun.service" ];
    wants = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      mkdir -p ${configRoot}
      cat > ${configRoot}/.env << ENVEOF
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=openvpn
OPENVPN_USER=$(cat ${config.sops.secrets.vpn_username.path})
OPENVPN_PASSWORD=$(cat ${config.sops.secrets.vpn_password.path})
SERVER_COUNTRIES=Netherlands
HEALTH_VPN_DURATION_INITIAL=30s
ENVEOF
      chmod 600 ${configRoot}/.env
    '';
  };

  # Container definitions
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
    
      # VPN GATEWAY: All download traffic routes through this
      gluetun = {
        image = "qmcgaw/gluetun:latest";
        autoStart = true;
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun"
          "--network=media-network" 
          "--network-alias=gluetun"
        ];
        environmentFiles = [ "${configRoot}/.env" ];
        ports = [
          "127.0.0.1:8080:8080"
          "127.0.0.1:8081:8085"
        ];
        volumes = [ 
          "${configRoot}/gluetun:/gluetun"
        ];
      };

      # DOWNLOAD CLIENTS: Use Gluetun network namespace
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = vpnNetworkOptions;
        environment = commonEnv // { WEBUI_PORT = "8080"; };
        volumes = [
          (configVol "qbittorrent")
          "${downloadRoot}/qbittorrent:/downloads"
          "${mediaRoot}/tv:/tv"
          "${mediaRoot}/movies:/movies"
          "${mediaRoot}/music:/music"
        ];
      };
      
      sabnzbd = {
        image = "lscr.io/linuxserver/sabnzbd:latest";
        autoStart = true;
        dependsOn = [ "gluetun" ];
        extraOptions = vpnNetworkOptions;
        environment = commonEnv;
        volumes = [
          (configVol "sabnzbd")
          "${downloadRoot}/sabnzbd:/downloads"
          "${downloadRoot}/sabnzbd/incomplete:/incomplete-downloads"
          "${mediaRoot}/tv:/tv"
          "${mediaRoot}/movies:/movies"
          "${mediaRoot}/music:/music"
        ];
      };

      # MEDIA MANAGEMENT: *arr apps on media-network
      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:8989:8989" ];
        volumes = [
          (configVol "sonarr")
          "${downloadRoot}:/downloads"
        ] ++ mediaVolumes;
      };
      
      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:7878:7878" ];
        volumes = [
          (configVol "radarr")
          "${downloadRoot}:/downloads"
        ] ++ mediaVolumes;
      };
      
      lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:8686:8686" ];
        volumes = [
          (configVol "lidarr")
          "${downloadRoot}:/downloads"
        ] ++ mediaVolumes;
      };
      
      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:9696:9696" ];
        volumes = [
          (configVol "prowlarr")
        ];
      };

      # SOULSEEK INTEGRATION
      slskd = {
        image = "slskd/slskd:latest";
        autoStart = true;
        extraOptions = mediaNetworkOptions;
        environment = commonEnv // {
          SLSKD_USERNAME = "admin";
          SLSKD_PASSWORD = "slskd_admin_2024";
        };
        ports = [ "127.0.0.1:5030:5030" ];
        volumes = [
          (configVol "slskd")
          "${downloadRoot}/slskd:/downloads"
          "${mediaRoot}/music:/music:ro"
        ];
      };
      
      soularr = {
        image = "ghcr.io/theultimatecoders/soularr:latest"; 
        autoStart = true;
        dependsOn = [ "slskd" "lidarr" ];
        extraOptions = mediaNetworkOptions;
        environment = commonEnv;
        ports = [ "127.0.0.1:9898:8989" ];
        volumes = [
          (configVol "soularr")
          "${downloadRoot}/slskd:/downloads"
          "${mediaRoot}/music:/music"
        ];
      };
    };
  };

  # Caddy reverse proxy configuration
  services.caddy = {
    enable = true;
    virtualHosts."hwc.ocelot-wahoo.ts.net".extraConfig = ''
      # Obsidian LiveSync proxy
      @sync path /sync*
      handle @sync {
        uri strip_prefix /sync
        reverse_proxy 127.0.0.1:5984 {
          header_up Host {host}
          header_down Location ^/(.*)$ /sync/{1}
        }
      }

      # Media services
      handle_path /media/* {
        reverse_proxy localhost:8096
      }
      handle_path /navidrome/* {
        reverse_proxy localhost:4533
      }

      # *ARR STACK: Media management with Forms auth
      handle /sonarr { redir /sonarr/ 301 }
      handle_path /sonarr/* {
        uri strip_prefix /sonarr
        reverse_proxy 127.0.0.1:8989
      }
      
      handle /radarr { redir /radarr/ 301 }
      handle_path /radarr/* {
        uri strip_prefix /radarr
        reverse_proxy 127.0.0.1:7878
      }
      
      handle /lidarr { redir /lidarr/ 301 }
      handle_path /lidarr/* {
        uri strip_prefix /lidarr  
        reverse_proxy 127.0.0.1:8686
      }
      
      handle /prowlarr { redir /prowlarr/ 301 }
      handle_path /prowlarr/* {
        uri strip_prefix /prowlarr
        reverse_proxy 127.0.0.1:9696
      }
      
      # SOULSEEK INTEGRATION
      handle /soularr { redir /soularr/ 301 }
      handle_path /soularr/* {
        uri strip_prefix /soularr
        reverse_proxy 127.0.0.1:9898
      }
      
      handle /slskd { redir /slskd/ 301 }
      handle_path /slskd/* {
        uri strip_prefix /slskd
        reverse_proxy 127.0.0.1:5030
      }
      
      # DOWNLOAD CLIENTS: VPN-routed via Gluetun
      handle /qbt { redir /qbt/ 301 }
      handle_path /qbt/* {
        uri strip_prefix /qbt
        reverse_proxy 127.0.0.1:8080
      }
      
      handle /sab { redir /sab/ 301 }
      handle_path /sab/* {
        uri strip_prefix /sab
        reverse_proxy 127.0.0.1:8081
      }

      # Business services
      handle /business* {
        reverse_proxy localhost:8000
      }
      handle /dashboard* {
        reverse_proxy localhost:8501
      }

      # Notification service
      handle_path /notify/* {
        reverse_proxy localhost:8282
      }

      # Photo management
      handle_path /immich/* {
        reverse_proxy localhost:2284
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

  # Directory structure
  systemd.tmpfiles.rules = [
    # Container config directories 
    "d /docker 0755 root root -"
    "d /docker/sonarr 0755 1000 1000 -"
    "d /docker/radarr 0755 1000 1000 -" 
    "d /docker/lidarr 0755 1000 1000 -"
    "d /docker/prowlarr 0755 1000 1000 -"
    "d /docker/soularr 0755 1000 1000 -"
    "d /docker/slskd 0755 1000 1000 -"
    "d /docker/qbittorrent 0755 1000 1000 -"
    "d /docker/sabnzbd 0755 1000 1000 -"
    "d /docker/gluetun 0755 1000 1000 -"
    
    # Download staging areas
    "d /mnt/media/downloads 0755 1000 1000 -"
    "d /mnt/media/downloads/qbittorrent 0755 1000 1000 -"
    "d /mnt/media/downloads/sabnzbd 0755 1000 1000 -"
    "d /mnt/media/downloads/sabnzbd/incomplete 0755 1000 1000 -"
    "d /mnt/media/downloads/slskd 0755 1000 1000 -"
  ];

  # Firewall: only expose HTTP/HTTPS publicly
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5984 8000 8501 8282 ];
  };
}
