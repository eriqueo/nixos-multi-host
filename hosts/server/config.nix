# hosts/server/config.nix
# Updated configuration with GPU acceleration and hot storage integration
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # 1. IMPORTS - Updated with new modules
  ####################################################################
  imports = [
    ./hardware-configuration.nix
    
    # New modules for GPU and SSD integration
    ./modules/gpu-acceleration.nix       # NVIDIA Quadro P1000 support
    ./modules/hot-storage.nix           # SSD hot storage tier
    ./modules/media-containers-v2.nix   # Updated containers with GPU and hot/cold storage
    
    # Existing modules
    ./modules/surveillance.nix
    ./modules/business-services.nix
    ./modules/business-api.nix
    ./modules/ai-services.nix
    ./modules/adhd-tools.nix
    ./modules/obsidian-sync.nix
    ./modules/hardware-tools.nix
    
    # Shared configuration
    ../../shared/secrets.nix
  ];

  ####################################################################
  # 2. NIX CONFIGURATION
  ####################################################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;  # Required for NVIDIA drivers

  ####################################################################
  # 2.1. SOPS SECRETS CONFIGURATION
  ####################################################################
  sops.age.keyFile = "/etc/sops/age/keys.txt";

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
  # Existing media storage mount (HDD - cold storage)
  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "ext4";
  };
  
  # Note: Hot storage mount (/mnt/hot) is configured in modules/hot-storage.nix

  ####################################################################
  # 6. ZSH CONFIGURATION - SYSTEM LEVEL
  ####################################################################
  programs.zsh.enable = true;

  ####################################################################
  # 7. SYSTEM PACKAGES
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
    claude-code
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
    
    # Additional tools for GPU and storage monitoring
   # nvtop                 # GPU monitoring (from gpu-acceleration.nix)
   # iotop                 # I/O monitoring (from hot-storage.nix)
  ];

  ####################################################################
  # 8. SSH & X11 SERVICES
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
  # 9. MEDIA SERVICES - Updated for GPU acceleration
  ####################################################################
  # Jellyfin Native Service - Enhanced with GPU support
  services.jellyfin = {
    enable = true;
    openFirewall = false;  # We'll manage firewall manually
  };
  
  # Override Jellyfin service to enable GPU access
  systemd.services.jellyfin = {
    serviceConfig = {
      # Add GPU device access
      DeviceAllow = [
        "/dev/dri/card0 rw"
        "/dev/dri/renderD128 rw"
      ];
    };
  };

  ####################################################################
  # 10. BUSINESS AI SERVICES - Updated for GPU acceleration
  ####################################################################
  # Update existing Ollama service for CUDA support
  services.ollama = {
    enable = true;
    acceleration = "cuda";  # Enable CUDA acceleration
    host = "127.0.0.1";
    port = 11434;
    # Move models to hot storage for faster loading
    home = "/mnt/hot/ai";
  };

# Allow Caddy to access Tailscale certificates
services.tailscale.permitCertUid = "caddy";
  ####################################################################
  # 11. FIREWALL CONFIGURATION - Updated ports
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
      5030  # SLSKD
    ];
    allowedUDPPorts = [
      7359   # Jellyfin
      50300  # SLSKD
    ];
    # Allow Tailscale and local network access
    interfaces."tailscale0" = {
      allowedTCPPorts = [ 5000 8123 8554 8555 1883 8000 8501 5432 6379 ];
      allowedUDPPorts = [ 8555 ];
    };
  };

  ####################################################################
  # 12. CONTAINER RUNTIME - GPU support
  ####################################################################
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";
  
  # Enable NVIDIA container runtime
hardware.nvidia-container-toolkit.enable = true;
  ####################################################################
  # 13. FILE OWNERSHIP & PERMISSIONS
  ####################################################################
  # Ensure user can edit NixOS configuration
  systemd.tmpfiles.rules = [
    "Z /etc/nixos - eric users - -"
  ];

  ####################################################################
  # 14. PERFORMANCE OPTIMIZATIONS
  ####################################################################
  # I/O scheduler optimization for mixed SSD/HDD setup
  services.udev.extraRules = ''
    # Use mq-deadline for SSDs (better for mixed workloads)
    ACTION=="add|change", KERNEL=="nvme*", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd*", ENV{ID_BUS}=="ata", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    
    # Use CFQ for HDDs (better for sequential workloads)
    ACTION=="add|change", KERNEL=="sd*", ENV{ID_BUS}=="ata", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="cfq"
  '';

  ####################################################################
  # 15. MONITORING & LOGGING
  ####################################################################
  # Enhanced logging for GPU and storage monitoring
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
  '';

  ####################################################################
  # 16. SYSTEM STATE VERSION
  ####################################################################
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05"; # Did you read the comment?
}
