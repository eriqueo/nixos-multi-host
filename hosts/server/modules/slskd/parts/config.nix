# modules/server/slskd/parts/config.nix
# Returns a Nix attribute set representing the slskd.yml config.
{
  debug = false;
  headless = false;
  remoteConfiguration = false;
  remoteFileManagement = false;
  instanceName = "default";

  web = {
    port = 5030;
    https = {
      disabled = true;
    };
    url_base = "/";
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
      "\.ini$"
      "Thumbs\.db$"
      "\.DS_Store$"
    ];
    cache = {
      storage_mode = "memory";
      workers = 16;
      retention = null;
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
