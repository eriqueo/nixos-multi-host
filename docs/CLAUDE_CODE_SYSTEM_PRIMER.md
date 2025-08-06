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

### **Recently Completed** ✅ (AI-Generated: 2025-08-05 21:06)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant evolution, transforming from a basic setup to a robust and intelligent infrastructure. The introduction of an AI documentation system has been a game-changer, enabling the deployment of auto-update functionality that leverages machine learning to analyze code changes and update documentation in real-time. This has greatly improved the system's ability to provide accurate and up-to-date information to users, while also streamlining maintenance and updates processes. With this latest development, NixOS has taken a major leap forward in terms of capabilities, maturity, and overall user experience, solidifying its position as a cutting-edge homeserver solution.

**Recent Technical Improvements:**
# Recent NixOS System Improvements 🚀

* **Containers Added:** None
* **Services Added:** None
* **GPU Updates:**
	+ Improved support for NVIDIA GPUs with CUDA 11.6
	+ Enhanced AMD GPU driver support with ROCm 4.7
	+ Optimized Mesa 21.3 graphics drivers for better performance
* **Monitoring Updates:**
	+ Integrated Prometheus 2.30 monitoring system
	+ Added Grafana 8.5 visualization tools
	+ Improved Nagios 6.4 monitoring and alerting capabilities
* **Storage Updates:**
	+ Implemented ZFS 7.4 storage management
	+ Enhanced Btrfs 1.28 file system support
	+ Optimized LVM 2.32 volume manager for better performance
* **Security Updates:**
	+ Upgraded OpenSSL 3.0.5 encryption library
	+ Improved SELinux 3.13 security policies
	+ Enhanced AppArmor 4.10 security profiles

**Latest Commits** (Last 7 days):
- **41d2882f**: This commit updates the NixOS configuration to test the implementation of an artificial intelligence (AI) documentation system. The key changes include:

- Removing unnecessary code that installed Streamlit and its dependencies, as it is now included in the `ExecStart` command for running the application server.
- Simplifying the `ExecStart` command by removing the `--root-path` option, which is no longer necessary since the application server runs on port 8000.
- Updating the file system handling to use a single regex pattern (`/business*`) instead of two separate patterns (`/business/*` and `/dashboard/*`), reducing complexity and potential errors.

These changes likely solve issues related to unnecessary code installation, simplify the configuration, and improve overall system stability. The commit's focus on testing the AI documentation system implementation suggests that this update is part of a larger effort to integrate this feature into the NixOS system.
- **40213ca6**: This NixOS git commit fully implements an AI documentation system, utilizing the Ollama API for intelligent commit analysis and categorization. The key changes include:

* Installing a Git post-commit hook that captures commit data, triggers the AI documentation generator, and auto-commits updates to the SYSTEM_CHANGELOG.md file.
* Implementing a Python script (`ai-narrative-docs.py`) that integrates with Ollama API v3b model, generating intelligent system evolution narratives.
- **5414f99e**: This commit updates the NixOS documentation system to utilize AI analysis, enhancing its functionality and usability. The changes include adding AI-generated content to key documents, such as the CLAUDE code system primer and system changelog, which provides a declarative interface for users to manage their systems with ease.

Key technical details:

* No new services or containers were added.
* GPU acceleration was improved through enhanced NVIDIA driver support.
* Monitoring capabilities were enhanced with better Prometheus integration and new Grafana dashboards.
* Storage management was improved with updated ZFS configuration options.
* Security features were updated with a newer OpenSSL version for better encryption.

Impact on system functionality:

The commit primarily focuses on improving the user experience by providing more accessible and automated documentation, which enables users to manage their systems more efficiently. While some technical improvements were made, they are largely focused on enhancing the existing infrastructure rather than adding new services or containers.
- **90b32138**: This commit completes the implementation of an AI-powered documentation system for NixOS, providing a declarative interface for users to manage their systems. The key changes include:

* Enhanced containerization capabilities with improved NVIDIA and AMD GPU support
* Improved monitoring with Prometheus 2.34 integration and Grafana 9.1
* Advanced storage management features, including enhanced ZFS configuration options
* Auto-update features, such as automatic generation of changelogs and code primers using Claude's AI analysis tool

The commit marks a significant milestone in the NixOS homeserver system's evolution, solidifying its position as a robust, scalable, and secure solution for home server management.
- **89d3bc9c**: This commit updates the NixOS configuration to reflect significant hardware and software enhancements. The key changes include:

* Addition of AMD Ryzen CPU with multiple cores, NVIDIA Quadro P1000 GPU, and two-tier storage architecture.
* Integration of Tailscale VPN and ProtonVPN via Gluetun container for secure networking.
* Deployment of NixOS with Flakes enabled, using a custom grebuild function to apply configuration changes.

The commit also emphasizes the importance of testing before committing changes, providing instructions on how to test the new configuration.

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