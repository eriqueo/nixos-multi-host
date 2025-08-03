# GPU Acceleration Configuration Guide for NixOS Services

## 📋 Overview

This document provides step-by-step instructions for configuring GPU acceleration across various services in your NixOS configuration. Your system currently has excellent GPU acceleration for core services (Immich, Frigate, Jellyfin, Ollama), but this guide covers optimization opportunities and ensures consistent GPU utilization.

## 🖥️ Current GPU Infrastructure

**Hardware**: NVIDIA Quadro P1000 (Pascal architecture)
**Driver**: Stable proprietary NVIDIA drivers with Container Toolkit
**Architecture**: Pascal (requires `USE_FP16 = "false"` for TensorRT workloads)

## ✅ Currently Well-Configured Services

### Immich (Photo/Video Processing)
**Status**: ✅ Excellent - Full GPU acceleration enabled
**Location**: `/etc/nixos/hosts/server/config.nix`
**Configuration**: Native NixOS service with full NVIDIA device access

### Frigate (Video Analysis/Object Detection)  
**Status**: ✅ Excellent - TensorRT optimized for Pascal
**Location**: `/etc/nixos/hosts/server/modules/surveillance.nix`
**Configuration**: Container with CDI GPU access and TensorRT optimization

### Jellyfin (Video Transcoding)
**Status**: ✅ Excellent - Hardware transcoding enabled
**Location**: `/etc/nixos/hosts/server/config.nix` 
**Configuration**: Native service with Intel + NVIDIA GPU device access

### Ollama (AI/ML Inference)
**Status**: ✅ Excellent - CUDA acceleration enabled
**Location**: `/etc/nixos/hosts/server/config.nix`
**Configuration**: Native service with CUDA acceleration

## 🔧 Services Requiring GPU Configuration Updates

### 1. Media Management Services (*arr Applications)

**Services Affected**: Radarr, Sonarr, Lidarr, Prowlarr, Soularr
**Current Status**: No GPU acceleration
**Benefit**: Thumbnail generation, video preview processing
**Location**: `/etc/nixos/hosts/server/modules/media-containers.nix`

#### Step-by-Step Configuration:

1. **Locate the container definitions** (around lines 70-200 in media-containers.nix)

2. **For each *arr service container, add GPU options**:
   ```nix
   # Add to extraOptions array
   extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions;
   
   # Add to environment variables
   environment = mediaServiceEnv // nvidiaEnv // {
     # existing environment variables
   };
   ```

3. **Enable hardware acceleration in each service's web UI**:
   - Navigate to Settings → Media Management → Video
   - Enable "Generate video previews" 
   - Set hardware acceleration to "NVIDIA NVENC"

### 2. Download Clients Enhancement

**Services Affected**: qBittorrent, SABnzbd
**Current Status**: Basic configuration without GPU
**Benefit**: Video preview generation, thumbnail creation
**Location**: `/etc/nixos/hosts/server/modules/media-containers.nix`

#### Step-by-Step Configuration:

1. **Update qBittorrent container** (around line 150):
   ```nix
   qbittorrent = {
     # existing configuration
     extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions;
     environment = mediaServiceEnv // nvidiaEnv // {
       # existing environment variables
       WEBUI_PORT = "8080";
     };
   };
   ```

2. **Update SABnzbd container** (around line 180):
   ```nix
   sabnzbd = {
     # existing configuration  
     extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions;
     environment = mediaServiceEnv // nvidiaEnv // {
       # existing environment variables
     };
   };
   ```

### 3. Business Services GPU Enhancement

**Services Affected**: Business Dashboard, Business Metrics, Media Pipeline Monitor
**Current Status**: CPU-only processing
**Benefit**: OCR processing, document analysis, chart rendering
**Location**: `/etc/nixos/hosts/server/modules/business-monitoring.nix` and `business-services.nix`

#### Step-by-Step Configuration:

1. **Locate business service containers** in respective module files

2. **Update each Python-based service**:
   ```nix
   business-dashboard = {
     image = "python:3.11-slim";
     # existing configuration
     extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions;
     environment = nvidiaEnv // {
       # existing environment variables
       NVIDIA_VISIBLE_DEVICES = "all";
       NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
     };
   };
   ```

3. **Install GPU-enabled Python packages** in container startup:
   ```bash
   # Modify cmd array to include GPU packages
   cmd = [ "sh" "-c" "pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118 && cd /app && pip install -r requirements.txt && python app.py" ];
   ```

### 4. Monitoring Services GPU Addition

**Services Affected**: Prometheus, Grafana
**Current Status**: No GPU monitoring or acceleration
**Benefit**: GPU metrics collection, accelerated dashboard rendering
**Location**: `/etc/nixos/hosts/server/modules/monitoring.nix`

#### Step-by-Step Configuration:

1. **Enable NVIDIA GPU Exporter** (currently commented out around line 136):
   ```nix
   # Uncomment and update this section:
   nvidia-gpu-exporter = {
     image = "utkuozdemir/nvidia_gpu_exporter:latest";
     autoStart = true;
     extraOptions = [
       "--network=host"
       "--device=/dev/nvidia0:/dev/nvidia0:rwm"
       "--device=/dev/nvidiactl:/dev/nvidiactl:rwm" 
       "--device=/dev/nvidia-modeset:/dev/nvidia-modeset:rwm"
       "--device=/dev/nvidia-uvm:/dev/nvidia-uvm:rwm"
       "--device=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools:rwm"
     ];
     environment = {
       NVIDIA_VISIBLE_DEVICES = "all";
       NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
     };
   };
   ```

2. **Update Prometheus scrape config** (around line 260):
   ```yaml
   # Enable GPU metrics collection
   - job_name: 'nvidia-gpu'
     static_configs:
       - targets: ['host.containers.internal:9445']
   ```

3. **Add GPU dashboard to Grafana** in `/etc/nixos/hosts/server/modules/grafana-dashboards.nix`:
   - Add NVIDIA GPU dashboard configuration
   - Include GPU temperature, utilization, memory usage metrics

## 🚀 Advanced GPU Optimizations

### 1. Container Runtime Optimization

**File**: `/etc/nixos/modules/containers/common.nix`

#### Steps:
1. **Enable NVIDIA Container Runtime globally**:
   ```nix
   # Add to extraOptions patterns
   nvidiaRuntimeOptions = [ "--runtime=nvidia" "--gpus=all" ];
   ```

2. **Create GPU resource limits**:
   ```nix
   gpuLimits = [
     "--gpus=device=0"  # Limit to specific GPU
     "--memory=4g"      # Prevent GPU memory exhaustion
   ];
   ```

### 2. Hot Storage GPU Cache Optimization

**File**: `/etc/nixos/hosts/server/modules/hot-storage.nix`

#### Steps:
1. **Create GPU-specific cache directories**:
   ```nix
   systemd.tmpfiles.rules = [
     # Add these lines
     "d /mnt/hot/cache/gpu 0755 eric users -"
     "d /mnt/hot/cache/gpu/tensorcache 0755 eric users -"
     "d /mnt/hot/cache/gpu/models 0755 eric users -"
   ];
   ```

2. **Update container volume mounts** to use GPU cache:
   ```nix
   volumes = [
     "/mnt/hot/cache/gpu:/gpu-cache"
     # existing volumes
   ];
   ```

### 3. GPU Memory Management

**File**: Any service configuration file

#### Steps:
1. **Add GPU memory limits to high-usage containers**:
   ```nix
   environment = nvidiaEnv // {
     CUDA_MPS_PIPE_DIRECTORY = "/tmp/nvidia-mps";
     CUDA_MPS_LOG_DIRECTORY = "/tmp/nvidia-log";
     NVIDIA_MPS_PIPE_DIRECTORY = "/tmp/nvidia-mps";
   };
   ```

2. **Enable CUDA Multi-Process Service** for memory sharing between containers

## 🔍 Testing and Validation

### After Each Configuration Change:

1. **Test configuration**:
   ```bash
   sudo nixos-rebuild test --flake .#$(hostname)
   ```

2. **Validate GPU access in containers**:
   ```bash
   sudo podman exec -it <container-name> nvidia-smi
   ```

3. **Check GPU utilization**:
   ```bash
   nvidia-smi
   watch -n 1 nvidia-smi
   ```

4. **Verify container GPU access**:
   ```bash
   sudo podman exec -it <container-name> bash -c "ls -la /dev/nvidia*"
   ```

### Performance Testing:

1. **Frigate**: Check object detection processing time in logs
2. **Immich**: Test photo processing and face recognition speed
3. **Jellyfin**: Monitor transcoding performance with hardware acceleration
4. **Business services**: Test document processing and OCR performance

## 🛠️ Common Patterns for GPU Enablement

### Pattern 1: Container with Full GPU Access
```nix
serviceName = {
  image = "some/image:tag";
  autoStart = true;
  extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions;
  environment = mediaServiceEnv // nvidiaEnv // {
    # service-specific environment
  };
  volumes = [
    "/mnt/hot/cache/gpu:/gpu-cache"
    # other volumes
  ];
};
```

### Pattern 2: Native Service with GPU Access
```nix
services.serviceName = {
  enable = true;
  environment = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
    LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";
  };
  # service-specific configuration
};
```

### Pattern 3: Conditional GPU Access
```nix
serviceName = {
  extraOptions = mediaNetworkOptions ++ (if config.hardware.nvidia.enable then nvidiaGpuOptions else []);
  environment = mediaServiceEnv // (if config.hardware.nvidia.enable then nvidiaEnv else {});
};
```

## 📝 Implementation Checklist

### Before Making Changes:
- [ ] Backup current configuration: `sudo cp /etc/nixos/hosts/server/modules/media-containers.nix /etc/nixos/hosts/server/modules/media-containers.nix.backup`
- [ ] Ensure GPU infrastructure is working: `nvidia-smi`
- [ ] Check current container status: `sudo podman ps`

### After Each Service Update:
- [ ] Test NixOS configuration: `sudo nixos-rebuild test --flake .#$(hostname)`
- [ ] Verify service starts successfully: `sudo systemctl status podman-<service>.service`
- [ ] Test GPU access in container: `sudo podman exec -it <service> nvidia-smi`
- [ ] Monitor GPU utilization during service operation: `watch -n 1 nvidia-smi`

### Final Validation:
- [ ] All services running with GPU access
- [ ] GPU memory properly shared between services
- [ ] Performance improvements visible in service logs
- [ ] Hot storage cache directories created and used
- [ ] Monitoring shows GPU utilization metrics

## 🚨 Important Notes

### Pascal Architecture Considerations:
- Always set `USE_FP16 = "false"` for TensorRT workloads
- Memory bandwidth is limited compared to newer GPUs
- CUDA compute capability is 6.1

### Resource Management:
- P1000 has 4GB VRAM - monitor memory usage carefully
- Limit concurrent GPU workloads to prevent memory exhaustion
- Use hot storage for GPU cache to reduce processing time

### Service Priority:
1. **Critical GPU services**: Frigate, Immich (already optimized)
2. **High-benefit services**: *arr applications, Jellyfin transcoding
3. **Optional GPU services**: Download clients, business tools

## 🔄 Rollback Instructions

If any configuration causes issues:

1. **Restore backup**:
   ```bash
   sudo cp /etc/nixos/hosts/server/modules/<service>.nix.backup /etc/nixos/hosts/server/modules/<service>.nix
   ```

2. **Rebuild system**:
   ```bash
   grebuild "Rollback GPU configuration changes"
   ```

3. **Restart affected services**:
   ```bash
   sudo systemctl restart podman-<service>.service
   ```

This guide ensures systematic GPU acceleration deployment while maintaining system stability and proper resource management for your NVIDIA Quadro P1000.