# modules/server/slskd/parts/caddy.nix
# Returns the reverse proxy config for slskd subpath with proper headers
''
handle /slskd { redir /slskd/ 301 }
handle /slskd/* {
  reverse_proxy 127.0.0.1:5031 {
    header_up Host {host}
    header_up X-Forwarded-Proto {scheme}
    header_up X-Forwarded-For {remote}
    header_up X-Forwarded-Prefix /slskd
    header_up Upgrade {>Upgrade}
    header_up Connection {>Connection}
  }
}
''