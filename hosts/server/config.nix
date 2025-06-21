# -----------------------------------------------------------------------------
# SERVER CONFIGURATION - Heartwood Craft Homeserver
# Main system configuration for business intelligence and media server
# https://search.nixos.org/options and NixOS manual (nixos-help)
# -----------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # 1. IMPORTS
  ####################################################################
  imports = [
    ./hardware-configuration.nix
    ./modules/surveillance.nix
    ./modules/business-services.nix
    ./modules/business-api.nix
    ./modules/ai-services.nix
    ./modules/adhd-tools.nix
    ./modules/obsidian-sync.nix
    ./modules/hardware-tools.nix
    ./containers.nix
    ../../shared/secrets.nix 
  ];

  ####################################################################
  # 2. NIX CONFIGURATION
  ####################################################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  ####################################################################
  # 3. BOOT & SYSTEM
  ####################################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ####################################################################
  # 4. HOST IDENTITY & NETWORKING
  ####################################################################
  networking.hostName = "homeserver";
  networking.networkmanager.enable = true;
  
  # Set your time zone
  time.timeZone = "America/Denver";

  ####################################################################
  # 5. STORAGE MOUNTS
  ####################################################################
  # Media Storage Mount
  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "ext4";
  };

  ####################################################################
  # 6. USER MANAGEMENT
  ####################################################################
  #users.users.eric = {
    #isNormalUser = true;
    #extraGroups = [ "wheel" "networkmanager" ];
    #shell = pkgs.zsh;
    #packages = with pkgs; [
      # User-specific packages can go here
   # ];
  #};

  ####################################################################
  # 7. ZSH CONFIGURATION - SYSTEM LEVEL
  ####################################################################
  programs.zsh.enable = true;

  ####################################################################
  # 8. SYSTEM PACKAGES
  ####################################################################
  environment.systemPackages = with pkgs; [
    # Network utilities
    wget                    # Download files from web
    curl                    # Transfer data from/to servers
    
    # Development tools
    git                     # Version control system
    micro                   # Modern terminal text editor
    
    # System monitoring
    htop                    # Interactive process viewer
    neofetch               # System information display
    tree                   # Directory structure display
    
    # Security tools
    ssh-to-age             # SSH key to age key converter
    sops                   # Secrets management tool
    age                    # File encryption tool
    
    # GUI applications (X11 forwarding support)
    kitty                  # Terminal emulator
    xfce.thunar           # File manager
    xorg.xauth            # Required for X11 forwarding
    file-roller           # Archive manager (zip/tar files)
    evince                # PDF viewer
    feh                   # Image viewer (lightweight)
    
    # Media tools
    picard                # Music organization
  ];

  ####################################################################
  # 9. SSH & X11 SERVICES
  ####################################################################
  services.openssh = {
    enable = true;
    settings.X11Forwarding = true;
  };
  
  # Enable basic X11 services (minimal for forwarding)
  services.xserver.enable = true;
  
  # Tailscale for secure remote access
  services.tailscale.enable = true;

  
  ####################################################################
  # 12. BUSINESS API SERVICES
  ####################################################################
  systemd.services.receipt-api = {
    description = "Receipt Upload API";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "eric";
      Group = "users";
      WorkingDirectory = "/opt/business/api";
      ExecStart = "${pkgs.python311.withPackages(ps: [ ps.fastapi ps.uvicorn ps.python-multipart ])}/bin/python receipt_upload.py";
      Restart = "always";
      RestartSec = "10";
    };
  };

  ####################################################################
  # 13. MEDIA SERVICES
  ####################################################################
  # Jellyfin Native Service
  services.jellyfin = {
    enable = true;
    openFirewall = false;  # We'll manage firewall manually
  };

  ####################################################################
  # 14. FIREWALL CONFIGURATION
  ####################################################################
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH
      8080  # qBittorrent (via Gluetun)
      7878  # Radarr
      8989  # Sonarr
      8686  # Lidarr
      9696  # Prowlarr
      4533  # Navidrome
      8096  # Jellyfin
      2283  # Immich
      8081  # SABnzbd
      8888  # Receipt API
      5030    # slskd web interface
      50300   # Soulseek P2P port
    ];
    allowedUDPPorts = [
      7359  # Jellyfin
    ];
    # Block all other external access
    extraCommands = ''
      # Allow Tailscale network
      iptables -A INPUT -i tailscale0 -j ACCEPT
      # Allow local network for Samba (optional)
      iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT
     '';
  };

  ####################################################################
  # 15. FILE OWNERSHIP & PERMISSIONS
  ####################################################################
  # Ensure user can edit NixOS configuration
  systemd.tmpfiles.rules = [
    "Z /etc/nixos - eric users - -"
  ];

  ####################################################################
  # 16. SYSTEM STATE VERSION
  ####################################################################
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05"; # Did you read the comment?
}