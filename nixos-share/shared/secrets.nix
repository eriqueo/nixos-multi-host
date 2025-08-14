# /etc/nixos/shared/secrets.nix
{ config, lib, ... }:

{
  # Set default SOPS file for all secrets
  sops.defaultSopsFile = ../secrets/admin.yaml;
  
  # Age key file path (set globally)
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  # Declare VPN secrets from encrypted admin.yaml
  sops.secrets."vpn/protonvpn/username" = {
    key = "vpn/protonvpn/username";
    format = "yaml";
  };

  sops.secrets."vpn/protonvpn/password" = {
    key = "vpn/protonvpn/password";
    format = "yaml";
  };

  # Render gluetun environment file using SOPS templates
  sops.templates."gluetun.env".content = ''
    VPN_SERVICE_PROVIDER=protonvpn
    VPN_TYPE=openvpn
    OPENVPN_USER=${config.sops.placeholder."vpn/protonvpn/username"}
    OPENVPN_PASSWORD=${config.sops.placeholder."vpn/protonvpn/password"}
    SERVER_COUNTRIES=Netherlands
    HEALTH_VPN_DURATION_INITIAL=30s
    TZ=${config.time.timeZone}
  '';

  # Secure permissions on rendered template
  sops.templates."gluetun.env".owner = "root";
  sops.templates."gluetun.env".group = "root";
  sops.templates."gluetun.env".mode = "0400";
}

