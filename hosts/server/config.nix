{ config, pkgs, lib, ... }:

{
  imports = [
  	../../configuration.nix
    ../../hardware-configuration.nix
    ../../modules.nix
  ];

  ++ lib.optionals config.server [
    podman-compose iotop lsof strace
    ffmpeg-full
  ];
  ++ lib.optionals config.server [ "docker" "podman" ];

  networking.firewall = {
        enable = true;
        allowedTCPPorts = lib.mkIf config.server [
          22 2283 4533 5000 7878 8080 8096 8123 8686 8989 9696
        ];
        allowedUDPPorts = lib.mkIf config.server [
          7359 8555
        ];
        interfaces = lib.mkIf config.server {
          "tailscale0" = {
            allowedTCPPorts = [
              5432 6379 8000 8501 11434 1883
            ];
          };
        };
      };
