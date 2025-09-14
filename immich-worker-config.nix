# /etc/nixos/immich-worker-config.nix
# Immich ML Processing Worker Node Configuration
# This node handles CPU/GPU intensive ML tasks for the main Immich instance
{ config, lib, pkgs, ... }:

{
  imports = [
    # Include hardware configuration for the worker machine
    ./hardware-configuration.nix
  ];

  # System identification
  networking.hostName = "immich-worker";
  
  # Enable Tailscale for secure communication with main server
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # NFS client for accessing shared photo storage from main server
  services.rpcbind.enable = true;
  fileSystems."/mnt/shared-photos" = {
    device = "100.115.126.41:/mnt/hot/pictures";  # hwc-server Tailscale IP
    fsType = "nfs";
    options = [ 
      "nfsvers=4.1"
      "rsize=1048576"
      "wsize=1048576" 
      "hard"
      "timeo=600"
      "retrans=2"
    ];
  };

  # Immich ML Worker Service (machine learning only)
  services.immich = {
    enable = true;
    # Only run machine learning service, not web/server components
    settings = {
      server.enable = false;
      web.enable = false;
      machineLearning.enable = true;
    };
    
    # Connect to main server's database
    database = {
      host = "100.115.126.41";  # hwc-server Tailscale IP  
      port = 5432;
      name = "immich_new";
      username = "immich_new";
    };
    
    # Connect to main server's Redis
    redis = {
      host = "100.115.126.41";  # hwc-server Tailscale IP
      port = 6381;
    };

    # Point to shared storage mounted via NFS
    mediaLocation = "/mnt/shared-photos";
    
    environment = {
      # ML processing cache on worker's local fast storage
      IMMICH_UPLOAD_LOCATION = "/var/cache/immich-worker/upload";
      IMMICH_THUMBNAIL_LOCATION = "/var/cache/immich-worker/thumb";
      IMMICH_ENCODED_VIDEO_LOCATION = "/var/cache/immich-worker/encoded";
      
      # Connect to main server services
      DATABASE_URL = "postgresql://immich_new@100.115.126.41:5432/immich_new";
      REDIS_URL = "redis://100.115.126.41:6381";
      
      # ML processing configuration
      IMMICH_MACHINE_LEARNING_ENABLED = "true";
      IMMICH_WORKERS = "4";  # Adjust based on worker node CPU cores
      
      # Performance tuning
      IMMICH_ML_WORKERS = "2";  # Concurrent ML jobs
      IMMICH_ML_REQUEST_THREADS = "4";  # Request handling threads
    };
  };

  # Override ML service for optimal performance and GPU access
  systemd.services.immich-machine-learning = {
    serviceConfig = {
      # Resource limits to prevent thermal issues
      CPUQuota = "80%";  # Limit to 80% of CPU capacity
      MemoryMax = "8G";   # Adjust based on worker RAM
      
      # GPU device access (if worker has GPU)
      DeviceAllow = [
        "/dev/dri/card0 rw"
        "/dev/dri/renderD128 rw"
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw" 
        "/dev/nvidia-modeset rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
      SupplementaryGroups = [ "video" "render" ];
    };
    
    environment = {
      # NVIDIA GPU acceleration (if worker has NVIDIA GPU)
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
      LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";
      
      # PyTorch CUDA configuration
      CUDA_VISIBLE_DEVICES = "0";
      TORCH_CUDA_ARCH_LIST = "6.1,7.5,8.6";  # Support multiple architectures
      
      # ML model cache directories
      MPLCONFIGDIR = "/var/cache/immich-worker";
      TRANSFORMERS_CACHE = "/var/cache/immich-worker";
      HF_HOME = "/var/cache/immich-worker";
    };
  };

  # Create necessary cache directories
  systemd.tmpfiles.rules = [
    "d /var/cache/immich-worker 0755 immich immich -"
    "d /var/cache/immich-worker/upload 0755 immich immich -"
    "d /var/cache/immich-worker/thumb 0755 immich immich -"
    "d /var/cache/immich-worker/encoded 0755 immich immich -"
  ];

  # Firewall configuration - only allow Tailscale access
  networking.firewall = {
    enable = true;
    # Block all external access
    allowedTCPPorts = [ ];
    # Only allow access from Tailscale network
    interfaces."tailscale0" = {
      allowedTCPPorts = [ 3003 ];  # ML service port
    };
  };

  # GPU support (if worker has NVIDIA GPU)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Essential packages for ML processing
  environment.systemPackages = with pkgs; [
    # ML and image processing
    python3
    python3Packages.torch
    python3Packages.torchvision
    ffmpeg
    imagemagick
    # Monitoring and debugging
    htop
    nvtop
    nethogs
    iotop
    # Network tools
    nfs-utils
    tailscale
  ];

  # Performance optimizations
  boot.kernel.sysctl = {
    # Network performance for NFS
    "net.core.rmem_max" = 268435456;
    "net.core.wmem_max" = 268435456;
    "net.ipv4.tcp_rmem" = "4096 87380 268435456";
    "net.ipv4.tcp_wmem" = "4096 65536 268435456";
  };

  system.stateVersion = "25.11";
}