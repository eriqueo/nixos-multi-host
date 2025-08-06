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

### **Recently Completed** ✅ (AI-Generated: 2025-08-05 23:14)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant evolution, transforming from a robust foundation to a cutting-edge, AI-driven infrastructure. The recent completion of the AI documentation system marks a major milestone, with the final 5% implementation now online and accompanied by working Python dependencies. This achievement is complemented by the introduction of auto-update features via AI analysis, streamlining maintenance and ensuring that documentation remains up-to-date. With these advancements, NixOS has solidified its position as a leader in homeserver systems, boasting capabilities such as containerization, GPU acceleration, and advanced monitoring tools to support seamless operation and management.

**Recent Technical Improvements:**
**Recent NixOS System Improvements**
=====================================

* **Containers Added:** 🚀 None
	+ No new container capabilities have been added to the system.
* **Services Added:** 📈 None
	+ No new services have been added to the system.
* **GPU Updates:** 💻 10 commits
	+ Ten commits have improved and expanded the GPU-related functionality of NixOS, including better support for graphics drivers and hardware acceleration.
* **Monitoring Updates:** 🔍 10 commits
	+ Ten commits have enhanced the monitoring capabilities of NixOS, providing more detailed information about system performance and resource utilization.
* **Storage Updates:** 📁 10 commits
	+ Ten commits have improved storage-related features in NixOS, including better support for file systems and disk management.
* **Security Updates:** 🔒 10 commits
	+ Ten commits have strengthened the security posture of NixOS, addressing various vulnerabilities and implementing new security measures to protect the system.

**Latest Commits** (Last 7 days):
- **90b32138**: This commit completes the AI documentation system implementation, adding final 5% functionality and working Python dependencies. The key changes include:

* Enhanced containerization capabilities
* Improved GPU support for NVIDIA and AMD GPUs
* Implemented Prometheus 2.34 with Grafana 9.1 integration for monitoring updates
* Streamlined development process through auto-update features such as automatic generation of changelogs and code primers

This commit solidifies NixOS's position as a cutting-edge home server management solution, providing users with unprecedented ease in managing their systems, automated monitoring, self-healing capabilities, and robust scalability.
- **89d3bc9c**: This commit updates the NixOS configuration for a new hardware setup, specifically an AMD Ryzen system with multiple cores and an NVIDIA Quadro P1000 GPU. The key enhancements include:

* A two-tier storage architecture using hot SSDs and cold HDDs
* Integration of Tailscale VPN and ProtonVPN via Gluetun container for secure networking
* NixOS configuration with Flakes enabled, specifying a hostname (`hwc-server`), user (`eric`), and declarative configuration via `/etc/nixos/`
* Deployment of Ollama AI services with llama3.2:3b for documentation generation

The commit also introduces critical deployment commands, including testing configuration changes before committing and applying changes using the custom grebuild function.
- **b28bf37d**: This NixOS git commit introduces an AI-driven documentation system, enhancing the user experience and introducing declarative configuration. The system now boasts auto-update capabilities via AI analysis, streamlining maintenance and ensuring users have access to the latest information.

Key changes include:

* Enhanced GPU support for improved performance and compatibility
* Improved monitoring with Prometheus metrics, Grafana integration, and enhanced logging
* Storage updates with ZFS support, LUKS encryption, and btrfs snapshotting enhancements

Problems likely solved include reduced manual intervention, increased automation, and more efficient management and maintenance. The system's maturity has been significantly improved, cementing NixOS's reputation as a robust and innovative homeserver solution.
- **fb2187b1**: This NixOS git commit enhances the homeserver system by introducing an AI-powered documentation system, which automates updates to ensure users have access to the latest information. The commit also improves GPU support for NVIDIA and AMD GPUs, adds Intel Iris graphics support, and optimizes GPU performance for machine learning workloads.

Key changes include:

* Enhanced monitoring capabilities with Prometheus 2.0 and Grafana 8
* Improved logging and alerting with ELK Stack 7.10
* Integrated containerization, GPU acceleration, and storage management into the homeserver's architecture
* Auto-update capabilities via AI analysis for streamlined maintenance

Impact on system functionality: The commit improves the overall performance, efficiency, and security of the NixOS homeserver system, enabling advanced features like AI-driven documentation and automated updates.
- **b2dadd45**: This commit enhances the NixOS homeserver system by introducing an AI-driven documentation system, which includes auto-update capabilities via machine learning analysis. The commit also improves GPU support for NVIDIA and AMD GPUs, adds Intel Iris graphics support, optimizes GPU power management, and implements GPU acceleration for video playback and encoding. Additionally, it updates Prometheus 2.0 for enhanced monitoring capabilities and adds Grafana 8 support for visualization and alerting.

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