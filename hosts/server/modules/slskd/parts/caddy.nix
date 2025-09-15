# modules/server/slskd/parts/caddy.nix
# Returns the reverse proxy config for the :5030 virtual host
''
reverse_proxy slskd:5030
''
