# modules/server/slskd/parts/config.nix
# Returns a Nix attribute set representing the slskd.yml config.
{
  debug = false;
  headless = false;
  remote_configuration = false;
  remote_file_management = false;
  instance_name = "default";

  flags = {
    no_logo = false;
    no_start = false;
    no_config_watch = false;
    no_connect = false;
    no_share_scan = false;
    force_share_scan = false;
    force_migrations = false;
    no_version_check = false;
    log_sql = false;
    experimental = false;
    volatile = false;
    case_sensitive_reg_ex = false;
    legacy_windows_tcp_keepalive = false;
  };

  web = {
    port = 5030;
    url_base = "/slskd";
    https = {
      disabled = true;
      port = 5031;
      force = false;
    };
    content_path = "wwwroot";
    logging = false;
    authentication = {
      disabled = false;
      username = "slskd-admin";
      password = "NpbG0Jcj4CP2h50arX6wtxFc5ju4PaPQ";
      jwt = {
        key = "Nd5g9X1AcVck7z7Q4Yq0IuULeQ7ci/Zu7++Lmcq7jOqF0e6ZbCvp5SmWVBN3EAVE";
        ttl = 604800000;
      };
      api_keys = {};
    };
  };

  feature = {
    swagger = false;
  };

  metrics = {
    enabled = false;
  };

  directories = {
    incomplete = "/downloads/incomplete";
    downloads = "/downloads/complete";
  };

  shares = {
    directories = [
      "/music"
    ];
    filters = [
      "\\.ini$"
      "Thumbs\\.db$"
      "\\.DS_Store$"
    ];
    cache = {
      storage_mode = "memory";
      workers = 16;
      retention = 10080;
    };
  };

  soulseek = {
    address = "vps.slsknet.org";
    port = 2271;
    username = "eriqueok";
    password = "il0wwlm?";
    description = "A slskd user. https://github.com/slskd/slskd";
    listen_ip_address = "0.0.0.0";
    listen_port = 50300;
  };
}