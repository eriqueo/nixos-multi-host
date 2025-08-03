# 🎯 Claude Code System Context - NixOS Homeserver

**READ THIS FIRST** - Essential context for understanding this NixOS homeserver configuration.

## ⚡ Quick Start Checklist
- [ ] **Hardware**: AMD Ryzen + NVIDIA Quadro P1000 + Hot SSD + Cold HDD
- [ ] **Deploy Method**: Use `grebuild "commit message"` (handles git + rebuild automatically)
- [ ] **Test First**: Always `sudo nixos-rebuild test --flake .#homeserver` before committing
- [ ] **GPU Enabled**: Services have NVIDIA acceleration (Frigate, Immich, Jellyfin, *arr apps)

## 🏗️ System Architecture

### **Storage Tiers**
- **`/mnt/hot`** (SSD): Active downloads, processing, cache
- **`/mnt/media`** (HDD): Final media library storage
- **Automated migration**: Hot → Cold via systemd services

### **Container Stack** (Podman)
- **Media**: Sonarr/Radarr/Lidarr + Jellyfin (GPU accelerated)
- **Downloads**: qBittorrent + SABnzbd via Gluetun VPN
- **Surveillance**: Frigate (TensorRT) + Home Assistant  
- **Monitoring**: Prometheus + Grafana + custom metrics
- **Business**: Python dashboards with analytics

### **Security**
- **SOPS**: Age-encrypted secrets in `/etc/nixos/secrets/`
- **VPN**: ProtonVPN for downloads, Tailscale for remote access
- **Network**: Custom `media-network` for container isolation

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

## 📚 Essential Documentation

| Topic | File | Purpose |
|-------|------|---------|
| **System Overview** | `docs/CLAUDE_CODE_SYSTEM_PRIMER.md` | Complete system context |
| **Media Management** | `docs/ARR_APPS_OPTIMIZATION_GUIDE.md` | *arr apps, naming, automation |
| **Surveillance** | `docs/FRIGATE_OPTIMIZATION_GUIDE.md` | Camera config, object detection |
| **Monitoring** | `docs/MONITORING_OPTIMIZATION_GUIDE.md` | Grafana, Prometheus, alerting |
| **GPU Acceleration** | `docs/GPU_ACCELERATION_GUIDE.md` | NVIDIA setup, troubleshooting |
| **Architecture** | `docs/SYSTEM_CONCEPTS_AND_ARCHITECTURE.md` | Service relationships |
| **Troubleshooting** | `docs/TROUBLESHOOTING_UPDATED.md` | Common issues, solutions |

## 🔧 Quick Commands

```bash
# System Status
sudo systemctl status podman-*.service  # Check all containers
sudo podman ps                          # Running containers
nvidia-smi                              # GPU status
df -h /mnt/hot /mnt/media               # Storage usage

# Deploy Changes
grebuild "Descriptive commit message"   # Preferred method
# OR manually:
sudo nixos-rebuild test --flake .#homeserver
sudo nixos-rebuild switch --flake .#homeserver

# Debugging
sudo journalctl -fu podman-servicename.service
sudo podman logs containername
```

## 🎯 Current System State

### **Recently Optimized** ✅
- *arr applications with GPU acceleration and resource limits
- Automated storage management with hot/cold tier migration
- Comprehensive monitoring with Prometheus metrics
- Frigate surveillance with 4K object detection

### **Active Services**
- **Media Pipeline**: All *arr apps + Jellyfin with GPU transcoding
- **Downloads**: VPN-protected via Gluetun + ProtonVPN
- **Monitoring**: Grafana dashboards operational
- **Surveillance**: 4 cameras with Frigate object detection
- **Business Tools**: Custom metrics and dashboards

### **Known Issues** ⚠️
- Some Frigate cameras may need periodic authentication fixes
- Storage monitoring requires proper gawk package paths
- GPU monitoring may need occasional restarts

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
4. **Document new features** - update relevant .md files
5. **Use existing patterns** - follow established configuration styles

This system prioritizes **reliability over complexity** and **safety over automation**. When in doubt, choose the safer approach and test thoroughly.

---
**Last Updated**: 2025-08-02 | **System**: NixOS Homeserver | **GPU**: NVIDIA Quadro P1000