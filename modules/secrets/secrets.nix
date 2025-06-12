# modules/secrets.nix

{ lib, config, ... }:

{
  # Deploy secret files under /etc/secrets/...
  # (ensure you have created modules/secrets/ and placed your files there)
  environment.etc = {
    "secrets" = {
      source = null;  # create directory
      mode   = "0750";
    };

    # Insert each secret file here
    "secrets/my-api-key.json".source = ./secrets/my-api-key.json;
    "secrets/other-credential.pem".source = ./secrets/other-credential.pem;
  };

  # If you prefer to place some secrets in your user home via Home-Manager:
  # home.file = {
  #   ".ssh/id_ed25519".source     = ./secrets/id_ed25519;
  #   ".ssh/id_ed25519.pub".source = ./secrets/id_ed25519.pub;
  # };
}
