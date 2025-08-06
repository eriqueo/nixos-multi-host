# System Concepts and Architecture Documentation

## Overview
This document consolidates all conceptual information about the NixOS multi-host homelab setup, including system architecture, design decisions, and operational workflows.


## Recent Architectural Evolution (AI-Generated: 2025-08-05)

Upon analyzing the recent commits to the NixOS homeserver, it appears that there have been significant architectural changes focused on improving service orchestration and containerization. The implementation of a declarative AI documentation system has streamlined configuration management, with Caddy being integrated into the system through a custom configuration file (`hosts/server/modules/caddy-config.nix`). This change enables more efficient and automated deployment of services, aligning with NixOS's emphasis on declarative infrastructure management.

---

## Recent Architectural Evolution (AI-Generated: 2025-08-05)

The recent commits to the NixOS homeserver have introduced significant architectural changes focused on improving service orchestration and automation. The implementation of an AI documentation system has enabled declarative configuration management, allowing for more efficient and automated updates to the system's documentation via AI analysis. This shift towards automation and self-updating documentation reflects a broader trend towards increasing infrastructure flexibility and maintainability in NixOS deployments.

---
## Table of Contents
1. [System Architecture](#system-architecture)
2. [GPU Acceleration Framework](#gpu-acceleration-framework) 
3. [Monitoring and Observability](#monitoring-and-observability)
4. [Media Pipeline Architecture](#media-pipeline-architecture)
5. [Security and Access Control](#security-and-access-control)
6. [Storage Tier Management](#storage-tier-management)

---

## System Architecture

### Hardware Foundation
**Primary Server**: hwc-server with NVIDIA Quadro P1000 (Pascal architecture)
- **GPU Capabilities**: CUDA compute capability 6.1, 4GB VRAM
- **Storage**: Two-tier architecture (SSD hot storage + HDD cold storage)
- **Network**: Tailscale mesh networking with local LAN access

### Service Containerization Strategy
**Container Runtime**: Podman with systemd integration
**Network Architecture**: Custom container networks with media-network for inter-service communication
**GPU Sharing**: Direct device access pattern with sophisticated container builders
**Resource Management**: Automatic memory/CPU limits and hot storage integration

### Core Service Categories
1. **Media Management**: *arr applications with buildMediaServiceContainer
2. **Media Streaming**: Jellyfin (native), Navidrome, Immich (native with GPU)
3. **Surveillance**: Frigate with TensorRT + Home Assistant integration
4. **AI/ML**: Ollama with CUDA acceleration
5. **Monitoring**: Comprehensive Prometheus + Grafana stack with GPU metrics
6. **Download Management**: qBittorrent + SABnzbd via buildDownloadContainer with VPN
7. **Business Intelligence**: Custom Python dashboards with GPU acceleration

---

## GPU Acceleration Framework

### Design Philosophy
**Consistent GPU Access**: All GPU-capable services use standardized device access patterns
**Resource Sharing**: Multiple services share GPU through proper isolation
**Architecture Optimization**: Pascal-specific configurations (FP16 disabled for TensorRT)

### GPU Device Access Pattern
```nix
nvidiaGpuOptions = [ 
  "--device=/dev/nvidia0:/dev/nvidia0:rwm"
  "--device=/dev/nvidiactl:/dev/nvidiactl:rwm" 
  "--device=/dev/nvidia-modeset:/dev/nvidia-modeset:rwm"
  "--device=/dev/nvidia-uvm:/dev/nvidia-uvm:rwm"
  "--device=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools:rwm"
  "--device=/dev/dri:/dev/dri:rwm"
];
```

### Service GPU Utilization Matrix
| Service | GPU Usage | Primary Benefit |
|---------|-----------|-----------------|
| Frigate | TensorRT object detection | Real-time video analysis |
| Immich | Face recognition, ML processing | Photo organization |
| Jellyfin | Hardware transcoding (NVENC/NVDEC) | Video streaming |
| Ollama | CUDA inference | Local AI processing |
| *arr apps | Thumbnail generation | Media preview |
| Download clients | Video processing | Preview generation |

### Pascal Architecture Considerations
- **TensorRT**: Requires `USE_FP16 = "false"` for model generation
- **Memory Management**: 4GB VRAM requires careful resource allocation
- **Codec Support**: H.264/H.265 encoding, limited AV1 support

---

## Monitoring and Observability

### Metrics Collection Architecture
**Core Metrics**: Node Exporter for system metrics
**Container Metrics**: cAdvisor for container resource usage  
**GPU Metrics**: NVIDIA GPU Exporter for GPU utilization
**Application Metrics**: Custom exporters for media pipeline health
**Storage Metrics**: Custom scripts for hot/cold storage monitoring

### Alert Management Strategy
**Severity Levels**: Critical, Warning, Info
**Notification Channels**: Webhook-based alerting system
**Alert Groups**: System, Storage, GPU, Containers, Services

### Dashboard Organization
1. **System Overview**: CPU, memory, disk, network
2. **GPU Monitoring**: Utilization, temperature, memory usage
3. **Media Pipeline**: Download queues, processing status, storage tiers
4. **Service Health**: Container status, endpoint availability
5. **Storage Management**: Hot/cold tier usage, migration status

---

## Media Pipeline Architecture

### Two-Tier Storage Strategy
**Hot Storage** (`/mnt/hot`): SSD-based fast storage for:
- Active downloads and processing
- Cache and temporary files  
- Recent media access

**Cold Storage** (`/mnt/media`): HDD-based archival storage for:
- Organized media libraries
- Long-term retention
- Plex/Jellyfin media serving

### Download and Processing Workflow
1. **Download**: qBittorrent/SABnzbd → Hot storage
2. **Processing**: *arr applications process and organize
3. **Migration**: Automated scripts move completed content to cold storage
4. **Cleanup**: Scheduled cleanup of temporary files and old downloads

### VPN Integration
**VPN Provider**: ProtonVPN via Gluetun container
**VPN Scope**: Download clients only (qBittorrent, SABnzbd)
**Security**: SOPS-encrypted credentials, container network isolation

---

## Security and Access Control

### Network Security
**Tailscale**: Mesh VPN for remote access
**Firewall**: Interface-specific rules (tailscale0, local LAN)
**Container Isolation**: Network segmentation between service groups

### Secrets Management
**SOPS**: Age-encrypted secrets for sensitive configuration
**Credential Scope**: VPN credentials, API keys, passwords
**Access Control**: File-level permissions and ownership

### Service Authentication
**Internal Services**: Basic authentication where required
**External Access**: Reverse proxy with authentication (planned)
**Container Security**: Non-privileged containers where possible

---

## Storage Tier Management

### Automated Migration Strategy
**Migration Triggers**: Completion status, age, storage thresholds
**Migration Process**: rsync with verification and cleanup
**Monitoring**: Storage usage alerts and capacity planning

### Cache Management
**GPU Cache**: Dedicated cache for GPU-accelerated services
**Application Cache**: Service-specific cache directories
**Cleanup Policies**: Time-based and size-based retention

### Backup Strategy
**Configuration**: Git-based NixOS configuration backup
**Media**: Cold storage acts as primary storage (no backup needed)
**Surveillance**: Event-based backup to cold storage

---

This document serves as the comprehensive guide to understanding the system architecture and design decisions behind the NixOS homelab setup.