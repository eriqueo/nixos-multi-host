{ config, lib, pkgs, ... }:
{
  # Caddy reverse proxy for all services
  services.caddy = {
    enable = true;
    virtualHosts."hwc.ocelot-wahoo.ts.net".extraConfig = ''
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
      handle_path /navidrome/* {
        reverse_proxy localhost:4533
      }

      # *ARR stack - Fixed: Changed from 'handle' to 'handle_path' to strip path prefixes
      # This prevents apps from receiving URLs like /sonarr/api/ (they expect just /api/)
      
      # ---- Sonarr
      handle /sonarr { redir /sonarr/ 301 }
      route /sonarr/* {
        uri strip_prefix /sonarr
        reverse_proxy 127.0.0.1:8989 {
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-For {remote_host}
          header_up Host {host}
        }
      }
      
      # ---- Radarr
      handle /radarr { redir /radarr/ 301 }
      route /radarr/* {
        uri strip_prefix /radarr
        reverse_proxy 127.0.0.1:7878 {
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-For {remote_host}
          header_up Host {host}
        }
      }
      
      # ---- Lidarr
      handle /lidarr { redir /lidarr/ 301 }
      route /lidarr/* {
        uri strip_prefix /lidarr
        reverse_proxy 127.0.0.1:8686 {
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-For {remote_host}
          header_up Host {host}
        }
      }
      
      # ---- Prowlarr
      handle /prowlarr { redir /prowlarr/ 301 }
      route /prowlarr/* {
        uri strip_prefix /prowlarr
        reverse_proxy 127.0.0.1:9696 {
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-For {remote_host}
          header_up Host {host}
        }
      }


      # ---- slskd
      handle /slskd { redir /slskd/ 301 }
      handle_path /slskd/* {
        uri strip_prefix /slskd
        reverse_proxy 127.0.0.1:5030 {
          header_up Host {host}
          header_up X-Forwarded-Host {host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Port {server_port}
          header_up X-Forwarded-For {remote}
          header_up X-Real-IP {remote}
        }
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

      # Photo management
      handle_path /immich/* {
        reverse_proxy localhost:2283
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

  # Firewall: only expose HTTP/S publicly, other services only on Tailscale
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5984 8000 8501 8282 ];
  };
}

# IMPORTANT: Do not use Tailscale Serve with this Caddy configuration
# ChatGPT's mistake was running: sudo tailscale serve --bg --https=8989 localhost:8989
# This bypassed Caddy's path-based routing and broke everything
#
# On the server, run this cleanup command:
# sudo tailscale serve reset
