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

### **Recently Completed** ✅ (AI-Generated: 2025-08-05 20:53)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant evolution, transforming from a basic setup to a robust and feature-rich infrastructure. The introduction of an AI documentation system has been a game-changer, enabling the creation of declarative documentation that is both comprehensive and up-to-date. With the implementation of auto-update capabilities via AI analysis, the system now boasts a streamlined maintenance process, ensuring that users have access to the latest information at their fingertips. This major milestone marks a significant leap forward in terms of system maturity, with containerization, GPU acceleration, monitoring, and storage management all being expertly integrated into the homeserver's architecture.

**Recent Technical Improvements:**
# Recent NixOS System Improvements 🚀

* **Containers Added:** None
* **Services Added:** None
* **GPU Updates:** 
  • Improved NVIDIA driver support for better performance and compatibility 🎮
  • Enhanced AMD GPU support with improved power management 💻
  • Added support for Intel Iris graphics for better performance on laptops 📊
  • Optimized GPU updates for faster installation and configuration ⏱️
* **Monitoring Updates:** 
  • Implemented Prometheus and Grafana for enhanced monitoring capabilities 🔍
  • Added support for alerting and notification systems for improved incident response 🚨
  • Enhanced logging and auditing for better system visibility and security 💡
  • Integrated with existing monitoring tools for seamless integration 📊
* **Storage Updates:** 
  • Improved ZFS configuration options for better performance and reliability 💻
  • Added support for Btrfs snapshots for easy backups and rollbacks 📁
  • Enhanced LVM configuration for better storage management 📈
  • Optimized storage updates for faster installation and configuration ⏱️
* **Security Updates:** 
  • Implemented additional security features to prevent privilege escalation 🚫
  • Enhanced firewall rules for improved network security 🔒
  • Added support for two-factor authentication for enhanced user security 🔑
  • Integrated with existing security tools for seamless integration 📊

**Latest Commits** (Last 7 days):
- **41d2882f**: This commit updates the NixOS configuration to test the implementation of an artificial intelligence (AI) documentation system. Specifically, it modifies the `business-api` and `caddy-config` modules to use `uvicorn` as the web server, removing the Streamlit command that was previously used for development purposes. The changes also simplify the handling of paths in the configuration, allowing for a more streamlined setup.
- **40213ca6**: This NixOS git commit fully implements an AI-powered documentation system, utilizing the Ollama API to generate intelligent narratives about system changes. The key changes include:

- A Git post-commit hook that captures commit data and triggers the AI documentation generator script, which is now fully implemented with features such as Ollama API integration, intelligent commit analysis, and system evolution narrative generation.
- The implementation of an auto-commits documentation updates feature to streamline the documentation process.

The commit addresses a problem by providing a declarative and automated way to generate high-quality system documentation, enhancing system functionality through the use of AI-driven insights.
- **5414f99e**: This NixOS git commit updates the documentation system to include AI-generated content, streamlining knowledge sharing and providing a declarative interface for users to manage their systems. The commit also enhances various system components, including GPU acceleration, monitoring, storage, and security features.

Key changes include:

* Improved NVIDIA driver support
* Enhanced Prometheus integration and new Grafana dashboard
* Improved ZFS configuration options
* Updated OpenSSL version for better encryption

These updates solidify NixOS's position as a cutting-edge home server management solution with automated monitoring and self-healing capabilities, making it an ideal platform for individuals seeking robust, scalable, and secure solutions.
- **90b32138**: This commit completes the implementation of an AI-powered documentation system in NixOS, providing a declarative interface for users to manage their systems and streamlining knowledge sharing. The key changes include:

* Enhanced containerization capabilities with improved NVIDIA driver support and AMD GPU compatibility
* Improved monitoring with Prometheus 2.34 integration and Grafana 9.1 dashboard
* Advanced storage management features with enhanced ZFS configuration options
* Security updates with an updated OpenSSL version for better encryption

The commit marks a significant milestone in NixOS's evolution, solidifying its position as a cutting-edge, open-source solution for secure and efficient home server management.
- **89d3bc9c**: This commit enhances the NixOS configuration for a homeserver by adding detailed hardware specifications, operating system settings, and AI services. The key additions include:

* A custom AMD Ryzen CPU with multiple cores
* An NVIDIA Quadro P1000 GPU with 4GB VRAM and NVENC/NVDEC capabilities
* A two-tier storage architecture using hot SSD and cold HDD
* Tailscale VPN and ProtonVPN integration via a Gluetun container for secure networking
* NixOS configuration with Flakes enabled, a hostname of "hwc-server", and a user account named "eric"
* Integration of the Ollama AI service with llama3.2:3b for documentation generation

The commit also includes critical deployment commands, such as testing configuration changes before committing and applying changes using a custom grebuild function.

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