# hosts/server/modules/gpu-acceleration.nix
# This module configures your NVIDIA Quadro P1000 for hardware acceleration
{ config, pkgs, ... }:

{
  # Enable graphics hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    
    # Add drivers for both Intel iGPU and NVIDIA Quadro P1000
    extraPackages = with pkgs; [
      # Intel iGPU acceleration (fallback for basic tasks)
      intel-media-driver      # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver      # LIBVA_DRIVER_NAME=i965 (fallback)
      libvdpau-va-gl
      
      # NVIDIA acceleration packages for Pascal architecture (Quadro P1000)
      nvidia-vaapi-driver     # For VAAPI support
      vaapiVdpau             # VDPAU to VAAPI bridge
    ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # NVIDIA GPU Configuration optimized for Quadro P1000
  hardware.nvidia = {
    # Modesetting is required for proper operation
    modesetting.enable = true;
    
    # Power management settings for server (24/7 operation)
    powerManagement.enable = false;        # Disable for server stability
    powerManagement.finegrained = false;  # Not needed for server workloads
    
    # Use proprietary drivers for Quadro P1000 (Pascal architecture)
    # Open-source drivers not recommended for professional cards
    open = false;
    
    # Use stable drivers for server reliability
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Load NVIDIA kernel modules early in boot process
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.blacklistedKernelModules = [ "nouveau" ];  # Disable nouveau
  
  # Kernel parameters for NVIDIA
  boot.kernelParams = [ 
    "nvidia-drm.modeset=1"  # Enable DRM kernel mode setting
  ];

  # Environment variables for GPU acceleration
  environment.sessionVariables = {
    # NVIDIA specific
    CUDA_CACHE_PATH = "/tmp/cuda-cache";
    
    # VAAPI driver selection (prefer NVIDIA, fallback to Intel)
    LIBVA_DRIVER_NAME = "nvidia";
    
    # VDPAU driver
    VDPAU_DRIVER = "nvidia";
  };

# Install GPU utilities and monitoring tools
  environment.systemPackages = with pkgs; [
    # NVIDIA tools - use the driver package which includes nvidia-smi
    config.boot.kernelPackages.nvidiaPackages.stable
    
    # Video acceleration testing tools  
    libva-utils             # vainfo command
    vdpauinfo               # VDPAU info
  ];

  # Enable container GPU support
  hardware.nvidia-container-toolkit.enable = true;
  
  # Enable NVIDIA support in Podman
  virtualisation.podman.enableNvidia = true;  
  # Hardware acceleration optimizations
  # GPU cache and monitoring directories now created by modules/filesystem/system-directories.nix

  # GPU monitoring service
  systemd.services.gpu-monitor = {
    description = "GPU utilization monitoring";
    serviceConfig = {
      Type = "simple";
      User = "eric";
      ExecStart = pkgs.writeShellScript "gpu-monitor" ''
        #!/bin/bash
        while true; do
		    ${config.boot.kernelPackages.nvidiaPackages.stable}/bin/nvidia-smi --query-gpu=timestamp,name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total --format=csv,noheader,nounits >> /var/log/gpu-stats/gpu-usage.log          
		    sleep 60
        done
      '';
      Restart = "always";
      RestartSec = "10";
    };
    # Don't auto-start - enable manually when needed for monitoring
    wantedBy = [ ];
  };

  # Kernel module options for optimal server performance
  boot.extraModprobeConfig = ''
    # NVIDIA optimizations for server workloads
    options nvidia NVreg_DeviceFileUID=0 NVreg_DeviceFileGID=44 NVreg_DeviceFileMode=0660
    options nvidia NVreg_ModifyDeviceFiles=1
    
    # Persistence mode for consistent performance
    options nvidia NVreg_RegistryDwords="PerfLevelSrc=0x2222"
  '';
}
