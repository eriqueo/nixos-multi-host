{ config, pkgs, lib, ... }:

{
  imports = [
    ../../configuration.nix
    ../../hardware-configuration.nix
    ../../modules/services.nix
  ];

  networking.hostName = "homeserver";

  # Server-specific packages
  environment.systemPackages = with pkgs; [
    podman-compose 
    iotop 
    lsof 
    strace
    ffmpeg-full
  ];

  # Add user to server-specific groups
  users.users.eric.extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "podman" ];

  # Server firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22     # SSH
      2283   # Immich
      4533   # Navidrome
      5000   # Frigate
      7878   # Radarr
      8080   # qBittorrent
      8096   # Jellyfin
      8123   # Home Assistant
      8686   # Lidarr
      8989   # Sonarr
      9696   # Prowlarr
    ];
    allowedUDPPorts = [
      7359   # Frigate RTMP
      8555   # Frigate WebRTC
    ];
    interfaces = {
      "tailscale0" = {
        allowedTCPPorts = [
          5432   # PostgreSQL
          6379   # Redis
          8000   # Custom API
          8501   # Streamlit
          11434  # Ollama
          1883   # MQTT
        ];
      };
    };
  };

  # Enable server-specific services
  services.jellyfin.enable = true;
  
  # Hardware acceleration for media
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}
