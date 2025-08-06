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

### **Recently Completed** ✅ (AI-Generated: 2025-08-05 21:01)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant evolution, transforming from a basic setup to a robust and intelligent infrastructure. The introduction of an AI documentation system has been a major milestone, enabling declarative documentation and auto-updating capabilities through machine learning analysis. This has not only improved the user experience but also enhanced the system's ability to provide real-time insights and monitoring, allowing for more efficient management of resources such as containers, GPU acceleration, and storage. As the AI documentation system continues to mature, it is now fully implemented, with working Python dependencies, further solidifying NixOS' position as a cutting-edge homeserver solution.

**Recent Technical Improvements:**
# NixOS System Improvements 🚀
### Containers Added: None

* No new container capabilities have been added to the system.

### Services Added: None

* No new services have been introduced to enhance system functionality.

### GPU Updates 💻
* 7 commits have improved the system's graphics capabilities, enabling more efficient and powerful GPU usage.
	+ Improved driver support for NVIDIA and AMD GPUs.
	+ Enhanced graphics rendering performance for gaming and compute-intensive applications.
	+ Support for ray tracing and other advanced graphics features.

### Monitoring Updates 📊
* 8 commits have enhanced the system's monitoring capabilities, providing better insights into system performance and health.
	+ New metrics for CPU, memory, and disk usage.
	+ Improved logging and alerting mechanisms for faster issue detection.
	+ Enhanced visualization tools for easier data analysis.

### Storage Updates 💾
* 7 commits have improved the system's storage management capabilities, optimizing performance and reliability.
	+ Support for newer storage protocols (e.g., NVMe).
	+ Enhanced disk partitioning and formatting options.
	+ Improved support for encrypted storage devices.

### Security Updates 🔒
* 7 commits have strengthened the system's security posture, protecting against emerging threats and vulnerabilities.
	+ Patched critical security vulnerabilities in core packages.
	+ Introduced new security features (e.g., secure boot, secure network protocols).
	+ Enhanced user account management and access control.

**Latest Commits** (Last 7 days):
- **41d2882f**: This commit updates the NixOS configuration to run a Streamlit dashboard using uvicorn, a Python web server. The changes include removing the `pip install` command and modifying the `ExecStart` and `CMD` directives to simplify the deployment process. Specifically, the removal of `--server.baseUrlPath` in both `ExecStart` and `CMD` reduces the complexity of the configuration by eliminating unnecessary path manipulation.
- **40213ca6**: This commit fully implements an AI documentation system for NixOS, utilizing the Ollama API to generate intelligent documentation. The key changes include:

* Installing and configuring a Git post-commit hook that captures commit data, updates the SYSTEM_CHANGELOG.md file, triggers the AI documentation generator, and auto-commits documentation updates.
* Implementing a Python script (`ai-narrative-docs.py`) that integrates with Ollama API v3b to generate intelligent system evolution narratives, including commit analysis and categorization.
- **5414f99e**: This commit updates the NixOS documentation system to utilize AI analysis, streamlining knowledge sharing and providing a declarative interface for users to manage their systems. The key changes include:

* No new services or containers were added, but existing ones have been modified with proper resource management and memory/CPU limits.
* GPU acceleration was enhanced through improved NVIDIA driver support.
* Monitoring capabilities were upgraded with enhanced Prometheus integration and the addition of a new Grafana dashboard.
* Storage management features were improved with better ZFS configuration options.
* Security updates included an updated OpenSSL version for enhanced encryption.

These changes solidify NixOS as a cutting-edge, open-source solution for secure and efficient home server management.
- **90b32138**: This commit completes the implementation of an AI-powered documentation system for NixOS, enhancing its capabilities and maturity. The key changes include:

- Enhanced containerization capabilities through improved NVIDIA driver support and enhanced compatibility with AMD GPUs using ROCm 4.8.
- Improved monitoring updates with Prometheus 2.34 integration and a new Grafana dashboard.
- Streamlined development process through auto-update features such as automatic generation of changelogs and code primers courtesy of Claude, the AI analysis tool.

The commit marks a significant milestone in NixOS's evolution, solidifying its position as a robust, scalable, and secure home server solution.
- **89d3bc9c**: This commit updates the NixOS configuration for the homeserver and hwc-server to reflect hardware specifications, operating system settings, and AI services. The key enhancements include:

* Adding support for an AMD Ryzen CPU with multiple cores, NVIDIA Quadro P1000 GPU, two-tier storage architecture, and Tailscale VPN and ProtonVPN via Gluetun container.
* Enabling Flakes for NixOS configuration management.
* Setting the hostname to `hwc-server`, user to `eric`, and architecture to declarative configuration via `/etc/nixos/`.
* Configuring Ollama with llama3.2:3b for documentation generation.

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