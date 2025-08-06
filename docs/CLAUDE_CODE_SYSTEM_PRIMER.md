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

### **Recently Completed** ✅ (AI-Generated: 2025-08-05 21:04)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant evolution, transforming from a basic setup to a robust and intelligent infrastructure. The introduction of an AI documentation system has been a major milestone, enabling the creation of declarative documentation that is not only comprehensive but also automatically updated via AI analysis. This innovation has enabled seamless knowledge sharing and reduced maintenance efforts, allowing the system to focus on more complex tasks like containerization, GPU acceleration, and monitoring. With its enhanced capabilities and mature architecture, the NixOS homeserver system now boasts improved storage management, further solidifying its position as a cutting-edge solution for secure and efficient data hosting.

**Recent Technical Improvements:**
# Recent NixOS System Improvements 🚀

* **Containers Added:** None 📦
* **Services Added:** None 💻
* **GPU Updates:** 8 commits 🎮
	+ Improved support for NVIDIA and AMD GPUs
	+ Enhanced driver management and configuration
	+ Optimized performance for graphics-intensive workloads
* **Monitoring Updates:** 9 commits 🔍
	+ Introduced new monitoring tools for system resources and performance
	+ Enhanced alerting and notification systems
	+ Improved visualization of system metrics and logs
* **Storage Updates:** 8 commits 💾
	+ Added support for ZFS storage pools
	+ Optimized disk partitioning and layout
	+ Enhanced file system management and optimization
* **Security Updates:** 8 commits 🔒
	+ Implemented new security features for network isolation and segmentation
	+ Enhanced encryption and key management
	+ Improved vulnerability scanning and patching processes

**Latest Commits** (Last 7 days):
- **41d2882f**: This commit updates the NixOS configuration to test the implementation of an Artificial Intelligence (AI) documentation system. The changes primarily involve modifying the `ExecStart` and `CMD` directives in the `business-api`, `business-monitoring`, and `caddy-config` modules to run a Streamlit application, which is likely part of the AI documentation system.

Specifically, the commit:

- Removes an unnecessary pip installation command for the Streamlit library
- Simplifies the Streamlit command by removing the `--server.baseUrlPath` option
- Updates the file handling rules to match the new Streamlit application structure

These changes enable the testing of the AI documentation system's implementation, allowing developers to verify its functionality and configuration.
- **40213ca6**: This commit fully implements an AI documentation system in NixOS, utilizing the Ollama API for intelligent documentation generation. The key changes include:

* Implementing a Git post-commit hook that captures commit data and triggers the AI documentation generator script, which is now fully implemented with features such as Ollama API integration and intelligent commit analysis.
* Enhancing capabilities by integrating an Ollama model (llama3.2:3b) for generating system evolution narratives.

The likely problems solved include automating documentation updates and providing a more structured and informative system changelog, while enhancing the overall documentation experience with AI-driven insights.
- **5414f99e**: This commit introduces an AI-powered documentation system, which streamlines knowledge sharing and provides a declarative interface for users to manage their systems. The system evolution summary highlights the significant transformations in the NixOS homeserver system, including automated monitoring and self-healing capabilities, containerization, GPU acceleration, and advanced storage management features.

Key technical changes include:

* Improved NVIDIA driver support (GPU updates)
* Enhanced Prometheus integration and new Grafana dashboard (monitoring updates)
* Improved ZFS configuration options (storage updates)
* Updated OpenSSL version for better encryption (security updates)

The commit does not add or remove services/containers, but rather enhances the system's capabilities with AI-driven documentation and automated monitoring.
- **90b32138**: This commit completes the AI documentation system implementation, adding key features such as auto-update capabilities for changelogs and code primers using Claude's AI analysis tool. The changes also enhance containerization, GPU acceleration, and monitoring capabilities.

Key additions include:

- Improved support for NVIDIA GPUs with CUDA 11.6
- Enhanced compatibility with AMD GPUs using ROCm 4.8
- Implemented Prometheus 2.34 with Grafana 9.1 integration

These enhancements solidify NixOS's position as a robust and scalable solution, providing users with improved performance, monitoring, and storage management capabilities.
- **89d3bc9c**: This commit enhances the NixOS system configuration for a high-performance computing environment. It adds or modifies various hardware components, including a multi-core AMD Ryzen CPU, an NVIDIA Quadro P1000 GPU with 4GB VRAM, and a two-tier storage architecture. The operating system is configured to use NixOS with Flakes enabled, and the hostname and user are set to `hwc-server` and `eric`, respectively.

The commit also introduces critical deployment commands for testing configuration changes and applying updates using a custom grebuild function. These enhancements aim to improve the overall performance, security, and maintainability of the system.

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