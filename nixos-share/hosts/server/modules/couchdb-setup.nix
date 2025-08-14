{ config, pkgs, ... }:
{
  # SOPS secrets configuration for CouchDB admin credentials
  sops.secrets.couchdb_admin_username = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "couchdb/admin_username";
    mode = "0400";
    owner = "couchdb";
    group = "couchdb";
  };
  
  sops.secrets.couchdb_admin_password = {
    sopsFile = ../../../secrets/admin.yaml;
    key = "couchdb/admin_password";
    mode = "0400";
    owner = "couchdb";
    group = "couchdb";
  };

  # Systemd service to setup CouchDB admin config BEFORE CouchDB starts
  systemd.services.couchdb-config-setup = {
    description = "Setup CouchDB admin configuration from SOPS secrets";
    before = [ "couchdb.service" ];
    wantedBy = [ "couchdb.service" ];
    wants = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      # Ensure CouchDB config directory exists
      mkdir -p /var/lib/couchdb
      
      # Read credentials from SOPS secrets
      ADMIN_USERNAME=$(cat ${config.sops.secrets.couchdb_admin_username.path})
      ADMIN_PASSWORD=$(cat ${config.sops.secrets.couchdb_admin_password.path})
      
      # Create local.ini with admin user configuration
      cat > /var/lib/couchdb/local.ini << EOF
[admins]
$ADMIN_USERNAME = $ADMIN_PASSWORD

[couchdb]
single_node=true

[chttpd]
require_valid_user = true
max_http_request_size = 4294967296

[chttpd_auth]
require_valid_user = true

[httpd]
WWW-Authenticate = Basic realm="couchdb"
enable_cors = true

[cors]
origins = app://obsidian.md,capacitor://localhost,http://localhost
credentials = true
headers = accept, authorization, content-type, origin, referer
methods = GET, PUT, POST, HEAD, DELETE
max_age = 3600

[couchdb]
max_document_size = 50000000
EOF
      
      # Set proper ownership and permissions
      chown couchdb:couchdb /var/lib/couchdb/local.ini
      chmod 600 /var/lib/couchdb/local.ini
    '';
  };

  # CouchDB service configuration (minimal, let local.ini handle the rest)
  services.couchdb = {
    enable = true;
    port = 5984;
    bindAddress = "127.0.0.1";
    # Don't set adminUser/adminPass here - we handle it via local.ini
  };
}