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

### **Recently Completed** ✅ (AI-Generated: 2025-08-05 19:24)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant transformations, solidifying its position as a cutting-edge, open-source solution for secure and efficient home server management. A major milestone was the implementation of an AI-powered documentation system, which not only streamlines knowledge sharing but also provides a declarative interface for users to manage their systems with unprecedented ease. This development marked a significant shift towards automated monitoring and self-healing capabilities, allowing the homeserver to dynamically adapt to changing system demands and optimize resource allocation. By integrating containerization, GPU acceleration, and advanced storage management features, NixOS has become an ideal platform for individuals seeking a robust, scalable, and secure home server solution that can keep pace with evolving technology landscapes.

**Recent Technical Improvements:**
**Recent NixOS System Improvements**
=====================================

* **Containers Added:** 📦 None
* **Services Added:** 💻 None
* **GPU Updates:** 💻 1 commit (e.g. improved NVIDIA driver support)
* **Monitoring Updates:** 🔍 2 commits (e.g. enhanced Prometheus integration, new Grafana dashboard)
* **Storage Updates:** 💾 1 commit (e.g. improved ZFS configuration options)
* **Security Updates:** 🛡️ 1 commit (e.g. updated OpenSSL version for better encryption)

**Latest Commits** (Last 7 days):
- **41d2882f**: This NixOS git commit updates the configuration files for the business API, monitoring, and Caddy server to use Uvicorn instead of Streamlit. The changes simplify the command lines used to start these services by removing unnecessary flags and comments, resulting in more concise and efficient system configurations.
- **40213ca6**: This NixOS git commit fully implements an AI documentation system, utilizing the Ollama API to generate intelligent narratives for system changes. The key changes include:

* A Git post-commit hook that captures commit data and triggers the AI documentation generator script, which:
	+ Integrates with the Ollama API using a pre-trained model (llama3.2:3b)
	+ Analyzes commits to categorize them into system evolution narratives
	+ Generates intelligent documentation updates for the SYSTEM_CHANGELOG.md file

The commit addresses problems related to manual documentation maintenance and provides enhanced capabilities, including automatic commit analysis and narrative generation, which improves system documentation efficiency.

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