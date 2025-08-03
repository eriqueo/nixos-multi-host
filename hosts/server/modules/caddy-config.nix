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

      # *ARR stack
      handle /sonarr/* {
        reverse_proxy localhost:8989
      }
      handle /radarr/* {
        reverse_proxy localhost:7878
      }
      handle /lidarr/* {
        reverse_proxy localhost:8686
      }
      handle /prowlarr/* {
        reverse_proxy localhost:9696
      }

      # Business services
      handle /business* {
        reverse_proxy localhost:8000
      }
      handle /dashboard* {
        reverse_proxy localhost:8501
      }

      # Photo management
      handle_path /immich/* {
        reverse_proxy localhost:2283
      }
    '';
  };

  # Firewall: only expose HTTP/S publicly, other services only on Tailscale
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5984 8000 8501 ];
  };
}
