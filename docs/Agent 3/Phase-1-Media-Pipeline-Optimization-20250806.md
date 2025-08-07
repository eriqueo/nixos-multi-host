# Phase 1 — arr Media Pipeline Optimization

**Agent 3: Media Pipeline & Monitoring Optimization**

**Date:** 2025-08-06

---

## Executive Summary

This guide delivers a complete, NixOS-native optimization of your *arr media pipeline:  
- Prowlarr indexer authentication (private tracker unlock)
- Quality profiles & naming conventions (library hygiene)
- Automated quality upgrades
- Resource limits on media containers
- GPU acceleration for *arr and Jellyfin
- Storage hygiene (cleanup & migration)

All steps are production-ready, include rollback/testing, and follow NixOS best practices.

---

## Table of Contents

1. [Indexer Authentication (Prowlarr)](#indexer-authentication-prowlarr)
2. [Quality Profiles & Naming Conventions](#quality-profiles--naming-conventions)
3. [Automated Quality Upgrades](#automated-quality-upgrades)
4. [Resource Limits on Media Containers](#resource-limits-on-media-containers)
5. [GPU Acceleration for Media Services](#gpu-acceleration-for-media-services)
6. [Storage Hygiene & Migration](#storage-hygiene--migration)
7. [Testing, Rollback, and Validation](#testing-rollback-and-validation)

---

## Indexer Authentication (Prowlarr)

**Goal:** Unlock access to private trackers for Sonarr/Radarr/Lidarr via Prowlarr.  
**Outcome:** Consistent, high-quality downloads.

### Steps

1. Open Prowlarr at `http://localhost:9696` (or reverse proxy path).
2. Go to **Settings → Indexers**.
3. For each private tracker (IPTorrents, TorrentLeech, RED, Orpheus, etc):
    - Click **+ Add Indexer**.
    - Paste API key or credentials.
    - Save and test connection.
4. *Best Practice*: Store API keys in SOPS, reference via Nix config for reproducibility:

    ```nix
    environment = mediaServiceEnv // {
      PROWLARR_IPTORRENTS_API = config.sops.secrets.iptorrents-api.path;
      # Add more as needed
    };
    ```
5. In the web UI, ensure each indexer shows **Status: OK** and is “Enabled”.

---

## Quality Profiles & Naming Conventions

**Goal:** Organize media at desired quality and with consistent file/folder names.

### Steps

#### Sonarr (TV)
- Go to **Settings → Profiles → Quality**.  
  Create: 4K-UHD, 1080p-Optimal, 720p-Efficient.
- **Media Management → Episode Naming:**

    ```
    {Series Title} ({Year})/Season {season:00}/{Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Title}
    ```

#### Radarr (Movies)
- **Settings → Profiles → Quality**: UHD-4K, HD-1080p, SD-720p.
- **Media Management → Movie Naming:**

    ```
    {Movie Title} ({Year})/{Movie Title} ({Year}) {Quality Title}
    ```

#### Lidarr (Music)
- **Settings → Profiles → Quality** if used.
- Folder/file template:

    ```
    {Artist Name}/{Album Title} ({Year})/{track:00} - {Track Title}
    ```

> *If desired, include these as environment variables in Nix. Some settings may still require manual web UI configuration.*

---

## Automated Quality Upgrades

**Goal:** Replace media with higher-quality releases automatically.

### Steps

- In each *arr app (**Profiles → Quality Upgrade**):
    - Enable **Automatic Upgrades**.
    - Set cutoffs (e.g., 1080p replaces 720p).
    - Restrict upgrades to recent content (e.g., within 30 days).
- Test by adding a lower-quality item, observe if it upgrades when a better version appears.

---

## Resource Limits on Media Containers

**Goal:** Prevent resource hogging by individual containers.

### Steps

- In `/etc/nixos/hosts/server/modules/media-containers.nix`, add to each media container:

    ```nix
    sonarr = {
      extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ [
        "--memory=2g"
        "--cpus=1.0"
        "--memory-swap=4g"
      ];
      # ...
    };
    radarr = {
      extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ [
        "--memory=2g"
        "--cpus=1.0"
        "--memory-swap=4g"
      ];
      # ...
    };
    # Repeat for lidarr, prowlarr, qbittorrent, sabnzbd
    ```

- Reload config:

    ```bash
    sudo nixos-rebuild switch
    sudo podman ps
    ```

- Test with heavy workloads and observe with `htop` or `podman stats`.

---

## GPU Acceleration for Media Services

**Goal:** Accelerate thumbnail/preview generation and transcoding.

### Steps

- In each *arr and downloader container:

    ```nix
    extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions;
    environment = mediaServiceEnv // nvidiaEnv;
    ```

- For Jellyfin, edit `/var/lib/jellyfin/config/encoding.xml`:

    ```xml
    <HardwareAccelerationType>nvenc</HardwareAccelerationType>
    <EnableHardwareEncoding>true</EnableHardwareEncoding>
    <EnableEnhancedNvdecDecoder>true</EnableEnhancedNvdecDecoder>
    <HardwareDecodingCodecs>
      <string>h264</string>
      <string>hevc</string>
      <string>vp8</string>
      <string>vp9</string>
    </HardwareDecodingCodecs>
    <AllowHevcEncoding>true</AllowHevcEncoding>
    ```

- Test by triggering transcodes and watching GPU usage (`nvidia-smi`).

---

## Storage Hygiene & Migration

**Goal:** Prevent bloat and automate movement to cold storage.

### Steps

- In `/etc/nixos/hosts/server/modules/media-containers.nix`:

    ```nix
    systemd.services.media-cleanup = {
      description = "Clean up old downloads and temporary files";
      startAt = "daily";
      script = ''
        find /mnt/hot/downloads -type f -mtime +30 -delete
        find /mnt/hot/quarantine -type f -mtime +7 -delete
        find /mnt/hot/processing -type f -mtime +1 -delete
        USAGE=$(df /mnt/hot | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ $USAGE -gt 80 ]; then
          echo "WARNING: Hot storage is $USAGE% full" | logger
        fi
      '';
    };
    systemd.services.media-migration = {
      description = "Migrate completed media from hot to cold storage";
      startAt = "hourly";
      script = ''
        if [ -d "/mnt/hot/downloads/tv/complete" ]; then
          rsync -av --remove-source-files /mnt/hot/downloads/tv/complete/ /mnt/media/tv/
        fi
        if [ -d "/mnt/hot/downloads/movies/complete" ]; then
          rsync -av --remove-source-files /mnt/hot/downloads/movies/complete/ /mnt/media/movies/
        fi
        if [ -d "/mnt/hot/downloads/music/complete" ]; then
          rsync -av --remove-source-files /mnt/hot/downloads/music/complete/ /mnt/media/music/
        fi
      '';
    };
    ```

- Test migration with manual runs and verify file movement.

---

## Testing, Rollback, and Validation

### Testing

After each change:

```bash
sudo nixos-rebuild test --flake .#$(hostname)
sudo podman ps
sudo podman logs <service>
watch -n 1 nvidia-smi
```

### Rollback

- All configs are version-controlled.  
- To revert:
    ```bash
    sudo git checkout <previous-commit>
    sudo nixos-rebuild switch
    ```
- For a single module:
    ```bash
    sudo cp /etc/nixos/hosts/server/modules/<file>.backup /etc/nixos/hosts/server/modules/<file>
    sudo nixos-rebuild switch
    ```

---

## References

- `ARR_APPS_OPTIMIZATION_GUIDE.md`
- `GPU_ACCELERATION_GUIDE.md`
- `JELLYFIN-GPU-SETUP.md`
- NixOS official docs: https://nixos.org/manual

---

*End of Phase 1 Media Pipeline Optimization*
