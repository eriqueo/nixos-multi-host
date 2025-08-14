{ config, lib, pkgs, ... }:

let
  # expose the two decrypted secret paths
  sopsSecrets = {
    vpn_username = {
      sopsFile = ../../../secrets/admin.yaml;
      key = "vpn/protonvpn/username";
    };
    vpn_password = {
      sopsFile = ../../../secrets/admin.yaml;
      key = "vpn/protonvpn/password";
    };
  };
in
{
  # Make the secrets available for other modules if needed
  # e.g., import this module and refer to config.vpn.sopsSecrets.vpn_username.path
  vpn = {
    sopsSecrets = sopsSecrets;
  };

  # Oneshoot service that generates the .env file for Gluetun
  systemd.services.gluetun-env-setup = {
    description = "Generate Gluetun environment file from SOPS secrets";
    before = [ "podman-gluetun.service" ]; # adjust if your unit has a different name
    wantedBy = [ "podman-gluetun.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -euo pipefail

      # Ensure secrets are decryptable; fail early if not
      user=$(cat ${sopsSecrets.vpn_username.path})
      pass=$(cat ${sopsSecrets.vpn_password.path})

      mkdir -p /opt/downloads
      temp=$(mktemp)

      cat > "$temp" <<EOF
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=openvpn
OPENVPN_USER=$user
OPENVPN_PASSWORD=$pass
SERVER_COUNTRIES=Netherlands
HEALTH_VPN_DURATION_INITIAL=30s
EOF

      chmod 600 "$temp"
      chown root:root "$temp"
      mv "$temp" /opt/downloads/.env
    '';
  };
}

