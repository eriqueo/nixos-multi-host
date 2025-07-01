# hosts/server/config.nix
# Updated configuration with GPU acceleration and hot storage integration
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # 1. IMPORTS - Updated with new modules
  ####################################################################
  imports = [
    ./hardware-configuration.nix
    
    # User configuration
    ../../modules/users/eric.nix
    
    # Shared configuration
    ../../shared/secrets.nix
    ../../shared/zsh-config.nix
    
    # Consolidated filesystem structure
    ../../modules/filesystem
    
    # New modules for GPU and SSD integration
    ./modules/gpu-acceleration.nix       # NVIDIA Quadro P1000 support
    ./modules/hot-storage.nix           # SSD hot storage tier
    ./modules/media-containers-v2.nix   # Updated containers with GPU and hot/cold storage
    
    # Monitoring stack
    ./modules/monitoring.nix              # Comprehensive monitoring with Grafana/Prometheus
    ./modules/media-monitor-setup.nix     # Media pipeline monitoring
    ./modules/grafana-dashboards.nix      # Custom dashboards
    ./modules/business-monitoring.nix     # Business intelligence monitoring
    
    # Existing modules
    ./modules/surveillance.nix
    ./modules/business-services.nix
    ./modules/business-api.nix
    ./modules/ai-services.nix
    ./modules/adhd-tools.nix
    ./modules/obsidian-sync.nix
    ./modules/hardware-tools.nix
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
  # ZSH system enablement now handled in modules/users/eric.nix

  ####################################################################
  # 7. SERVER-SPECIFIC SYSTEM PACKAGES
  ####################################################################
  # Core packages now provided by modules/users/eric.nix
  # Only server-specific packages are included here
  environment.systemPackages = with pkgs; [
    # Claude Code CLI
    claude-code
    
    # GUI applications (X11 forwarding support)
    kitty                  # Terminal emulator
    xfce.thunar           # File manager
    xorg.xauth            # Required for X11 forwarding
    file-roller           # Archive manager (zip/tar files)
    evince                # PDF viewer
    feh                   # Image viewer (lightweight)
    
    # Media tools (server-specific)
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
  
  # Immich Native Service - Photo management with GPU support
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    mediaLocation = "/mnt/media/pictures";
    
    # Database configuration on hot storage for performance
    database = {
      enable = true;
      name = "immich";
      user = "immich";
      createDB = true;
    };
    
    # Redis configuration for caching 
    redis = {
      enable = true;
      host = "127.0.0.1";
      port = 6380;  # Use different port to avoid conflict
    };
    
    environment = {
      # Hot storage paths for processing and caching
      IMMICH_UPLOAD_LOCATION = "/mnt/hot/cache/immich/upload";
      IMMICH_THUMBNAIL_LOCATION = "/mnt/hot/cache/immich/thumb";
      IMMICH_ENCODED_VIDEO_LOCATION = "/mnt/hot/cache/immich/encoded";
      
      # Redis connection to Immich-specific instance
      REDIS_HOSTNAME = "127.0.0.1";
      REDIS_PORT = "6380";
      
      # GPU acceleration settings
      IMMICH_MACHINE_LEARNING_ENABLED = "true";
    };
  };
  
  # Override Jellyfin service to enable GPU access
  systemd.services.jellyfin = {
    serviceConfig = {
      # Add GPU device access
      DeviceAllow = [
        "/dev/dri/card0 rw"
        "/dev/dri/renderD128 rw"
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-modeset rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
    };
    environment = {
      # NVIDIA GPU acceleration
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
    };
  };

  # Override Immich services to enable GPU access
  systemd.services.immich-server = {
    serviceConfig = {
      # Add GPU device access for photo/video processing
      DeviceAllow = [
        "/dev/dri/card0 rw"
        "/dev/dri/renderD128 rw"
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-modeset rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
    };
    environment = {
      # NVIDIA GPU acceleration
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
    };
  };

  systemd.services.immich-machine-learning = {
    serviceConfig = {
      # Add GPU device access for ML processing
      DeviceAllow = [
        "/dev/dri/card0 rw"
        "/dev/dri/renderD128 rw"
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-modeset rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
    };
    environment = {
      # NVIDIA GPU acceleration for ML workloads
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
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
  
  # NVIDIA container runtime is enabled in gpu-acceleration.nix
  ####################################################################
  # 13. FILE OWNERSHIP & PERMISSIONS
  ####################################################################
  # File ownership rules now handled in modules/users/eric.nix

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
