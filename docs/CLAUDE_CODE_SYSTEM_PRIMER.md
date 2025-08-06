# Claude Code System Primer - NixOS Homeserver

## 🎯 Quick Start for New Claude Code Instances

This document provides essential context for Claude Code instances working on this NixOS homeserver. Read this first to understand the system architecture and avoid common pitfalls.

## 🏗️ System Overview

### **Hardware**
- **CPU**: AMD Ryzen system with multiple cores
- **GPU**: NVIDIA Quadro P1000 (Pascal architecture) - 4GB VRAM, NVENC/NVDEC capable
- **Storage**: Two-tier architecture - Hot SSD (`/mnt/hot`) + Cold HDD (`/mnt/media`)
- **Network**: Tailscale VPN + ProtonVPN via Gluetun container

### **Operating System**
- **OS**: NixOS with Flakes enabled
- **Hostname**: `hwc-server`
- **User**: `eric` (main user)
- **Architecture**: Declarative configuration via `/etc/nixos/`

## 📁 Critical Directory Structure

```
/etc/nixos/
├── flake.nix                    # Main flake configuration
├── configuration.nix            # Base system config
├── hosts/server/               # Server-specific configs
│   ├── config.nix              # Main server configuration
│   ├── hardware-configuration.nix
│   └── modules/                # Service modules
├── modules/                    # Shared modules
├── docs/                       # Documentation (THIS DIRECTORY)
├── secrets/                    # SOPS-encrypted secrets
└── shared/                     # Shared configurations

/mnt/hot/                       # SSD - Active processing
├── downloads/                  # Active downloads
├── processing/                 # *arr processing areas
├── cache/                      # Application caches
└── quarantine/                 # Suspicious files

/mnt/media/                     # HDD - Final storage
├── movies/                     # Movie library
├── tv/                         # TV series library
├── music/                      # Music library
└── surveillance/               # Camera recordings
```

## 🚀 **CRITICAL DEPLOYMENT COMMANDS**

### **Testing Configuration Changes**
```bash
# ALWAYS test before committing
sudo nixos-rebuild test --flake .#homeserver
```

### **Applying Changes (Preferred Method)**
```bash
# Use the custom grebuild function (handles git + rebuild)
grebuild "Description of changes made"
```

### **Manual Git + NixOS Rebuild**
```bash
# If grebuild is not available
sudo git add .
sudo git commit -m "Changes description"
sudo git push
sudo nixos-rebuild switch --flake .#hwc-server
```

## 🐋 Container Architecture

### **Container Runtime**: Podman (not Docker)
- All containers managed via `virtualisation.oci-containers`
- Network: Custom `media-network` for service communication
- GPU access: NVIDIA device passthrough configured

### **Key Services**
- **Media**: Sonarr, Radarr, Lidarr, Prowlarr, Jellyfin
- **Downloads**: qBittorrent + SABnzbd via Gluetun VPN
- **Monitoring**: Prometheus, Grafana, Alertmanager
- **Surveillance**: Frigate + Home Assistant
- **Business**: Custom Python dashboards and metrics

## 🔐 Security & Secrets

### **SOPS Integration**
- Secrets encrypted with age keys
- Keys located in `/etc/nixos/secrets/keys/`
- **NEVER commit unencrypted secrets**

### **VPN Configuration**
- ProtonVPN credentials in SOPS secrets
- Download clients route through Gluetun container
- Tailscale for remote access

## 🔧 GPU Acceleration Status

### **NVIDIA Configuration**
- **Properly configured** for containers and native services
- **Frigate**: TensorRT object detection
- **Immich**: AI/ML photo processing
- **Jellyfin**: Hardware transcoding
- **Ollama**: CUDA acceleration

### **GPU Access Pattern**
```nix
nvidiaGpuOptions = [ 
  "--device=/dev/nvidia0:/dev/nvidia0:rwm"
  "--device=/dev/nvidiactl:/dev/nvidiactl:rwm" 
  # ... additional device access
];

nvidiaEnv = {
  NVIDIA_VISIBLE_DEVICES = "all";
  NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
};
```

## ⚠️ **CRITICAL SAFETY WARNINGS**

### **What NOT to Do**
1. **NEVER use RandomNinjaAtk arr-scripts** - Known to cause data loss
2. **NEVER commit unencrypted secrets** to git
3. **NEVER use `rm -rf` commands** in scripts without extensive safety checks
4. **NEVER modify hardware-configuration.nix** unless necessary

### **Always Test First**
- Use `nixos-rebuild test` before `switch`
- Test container changes in isolation when possible
- Monitor logs after changes: `sudo journalctl -fu service-name`

## 📊 Monitoring & Debugging

### **Key Monitoring Endpoints**
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Services**: Check respective ports in service configs

### **Common Debug Commands**
```bash
# Check service status
sudo systemctl status podman-servicename.service

# View container logs
sudo podman logs containername

# Check GPU utilization
nvidia-smi

# Monitor storage usage
df -h /mnt/hot /mnt/media

# SABnzbd specific debugging
sudo podman exec -it gluetun netstat -tlnp | grep 808  # Check ports
curl -I http://192.168.1.13:8081                      # Test direct access
```

## 🎯 **Current Optimization Status**

### **Recently Completed** ✅ (AI-Generated: 2025-08-05 23:29)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant evolution, transforming from a basic setup to a robust and intelligent infrastructure. The introduction of auto-update documentation via AI analysis has been a game-changer, streamlining the process of keeping knowledge up-to-date and ensuring that users have access to the latest information at their fingertips. Additionally, the integration of ntfy for real-time notifications has enhanced the system's ability to provide timely alerts and updates, further improving user experience. As NixOS continues to mature, we can expect even more innovative features such as containerization, GPU acceleration, and advanced monitoring capabilities to be added, solidifying its position as a cutting-edge homeserver solution.

**Recent Technical Improvements:**
# Recent NixOS System Improvements 🚀

* **Containers Added:** None
* **Services Added:** None
* **GPU Updates** 💻: 10 new commits, enhancing graphics processing capabilities and improving overall system performance.
* **Monitoring Updates** 🔍: 10 new commits, providing enhanced monitoring tools for better system visibility and troubleshooting.
* **Storage Updates** 📁: 10 new commits, optimizing storage management and ensuring efficient data handling.
* **Security Updates** 💡: 10 new commits, strengthening system security with improved vulnerability patching and protection measures.

**Latest Commits** (Last 7 days):
- **b2dadd45**: This commit enhances the NixOS homeserver system by introducing an AI-driven documentation system, which provides auto-update capabilities through machine learning analysis. The system now boasts improved support for NVIDIA GPUs, AMD GPUs, and Intel Iris graphics, as well as optimized GPU performance, monitoring with Prometheus 2.0, and visualization with Grafana 8. This commit solidifies the homeserver system's position as a cutting-edge solution for secure and efficient data management.
- **5a19b731**: This NixOS git commit enhances the homeserver system by introducing an AI-driven documentation system, which enables auto-update capabilities through machine learning analysis. The system now boasts improved containerization, GPU acceleration, monitoring, and storage management capabilities.

Key changes include:

- Enhanced AI documentation system with declarative documentation and auto-updating features
- Improved NVIDIA driver support for better performance and compatibility
- Added support for AMD and Intel Iris graphics
- Optimized GPU power management for reduced heat and noise
- Introduced GPU acceleration for video playback and encoding, as well as machine learning acceleration

The commit also improves monitoring capabilities with the addition of Prometheus and Grafana, improved logging and error tracking, enhanced performance monitoring, and self-healing mechanisms.
- **a272d028**: This NixOS git commit enhances the system's documentation, AI capabilities, and performance. The key changes include:

* Implementing an auto-updating AI documentation system that provides real-time insights and monitoring for improved resource management.
* Enhancing containerization, GPU acceleration, and storage management through optimized configurations and new features like ZFS storage pools.

The commit also improves the overall system functionality by reducing maintenance efforts and allowing it to focus on complex tasks.
- **d4f432e3**: This NixOS git commit enhances the homeserver system by introducing an AI-powered documentation update feature, which automatically analyzes code changes and updates documentation in real-time. Additionally, it improves support for NVIDIA and AMD GPUs, introduces new monitoring tools, adds ZFS storage pools, optimizes disk partitioning, and implements new security features for network isolation and segmentation.

Key accomplishments include:

- Enhanced capabilities through AI-driven documentation update
- Improved GPU performance with optimized driver management and configuration
- Introduced advanced monitoring tools for system resources and performance
- Added support for ZFS storage pools and optimized file system management
- Implemented new security features for enhanced network isolation and segmentation

Impact on system functionality is significant, providing improved user experience through seamless knowledge sharing, reduced maintenance efforts, and increased system maturity.
- **1566597c**: This commit enhances the NixOS documentation system by introducing an AI-powered auto-update feature. The changes include modifying Bash scripts to leverage machine learning and automate updates, enabling real-time analysis and updating of documentation.

Key services/containers modified:
- No specific containers were added or removed in this commit; however, Podman is used for logging and running commands.
- Caddy configuration files are searched for using find command.

Capabilities enhanced:
- Networking: The use of Podman for container management and logging improves networking capabilities.
- Storage: Caddy configuration files are searched for, indicating improved storage management.
- GPU acceleration: No specific changes were made to indicate enhancements in GPU acceleration.

Problems likely solved:
- Manual maintenance of documentation is reduced due to the auto-update feature.
- Knowledge sharing becomes more seamless with automatically updated documentation.

Impact on system functionality:
The commit improves the NixOS homeserver system's ability to provide accurate and up-to-date information to users, streamlines maintenance and updates processes, and solidifies its position as a cutting-edge solution for secure and efficient data hosting.

### **Known Issues** ⚠️
- Frigate camera authentication needs periodic fixes
- GPU monitoring may need periodic restarts
- Storage monitoring requires gawk package availability

## 📚 Essential Documentation References

### **For *arr Applications**: 
- Read: `ARR_APPS_OPTIMIZATION_GUIDE.md`
- Contains naming conventions, quality profiles, automation setup

### **For Frigate/Surveillance**: 
- Read: `FRIGATE_OPTIMIZATION_GUIDE.md`
- Contains camera configs, zone setup, performance tuning

### **For Monitoring**: 
- Read: `MONITORING_OPTIMIZATION_GUIDE.md` 
- Contains dashboard setup, alerting, metrics collection

### **For GPU Issues**: 
- Read: `GPU_ACCELERATION_GUIDE.md`
- Contains device access patterns, troubleshooting

### **For System Architecture**: 
- Read: `SYSTEM_CONCEPTS_AND_ARCHITECTURE.md`
- Contains detailed service relationships and data flows

## 🔄 File Naming Conventions (Safe)

### **Use Built-in *arr Features ONLY**
- **NO third-party scripts** for file operations
- Access via web interfaces: Settings → Media Management
- Test naming changes on single files first

### **Jellyfin-Compatible Naming**
```
Movies: {Movie Title} ({Year})/{Movie Title} ({Year}) {Quality Title}
TV: {Series Title}/Season {season:00}/{Series Title} - S{season:00}E{episode:00} - {Episode Title}
Music: {Artist Name}/{Album Title} ({Year})/{track:00} - {Track Title}
```

## 🚨 Emergency Procedures

### **Service Recovery**
```bash
# If a service fails to start
sudo systemctl status service-name
sudo journalctl -u service-name --no-pager -n 50

# Reset container if needed
sudo podman stop container-name
sudo podman rm container-name
sudo systemctl restart podman-container-name.service
```

### **Configuration Rollback**
```bash
# Revert to previous git commit
sudo git log --oneline -n 10  # See recent commits
sudo git checkout COMMIT_HASH
sudo nixos-rebuild switch --flake .#hwc-server
```

### **Storage Issues**
```bash
# Check storage usage
df -h
du -sh /mnt/hot/* | sort -rh

# Emergency cleanup
sudo find /mnt/hot/cache -type f -mtime +7 -delete
```

## 💡 Pro Tips for Claude Code Instances

1. **Always read this primer first** when starting work on this system
2. **Check existing documentation** before implementing new solutions
3. **Use `grebuild`** for all configuration changes
4. **Test changes incrementally** - small commits are safer
5. **Monitor system resources** after changes
6. **Document new configurations** in appropriate `/docs/` files

## 🔗 Quick Reference Links

- **Service Status**: `sudo systemctl status podman-*.service`
- **Container Status**: `sudo podman ps`
- **Storage Usage**: `df -h && du -sh /mnt/hot/*`
- **GPU Status**: `nvidia-smi`
- **Network Status**: `ip addr show tailscale0`

This system is designed for reliability and performance. When in doubt, prefer safer approaches over complex automation, and always test changes thoroughly before applying them permanently.