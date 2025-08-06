# 🎯 Claude Code System Context - NixOS Homeserver

**READ THIS FIRST** - Essential context for understanding this NixOS homeserver configuration.

## ⚡ Quick Start Checklist
- [ ] **Hardware**: AMD Ryzen + NVIDIA Quadro P1000 + Hot SSD + Cold HDD
- [ ] **Deploy Method**: Use `grebuild "commit message"` (handles git + rebuild automatically)
- [ ] **Test First**: Always `sudo nixos-rebuild test --flake .#hwc-server` before committing
- [ ] **GPU Enabled**: Services have NVIDIA acceleration (Frigate, Immich, Jellyfin, *arr apps)

## 🏗️ System Architecture

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

### **Storage Tiers**
- **`/mnt/hot`** (SSD): Active downloads, processing, cache
- **`/mnt/media`** (HDD): Final media library storage
- **Automated migration**: Hot → Cold via systemd services

### **Container Stack** (Podman)
- **Media Management**: Sonarr, Radarr, Lidarr, Prowlarr (GPU-accelerated thumbnails)
- **Media Streaming**: Jellyfin (native with GPU transcoding), Navidrome, Immich (native with GPU AI/ML)
- **Downloads**: qBittorrent + SABnzbd via Gluetun VPN isolation
- **Surveillance**: Frigate (TensorRT object detection) + Home Assistant integration
- **Monitoring**: Prometheus + Grafana + GPU metrics + custom storage monitoring
- **AI Services**: Ollama with llama3.2:3b (CUDA acceleration) for documentation generation
- **Business Intelligence**: Custom Python dashboards with GPU acceleration and analytics

### **Security & Network**
- **SOPS**: Age-encrypted secrets in `/etc/nixos/secrets/` with file-level permissions
- **VPN**: ProtonVPN (downloads only) via Gluetun, Tailscale mesh for remote access
- **Network**: Custom `media-network` for inter-service communication, container isolation
- **Firewall**: Interface-specific rules (tailscale0, local LAN)
- **Authentication**: Basic auth for internal services, reverse proxy planned

## 🚨 **CRITICAL DEPLOYMENT COMMANDS**

### **Testing Configuration Changes**
```bash
# ALWAYS test before committing
sudo nixos-rebuild test --flake .#hwc-server
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

## 🚨 Critical Safety Rules

### **NEVER**
- ❌ Use RandomNinjaAtk arr-scripts (causes data loss)
- ❌ Commit unencrypted secrets to git
- ❌ Use `rm -rf` without extensive safety checks
- ❌ Modify `hardware-configuration.nix` unnecessarily

### **ALWAYS**
- ✅ Test with `nixos-rebuild test` before committing
- ✅ Use `grebuild "message"` for configuration changes
- ✅ Check logs after changes: `sudo journalctl -fu service`
- ✅ Document changes in `/etc/nixos/docs/`

## 🤖 AI Documentation System

### **Recently Implemented** ✅
The system now includes an intelligent AI documentation generator that:
- Analyzes git commits automatically via post-commit hooks
- Uses local Ollama with llama3.2:3b model for AI processing
- Generates system evolution narratives and technical summaries
- Updates documentation files automatically after each commit

### **Key AI Components**
- **Git Hook**: `/etc/nixos/.git/hooks/post-commit` - Triggers AI analysis
- **AI Script**: `/etc/nixos/scripts/ai-narrative-docs.py` - Main AI processing
- **Wrapper**: `/etc/nixos/scripts/ai-docs-wrapper.sh` - Python environment
- **Service**: `ollama.service` - Local AI model server

## 📚 Essential Documentation

| Topic | File | Purpose |
|-------|------|---------|
| **System Overview** | `docs/CLAUDE_CODE_SYSTEM_PRIMER.md` | Complete system context |
| **AI Documentation** | `docs/AI_DOCUMENTATION_SYSTEM_HOWTO.md` | AI system usage and troubleshooting |
| **Media Management** | `docs/ARR_APPS_OPTIMIZATION_GUIDE.md` | *arr apps, naming, automation |
| **Surveillance** | `docs/FRIGATE_OPTIMIZATION_GUIDE.md` | Camera config, object detection |
| **Monitoring** | `docs/MONITORING_OPTIMIZATION_GUIDE.md` | Grafana, Prometheus, alerting |
| **GPU Acceleration** | `docs/GPU_ACCELERATION_GUIDE.md` | NVIDIA setup, troubleshooting |
| **Architecture** | `docs/SYSTEM_CONCEPTS_AND_ARCHITECTURE.md` | Service relationships |
| **Troubleshooting** | `docs/TROUBLESHOOTING_UPDATED.md` | Common issues, solutions |

## 🎮 GPU Acceleration Framework

### **NVIDIA Quadro P1000 Configuration**
- **Architecture**: Pascal (Compute Capability 6.1) with 4GB VRAM
- **Capabilities**: CUDA compute, NVENC/NVDEC hardware encoding, limited AV1 support
- **Shared Access**: Multiple services with proper isolation and resource management

### **Service GPU Utilization Matrix**
| Service | GPU Usage | Primary Benefit |
|---------|-----------|-----------------|
| **Frigate** | TensorRT object detection | Real-time video analysis |
| **Immich** | Face recognition, ML processing | Photo organization |
| **Jellyfin** | Hardware transcoding (NVENC/NVDEC) | Video streaming |
| **Ollama** | CUDA inference | Local AI processing |
| ***arr apps** | Thumbnail generation | Media preview |
| **Download clients** | Video processing | Preview generation |

### **GPU Device Access Pattern**
```nix
nvidiaGpuOptions = [ 
  "--device=/dev/nvidia0:/dev/nvidia0:rwm"
  "--device=/dev/nvidiactl:/dev/nvidiactl:rwm" 
  "--device=/dev/nvidia-modeset:/dev/nvidia-modeset:rwm"
  "--device=/dev/nvidia-uvm:/dev/nvidia-uvm:rwm"
  "--device=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools:rwm"
  "--device=/dev/dri:/dev/dri:rwm"
];

nvidiaEnv = {
  NVIDIA_VISIBLE_DEVICES = "all";
  NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
};
```

### **Pascal Architecture Considerations**
- **TensorRT**: Requires `USE_FP16 = "false"` for model generation on Pascal
- **Memory Management**: 4GB VRAM requires careful resource allocation between services
- **Codec Support**: Full H.264/H.265 encoding support, limited AV1 decode capability

## 🔧 Quick Commands

```bash
# System Status
sudo systemctl status podman-*.service  # Check all containers
sudo podman ps                          # Running containers
nvidia-smi                              # GPU status
df -h /mnt/hot /mnt/media               # Storage usage

# AI System Status
systemctl status ollama                 # Check AI service
ollama list                            # Available AI models
tail /etc/nixos/docs/ai-doc-generation.log  # AI processing logs

# Monitoring & Metrics
curl http://localhost:3000              # Grafana dashboard
curl http://localhost:9090              # Prometheus metrics
nvidia-smi -q                          # Detailed GPU info
sudo podman stats                       # Container resource usage

# Deploy Changes
grebuild "Descriptive commit message"   # Preferred method (includes AI docs)
# OR manually:
sudo nixos-rebuild test --flake .#hwc-server
sudo nixos-rebuild switch --flake .#hwc-server

# Debugging
sudo journalctl -fu podman-servicename.service
sudo podman logs containername
sudo journalctl -fu ollama              # AI service logs
```

## 🎯 Current System State

### **Recently Optimized** ✅ (AI-Generated: 2025-08-05 19:37)

**System Evolution Summary:**
The NixOS homeserver system has undergone significant transformations, solidifying its position as a cutting-edge, self-sustaining infrastructure. A major milestone was the implementation of an AI-driven documentation system, which not only enhanced the user experience but also introduced declarative configuration and automated updates via AI analysis. This marked a significant shift towards increased automation and reduced manual intervention, allowing for more efficient management and maintenance. The completion of the final 5% implementation has brought the AI documentation system to full maturity, further cementing NixOS's reputation as a robust and innovative homeserver solution.

### **Active Services**
- **Media Pipeline**: All *arr apps + Jellyfin with GPU transcoding
- **Downloads**: VPN-protected via Gluetun + ProtonVPN
- **Monitoring**: Grafana dashboards operational
- **Surveillance**: 4 cameras with Frigate object detection
- **AI Documentation**: Ollama with llama3.2:3b model for intelligent docs
- **Business Tools**: Custom metrics and dashboards

### **Known Issues** ⚠️
- Some Frigate cameras may need periodic authentication fixes
- Storage monitoring requires proper gawk package paths
- GPU monitoring may need occasional restarts

## 📊 Monitoring & Observability Architecture

### **Metrics Collection**
- **Core Metrics**: Node Exporter for system metrics (CPU, memory, disk, network)
- **Container Metrics**: cAdvisor for container resource usage and performance
- **GPU Metrics**: NVIDIA GPU Exporter for GPU utilization, temperature, memory
- **Application Metrics**: Custom exporters for media pipeline health and status
- **Storage Metrics**: Custom scripts for hot/cold storage monitoring and alerts

### **Dashboard Organization**
1. **System Overview**: CPU, memory, disk, network status
2. **GPU Monitoring**: Utilization, temperature, memory usage across services
3. **Media Pipeline**: Download queues, processing status, storage tier usage
4. **Service Health**: Container status, endpoint availability, response times
5. **Storage Management**: Hot/cold tier usage, migration status, capacity planning

### **Alert Management**
- **Severity Levels**: Critical (immediate action), Warning (attention needed), Info (awareness)
- **Notification Channels**: Webhook-based alerting system for real-time notifications
- **Alert Groups**: System alerts, Storage alerts, GPU alerts, Container alerts, Service alerts

## 🎬 Media Pipeline Architecture

### **Two-Tier Storage Strategy**
**Hot Storage** (`/mnt/hot` - SSD): Fast storage for active operations
- Active downloads and real-time processing
- Application caches and temporary files  
- Recent media access and preview generation

**Cold Storage** (`/mnt/media` - HDD): Archival storage for organized libraries
- Final organized media libraries (movies, TV, music)
- Long-term retention and backup storage
- Jellyfin/Plex media serving and streaming

### **Download and Processing Workflow**
1. **Download Phase**: qBittorrent/SABnzbd → Hot storage via VPN protection
2. **Processing Phase**: *arr applications analyze, rename, and organize content
3. **Migration Phase**: Automated scripts move completed content to appropriate cold storage
4. **Cleanup Phase**: Scheduled cleanup of temporary files, old downloads, and cache

### **VPN Integration & Security**
- **VPN Provider**: ProtonVPN via Gluetun container isolation
- **VPN Scope**: Download clients only (qBittorrent, SABnzbd) - media serving remains direct
- **Security**: SOPS-encrypted credentials, dedicated container network isolation
- **Monitoring**: VPN connection status monitoring and automatic reconnection

## 💾 Storage Tier Management Strategy

### **Automated Migration System**
- **Migration Triggers**: Completion status, file age, storage usage thresholds
- **Migration Process**: rsync with verification, integrity checks, and cleanup
- **Monitoring**: Real-time storage usage alerts and capacity planning automation

### **Cache Management Policies**
- **GPU Cache**: Dedicated cache directories for GPU-accelerated services
- **Application Cache**: Service-specific cache with intelligent cleanup
- **Cleanup Policies**: Time-based retention (7-30 days) and size-based limits

### **Backup & Recovery Strategy**
- **Configuration**: Git-based NixOS configuration backup with automatic commits
- **Media Libraries**: Cold storage acts as primary (no additional backup needed)
- **Surveillance**: Event-based backup to cold storage with retention policies

## 🚀 File Management (Safe Methods Only)

### **Use Built-in *arr Features**
- Access via web UI: Settings → Media Management → File Naming
- Test on single files first
- Enable manual import for maximum control

### **Jellyfin-Compatible Templates**
```
Movies: {Movie Title} ({Year})/{Movie Title} ({Year}) {Quality Title}
TV: {Series Title}/Season {season:00}/{Series Title} - S{season:00}E{episode:00} - {Episode Title}
Music: {Artist Name}/{Album Title} ({Year})/{track:00} - {Track Title}
```

## 💡 Working with This System

1. **Read documentation first** - check `/etc/nixos/docs/` for existing solutions
2. **Test incrementally** - small changes are safer than large ones
3. **Monitor after changes** - watch logs and system metrics
4. **Document new features** - AI system will help generate documentation automatically
5. **Use existing patterns** - follow established configuration styles

This system prioritizes **reliability over complexity** and **safety over automation**. The new AI documentation system enhances this by automatically generating intelligent documentation while maintaining safety through local processing.

---
**Last Updated**: 2025-08-06 | **System**: NixOS hwc-server | **GPU**: NVIDIA Quadro P1000 | **AI**: Ollama llama3.2:3b