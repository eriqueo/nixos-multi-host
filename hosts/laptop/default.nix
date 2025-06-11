{ config, pkgs, ... }:

{
  imports = [
    ../../configuration.nix
    ../../hardware-configuration.nix
    ../../modules.nix
  ];

  # Set the hostname for this server
  networking.hostName = "homeserver";

  # Server-specific packages
  environment.systemPackages = with pkgs; [
    podman-compose
    iotop
    lsof
    strace
    ffmpeg-full
    # Add any other server-specific packages here
  ];

  # Add server-specific groups for your user (if needed)
  users.users.eric.extraGroups = [ "docker" "podman" ];

  # Configure the firewall for server ports
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 2283 4533 5000 7878 8080 8096 8123 8686 8989 9696
    ];
    allowedUDPPorts = [
      7359 8555
    ];
    interfaces = {
      "tailscale0" = {
        allowedTCPPorts = [
          5432 6379 8000 8501 11434 1883
        ];
      };
    };
  };

networking.networkmanager.enable = true;

hardware.bluetooth.enable = true;
services.blueman.enable = true;
}
