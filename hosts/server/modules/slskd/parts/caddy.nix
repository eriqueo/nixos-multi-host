# modules/server/slskd/parts/caddy.nix
# Returns the Caddy extraConfig string for this service.
''
  # ---- slskd - exposed on port 5030
  :5030 {
    reverse_proxy slskd:5030 {
      header_up Host {host}
      header_up X-Forwarded-Host {host}
      header_up X-Forwarded-Proto {scheme}
      header_up X-Forwarded-Port {server_port}
      header_up X-Forwarded-For {remote}
      header_up X-Real-IP {remote}
    }
  }
''
