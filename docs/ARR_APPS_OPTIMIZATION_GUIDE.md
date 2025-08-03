# *arr Applications Optimization Guide

## 📋 Current Status Assessment

### ✅ Excellent Foundation
- **Complete Stack**: Sonarr, Radarr, Lidarr, Prowlarr, Soularr all running
- **Download Clients**: qBittorrent + SABnzbd with VPN protection via Gluetun
- **Smart Storage**: Hot/cold tier architecture with SSD processing and HDD storage
- **Security**: SOPS encryption, VPN protection, quarantine system
- **Automation**: RandomNinjaAtk scripts integrated

### 🔧 Optimization Opportunities

#### 1. Indexer Authentication & Configuration
**Status**: Many indexers configured but likely missing credentials
**Impact**: Limited access to high-quality content from private trackers

#### 2. Quality Profiles & Naming
**Status**: Using default profiles, no custom optimization
**Impact**: Inefficient storage usage and inconsistent media organization

#### 3. Performance & Resource Management
**Status**: No container limits, GPU acceleration available but underutilized
**Impact**: Potential resource contention and missed performance opportunities

## 🚀 Step-by-Step Optimization Instructions

### Phase 1: Indexer Configuration and Authentication

#### Step 1.1: Configure Private Tracker Credentials
**File**: Access via Prowlarr Web UI at http://localhost:9696

**Critical Indexers to Configure**:
1. **Navigate to Prowlarr** → Settings → Indexers
2. **For each private tracker**, add API keys/credentials:
   - **IPTorrents**: Add API key from profile page
   - **TorrentLeech**: Add API key from profile settings
   - **RED/Orpheus**: Configure for music (if you have accounts)
   - **BroadcastHE.Net**: For TV content

**NixOS Configuration Update**:
```nix
# In media-containers.nix, add environment variables for indexer credentials
environment = mediaServiceEnv // {
  # Add SOPS-encrypted indexer credentials
  PROWLARR_API_KEY = config.sops.secrets.prowlarr-api.path;
  # Other indexer-specific variables
};
```

#### Step 1.2: Optimize Indexer Health Monitoring
**File**: `/etc/nixos/hosts/server/modules/media-containers.nix`

**Add health check configurations**:
```nix
prowlarr = {
  # existing configuration
  healthcheck = {
    test = [ "CMD" "curl" "-f" "http://localhost:9696/api/v1/health" ];
    interval = "30s";
    timeout = "10s";
    retries = 3;
  };
};
```

### Phase 2: Quality Profiles and Media Management

#### Step 2.1: Create Custom Quality Profiles
**Access each *arr application web interface**:

**Sonarr (TV Shows) - http://localhost:8989**:
1. **Settings** → **Profiles** → **Quality Profiles**
2. **Create profiles**:
   - **4K-UHD**: For 4K content (if storage allows)
   - **1080p-Optimal**: 1080p with reasonable file sizes
   - **720p-Efficient**: For older shows or space constraints

**Radarr (Movies) - http://localhost:7878**:
1. **Settings** → **Profiles** → **Quality Profiles**
2. **Create profiles**:
   - **UHD-4K**: For new releases
   - **HD-1080p**: Standard high quality
   - **SD-720p**: For older content

#### Step 2.2: Configure Custom Naming Schemes
**For each *arr application**:

**TV Shows (Sonarr)**:
```
Series Folder: {Series Title} ({Year})
Season Folder: Season {season:00}
Episode File: {Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Title}
```

**Movies (Radarr)**:
```
Movie Folder: {Movie Title} ({Year})
Movie File: {Movie Title} ({Year}) {Quality Title}
```

**Music (Lidarr)**:
```
Artist Folder: {Artist Name}
Album Folder: {Album Title} ({Year})
Track File: {track:00} - {Track Title}
```

#### Step 2.3: Implement Automated Quality Upgrades
**Configure automatic quality improvements**:

1. **Enable automatic search** for better quality releases
2. **Set upgrade policies**:
   - Upgrade from 720p to 1080p within 30 days
   - Replace low-bitrate releases with higher quality
   - Skip upgrades for files >2 years old

### Phase 3: Performance and Resource Optimization

#### Step 3.1: Add Container Resource Limits
**File**: `/etc/nixos/hosts/server/modules/media-containers.nix`

**Add resource constraints to prevent system overload**:
```nix
# Add to each *arr container
extraOptions = mediaNetworkOptions ++ [
  "--memory=2g"          # Limit RAM usage
  "--cpus=1.0"           # Limit CPU usage
  "--memory-swap=4g"     # Allow swap for large operations
];
```

#### Step 3.2: Enable GPU Acceleration for Jellyfin
**File**: `/etc/nixos/hosts/server/modules/media-containers.nix`

**Uncomment and optimize Jellyfin container**:
```nix
# Uncomment the Jellyfin container configuration around line 300
jellyfin = {
  image = "jellyfin/jellyfin:latest";
  autoStart = true;
  extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ [
    "--memory=4g"
    "--cpus=2.0"
  ];
  environment = mediaServiceEnv // nvidiaEnv;
  ports = [ "8096:8096" ];
  volumes = [
    "/mnt/media/movies:/movies:ro"
    "/mnt/media/tv:/tv:ro"
    "/mnt/media/music:/music:ro"
    "/mnt/hot/cache/jellyfin:/cache"
    "/etc/localtime:/etc/localtime:ro"
  ];
};
```

#### Step 3.3: Optimize Download Client Settings
**qBittorrent Optimization**:
1. **Access qBittorrent**: http://localhost:8080
2. **Settings** → **Speed**:
   - Global download limit: 80% of connection speed
   - Global upload limit: 10% of connection speed
3. **Settings** → **BitTorrent**:
   - Enable DHT, PeX, and LSD
   - Max active downloads: 5
   - Max active uploads: 3

**SABnzbd Optimization**:
1. **Access SABnzbd**: http://localhost:8080 (different port)
2. **Config** → **Servers**: Configure Usenet provider
3. **Config** → **General**:
   - Download folder: `/hot/downloads/usenet/incomplete`
   - Complete folder: `/hot/downloads/usenet/complete`

### Phase 4: Storage and File Management

#### Step 4.1: Implement Automated Cleanup
**File**: `/etc/nixos/hosts/server/modules/media-containers.nix`

**Add cleanup service**:
```nix
systemd.services.media-cleanup = {
  description = "Clean up old downloads and temporary files";
  startAt = "daily";
  script = ''
    # Clean old downloads (>30 days)
    find /mnt/hot/downloads -type f -mtime +30 -delete
    
    # Clean quarantine (>7 days)
    find /mnt/hot/quarantine -type f -mtime +7 -delete
    
    # Clean processing temp files (>1 day)
    find /mnt/hot/processing -type f -mtime +1 -delete
    
    # Alert if hot storage >80% full
    USAGE=$(df /mnt/hot | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $USAGE -gt 80 ]; then
      echo "WARNING: Hot storage is $USAGE% full" | logger
    fi
  '';
};
```

#### Step 4.2: Configure Automated Media Migration
**Create hot-to-cold storage migration**:
```nix
systemd.services.media-migration = {
  description = "Migrate completed media from hot to cold storage";
  startAt = "hourly";
  script = ''
    # Move completed TV shows
    if [ -d "/mnt/hot/downloads/tv/complete" ]; then
      rsync -av --remove-source-files /mnt/hot/downloads/tv/complete/ /mnt/media/tv/
    fi
    
    # Move completed movies
    if [ -d "/mnt/hot/downloads/movies/complete" ]; then
      rsync -av --remove-source-files /mnt/hot/downloads/movies/complete/ /mnt/media/movies/
    fi
    
    # Move completed music
    if [ -d "/mnt/hot/downloads/music/complete" ]; then
      rsync -av --remove-source-files /mnt/hot/downloads/music/complete/ /mnt/media/music/
    fi
  '';
};
```

### Phase 5: Advanced Automation and Integration

#### Step 5.1: Configure RandomNinjaAtk Scripts
**Optimize existing script integration**:

**Review script configuration** in container environment:
```nix
# Add specific script configurations
environment = mediaServiceEnv // {
  # Sonarr script settings
  SONARR_URL = "http://sonarr:8989";
  SONARR_API_KEY = "your-api-key";
  
  # Radarr script settings  
  RADARR_URL = "http://radarr:7878";
  RADARR_API_KEY = "your-api-key";
  
  # Enable specific automations
  ENABLE_RECYCLARR = "true";
  ENABLE_AUDIO_PROCESSING = "true";
  ENABLE_VIDEO_PROCESSING = "true";
};
```

#### Step 5.2: Set Up Cross-Application Integration
**Configure *arr app communication**:

1. **In Sonarr/Radarr**: Settings → Connect
2. **Add Prowlarr connection**:
   - URL: http://prowlarr:9696
   - API Key: (from Prowlarr settings)
3. **Add download client connections**:
   - qBittorrent: http://gluetun:8080
   - SABnzbd: http://gluetun:8080

#### Step 5.3: Implement Request Management
**Set up Overseerr for media requests** (optional enhancement):
```nix
# Add to media-containers.nix
overseerr = {
  image = "sctx/overseerr:latest";
  autoStart = true;
  extraOptions = mediaNetworkOptions;
  ports = [ "5055:5055" ];
  volumes = [
    "/mnt/hot/config/overseerr:/app/config"
    "/etc/localtime:/etc/localtime:ro"
  ];
  environment = mediaServiceEnv;
};
```

### Phase 6: Monitoring and Health Checks

#### Step 6.1: Add Application Health Monitoring
**Integrate with existing Prometheus setup**:
```nix
# Add to monitoring.nix scrape configs
- job_name: 'media-services'
  static_configs:
    - targets: 
      - 'sonarr:8989'
      - 'radarr:7878'  
      - 'lidarr:8686'
      - 'prowlarr:9696'
  metrics_path: '/api/v3/system/status'
```

#### Step 6.2: Configure Application-Specific Alerts
**Add alerting rules**:
```yaml
# Add to Prometheus alert rules
- alert: ArrApplicationDown
  expr: up{job="media-services"} == 0
  for: 5m
  annotations:
    summary: "*arr application is down"

- alert: DownloadQueueStuck  
  expr: sonarr_queue_total > 50
  for: 30m
  annotations:
    summary: "Download queue appears stuck"
```

## 🧪 Testing and Validation

### After Each Phase:

1. **Test configuration**:
   ```bash
   grebuild "Media pipeline optimization phase X"
   ```

2. **Verify service health**:
   ```bash
   sudo podman ps | grep -E "(sonarr|radarr|prowlarr)"
   ```

3. **Check application logs**:
   ```bash
   sudo podman logs sonarr -f
   ```

4. **Test download workflow**:
   - Add a test movie/show to monitor automatic download

### Performance Validation:

- **Search speed**: Indexer searches complete in <10 seconds
- **Download speed**: Utilizing available bandwidth efficiently  
- **Storage usage**: Hot storage staying under 80%
- **Resource usage**: Container CPU/memory within limits

## 🚨 Common Issues and Solutions

### Issue: "No indexers available"
**Solution**: Configure private tracker credentials in Prowlarr

### Issue: "Downloads stuck in queue"
**Solution**: Check VPN connection and download client connectivity

### Issue: "Hot storage full"
**Solution**: Implement automated cleanup or reduce parallel downloads

### Issue: "Poor quality downloads"
**Solution**: Adjust quality profiles and indexer preferences

## 📈 Success Metrics

After optimization:
- ✅ 90%+ successful automatic downloads
- ✅ Consistent media quality across library
- ✅ Hot storage efficiently managed (<80% usage)
- ✅ Download speeds utilizing available bandwidth
- ✅ Automated quality upgrades working
- ✅ Integration between all *arr applications functional
- ✅ Monitoring and alerting operational