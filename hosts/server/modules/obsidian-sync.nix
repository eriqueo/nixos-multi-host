{ config, pkgs, ... }:
{
  # CouchDB for Obsidian LiveSync – let CouchDB handle CORS
  services.couchdb = {
    enable      = true;
    port        = 5984;
    bindAddress = "127.0.0.1";
    adminUser   = "eric";
    adminPass   = "il0wwlm?";

    extraConfig = {
      chttpd = {
        require_valid_user    = "true";
        max_http_request_size = "4294967296";
      };
      chttpd_auth = {
        require_valid_user = "true";
      };
      httpd = {
        WWW-Authenticate = "Basic realm=\"couchdb\"";
        enable_cors      = "true";  # enable native CORS
      };
      cors = {
        origins     = "app://obsidian.md,capacitor://localhost,http://localhost";
        credentials = "true";
        headers     = "accept, authorization, content-type, origin, referer";
        methods     = "GET, PUT, POST, HEAD, DELETE";
        max_age     = "3600";
      };
      couchdb = {
        max_document_size = "50000000";
      };
    };
  };

  # Caddy reverse proxy for all services, with minimal logic for Obsidian LiveSync
  services.caddy = {
    enable = true;
    virtualHosts."heartwood.ocelot-wahoo.ts.net".extraConfig = ''
      # TLS via Tailscale certificates
      tls /var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.crt \
          /var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.key

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

      # Additional service proxies
      handle /cameras* {
        reverse_proxy localhost:5000 { header_up Host {host} }
      }
      handle_path /qbt/* {
        reverse_proxy localhost:8080
      }
      handle /sab/* {
        reverse_proxy localhost:8081
      }
      handle_path /media/* {
        reverse_proxy localhost:8096
      }
      handle_path /navidrome/* {
        reverse_proxy localhost:4533
      }
      handle_path /home/* {
        reverse_proxy localhost:8123 {
          header_up Upgrade {http.request.header.Upgrade}
          header_up Connection {http.request.header.Connection}
        }
      }
      handle /business* {
        reverse_proxy localhost:8000
      }
      handle /dashboard* {
        reverse_proxy localhost:8501
      }
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
      handle_path /immich/* {
        reverse_proxy localhost:2283
      }
    '';
  };

  # Firewall: only expose HTTP/S publicly, couchDB only on Tailscale
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 5984 8000 8501 ];
  };
  # Fix Tailscale certificate permissions for Caddy
    systemd.tmpfiles.rules = [
      "d /var/lib/tailscale 0755 root root -"
      "d /var/lib/tailscale/certs 0755 root root -"
      "Z /var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.crt 0644 root caddy -"
      "Z /var/lib/tailscale/certs/heartwood.ocelot-wahoo.ts.net.key 0640 root caddy -"
    ];
}
