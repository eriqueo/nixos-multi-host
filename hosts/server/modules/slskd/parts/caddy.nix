# modules/server/slskd/parts/caddy.nix
# Returns the Caddy extraConfig string for this service.
''
  # ---- slskd
  handle /slskd { redir /slskd/ 301 }
  route /slskd* {
    reverse_proxy 127.0.0.1:5030 {
      header_up Host {host}
      header_up X-Forwarded-Host {host}
      header_up X-Forwarded-Proto {scheme}
      header_up X-Forwarded-Port {server_port}
      header_up X-Forwarded-For {remote}
      header_up X-Real-IP {remote}
    }
  }
''
