# Media Pipeline Configuration Guide

**Last Updated**: 2025-08-05  
**System**: NixOS Homeserver with Gluetun VPN  
**Purpose**: Complete technical reference for configuring *arr apps, download clients, and media storage

---

## 🏗️ Container Network Architecture

### **Network Overview**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   *arr Apps     │    │     Gluetun      │    │  Media Storage  │
│  (media-network)│    │   VPN Gateway    │    │   (Host Mounts) │
│                 │    │                  │    │                 │
│ • Sonarr        │◄──►│ • qBittorrent    │◄──►│ • /mnt/hot      │
│ • Radarr        │    │ • SABnzbd        │    │ • /mnt/media    │
│ • Lidarr        │    │                  │    │                 │
│ • Prowlarr      │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### **Container Ports Reference**

| Service | Container Network | Internal Port | External Port | Access From *arr Apps |
|---------|------------------|---------------|---------------|----------------------|
| **Sonarr** | media-network | 8989 | 8989 | N/A |
| **Radarr** | media-network | 7878 | 7878 | N/A |
| **Lidarr** | media-network | 8686 | 8686 | N/A |
| **Prowlarr** | media-network | 9696 | 9696 | N/A |
| **qBittorrent** | container:gluetun | 8080 | 8080 (via Gluetun) | `gluetun:8080` |
| **SABnzbd** | container:gluetun | 8085 | 8081 (via Gluetun) | `gluetun:8085` |
| **Gluetun** | media-network | N/A | N/A | N/A |

### **Critical Port Mapping Notes**
- **SABnzbd Internal**: Runs on port 8085 inside container
- **SABnzbd External**: Accessible on port 8081 (mapped by Gluetun)
- **Connection Rule**: *arr apps connect to download clients using `gluetun:INTERNAL_PORT`

---

## 📁 Volume Mounting Architecture

### **Hot/Cold Storage Strategy**
```
/mnt/hot/     (SSD - Active Processing)
├── downloads/
│   ├── qbittorrent/
│   │   ├── incomplete/
│   │   └── complete/
│   ├── sabnzbd/
│   │   ├── incomplete/
│   │   └── complete/
│   └── categories/
│       ├── tv/
│       ├── movies/
│       └── music/
├── processing/
│   ├── sonarr/
│   ├── radarr/
│   └── lidarr/
└── cache/
    ├── sonarr/
    ├── radarr/
    └── lidarr/

/mnt/media/   (HDD - Final Storage)
├── tv/
├── movies/
└── music/
```

### **Container Volume Mappings**

#### ***arr Applications (Sonarr, Radarr, Lidarr)**
```nix
volumes = [
  "/opt/downloads/${name}:/config"                    # App configuration
  "/mnt/hot/downloads:/hot-downloads"                 # Active downloads monitoring
  "/mnt/hot/processing/${mediaType}:/processing"     # Import processing area
  "/mnt/media/${mediaType}:/media"                    # Final media library
  "/mnt/hot/cache/${name}:/cache"                     # Application cache
];
```

**Specific Media Type Mappings:**
- **Sonarr**: `mediaType = "tv"`
  - `/mnt/media/tv:/media` (TV library)
  - `/mnt/hot/processing/tv:/processing` (TV processing)
- **Radarr**: `mediaType = "movies"`  
  - `/mnt/media/movies:/media` (Movie library)
  - `/mnt/hot/processing/movies:/processing` (Movie processing)
- **Lidarr**: `mediaType = "music"`
  - `/mnt/media/music:/media` (Music library)
  - `/mnt/hot/processing/music:/processing` (Music processing)

#### **Download Clients (qBittorrent, SABnzbd)**
```nix
# qBittorrent volumes
volumes = [
  "/opt/downloads/qbittorrent:/config"               # qBittorrent config
  "/mnt/hot/downloads:/downloads"                    # Download directory
  "/mnt/hot/cache/qbittorrent:/cache"               # Cache directory
];

# SABnzbd volumes  
volumes = [
  "/opt/downloads/sabnzbd:/config"                   # SABnzbd config
  "/mnt/hot/downloads:/downloads"                    # Download directory
  "/mnt/hot/cache:/incomplete-downloads"            # Incomplete downloads
];
```

#### **Prowlarr**
```nix
volumes = [
  "/opt/downloads/prowlarr:/config"                  # Prowlarr config
  "/mnt/hot/cache/prowlarr:/cache"                  # Cache directory
];
```

---

## ⚙️ Download Client Configuration

### **qBittorrent Setup**

#### **Web Interface Access**
- **Direct**: `http://192.168.1.13:8080`
- **Tailscale**: `http://hwc.ocelot-wahoo.ts.net:8080`
- **Default Login**: `admin` / `adminadmin` (change immediately)

#### **Required Categories in qBittorrent**
1. **Access**: qBittorrent → Options → Downloads
2. **Create Categories**:
   ```
   tv       → /downloads/tv/
   movies   → /downloads/movies/  
   music    → /downloads/music/
   ```

#### **Critical qBittorrent Settings**
```
Options → Downloads:
✓ Default Save Path: /downloads/
✓ Keep incomplete torrents in: /downloads/incomplete/
✓ Copy .torrent files to: /downloads/torrents/
✓ Automatically add torrents from: /downloads/watch/

Options → Connection:
✓ Use different port on each startup: DISABLED
✓ Port used for incoming connections: 6881

Options → Speed:
✓ Global download speed limit: [80% of connection]
✓ Global upload speed limit: [10% of connection]
```

### **SABnzbd Setup**

#### **Web Interface Access**
- **Direct**: `http://192.168.1.13:8081`
- **Tailscale**: `http://hwc.ocelot-wahoo.ts.net:8081`

#### **Required Categories in SABnzbd**
1. **Access**: SABnzbd → Config → Categories
2. **Create Categories**:
   ```
   tv      → Folder: tv      → Processing: +Delete
   movies  → Folder: movies  → Processing: +Delete  
   music   → Folder: music   → Processing: +Delete
   ```

#### **Critical SABnzbd Settings**
```
Config → Folders:
✓ Temporary Download Folder: /incomplete-downloads/
✓ Completed Download Folder: /downloads/
✓ Watched Folder: /downloads/nzb-watch/

Config → General:
✓ Web Server: 0.0.0.0:8085
✓ URL Base: /sab/  (for reverse proxy)
✓ API Key: [Generate and copy for *arr apps]

Config → Switches:
✓ Pre-check completeness: ON
✓ Abort jobs that cannot be completed: ON
✓ Pause downloading during post-processing: ON
```

---

## 🔗 *arr Applications Configuration

### **Connection Settings for Download Clients**

#### **In Sonarr (Settings → Download Clients)**

**qBittorrent Configuration:**
```
Name: qBittorrent
Implementation: qBittorrent  
Host: gluetun
Port: 8080
Username: admin
Password: [your qBittorrent password]
Category: tv
URL Base: [leave empty]
```

**SABnzbd Configuration:**
```  
Name: SABnzbd
Implementation: SABnzbd
Host: gluetun
Port: 8085
API Key: [from SABnzbd config]
Category: tv
URL Base: [leave empty]
```

#### **In Radarr (Settings → Download Clients)**
- Same as Sonarr but use `Category: movies`

#### **In Lidarr (Settings → Download Clients)**  
- Same as Sonarr but use `Category: music`

### **Media Management Settings**

#### **Root Folder Configuration**
```
Sonarr:   /media/tv/
Radarr:   /media/movies/
Lidarr:   /media/music/
```

#### **Import Settings**
```
Settings → Media Management:
✓ Use Hardlinks instead of Copy: ENABLED
✓ Import Extra Files: ENABLED  
✓ Unmonitor Deleted Episodes/Movies: ENABLED
✓ Propers and Repacks: Do not upgrade automatically
✓ Analyse video files: ENABLED
✓ Skip Free Space Check: DISABLED
```

---

## 🔍 Prowlarr Indexer Configuration

### **Application Connections**
**Settings → Apps → Add Application:**

```
Sonarr:
- Prowlarr Server: http://prowlarr:9696
- Sonarr Server: http://sonarr:8989  
- API Key: [Sonarr API key]

Radarr:
- Prowlarr Server: http://prowlarr:9696
- Radarr Server: http://radarr:7878
- API Key: [Radarr API key]

Lidarr:  
- Prowlarr Server: http://prowlarr:9696
- Lidarr Server: http://lidarr:8686
- API Key: [Lidarr API key]
```

### **Download Client Sync in Prowlarr**
**Settings → Download Clients:**

```
qBittorrent:
- Host: gluetun
- Port: 8080
- Category: prowlarr

SABnzbd:
- Host: gluetun  
- Port: 8085
- Category: prowlarr
```

---

## 🧪 Testing & Verification

### **Connection Testing Commands**
```bash
# Test *arr app to download client connectivity
sudo podman exec -it sonarr curl -I http://gluetun:8080     # qBittorrent
sudo podman exec -it sonarr curl -I http://gluetun:8085     # SABnzbd

# Test Prowlarr to *arr app connectivity  
sudo podman exec -it prowlarr curl -I http://sonarr:8989
sudo podman exec -it prowlarr curl -I http://radarr:7878
sudo podman exec -it prowlarr curl -I http://lidarr:8686

# Test DNS resolution
sudo podman exec -it sonarr nslookup gluetun
```

### **Volume Mount Verification**
```bash
# Check if paths exist and are writable
sudo podman exec -it sonarr ls -la /media /processing /hot-downloads /cache
sudo podman exec -it qbittorrent ls -la /downloads /cache
sudo podman exec -it sabnzbd ls -la /downloads /incomplete-downloads
```

### **Download Test Workflow**
1. **Add a test download** in Sonarr/Radarr manually
2. **Check download appears** in qBittorrent/SABnzbd with correct category
3. **Verify download location** matches expected hot storage path
4. **Confirm import** moves file from processing to final media location

---

## 🚨 Common Issues & Solutions

### **Connection Failures**
**Symptom**: *arr apps can't connect to download clients
**Solution**: Verify container network and use `gluetun:PORT`, not `localhost:PORT`

### **Downloads Not Importing**  
**Symptom**: Downloads complete but don't import to media library
**Solution**: Check category configuration and volume mounts match

### **VPN IP Leaks**
**Symptom**: Download clients showing real IP instead of VPN IP
**Solution**: Verify containers use `network: "vpn"` and share Gluetun network

### **Storage Permission Issues**
**Symptom**: Import failures due to permission denied
**Solution**: Check `/mnt/hot` and `/mnt/media` ownership is `eric:users`

---

## 📋 Configuration Checklist

### **Pre-Setup Verification**
- [ ] All containers running and healthy
- [ ] VPN connection active (check IP in Gluetun)
- [ ] Storage mounts accessible with correct permissions
- [ ] API keys collected from all services

### **Download Client Setup**
- [ ] qBittorrent categories created (tv, movies, music)
- [ ] SABnzbd categories configured with correct folders
- [ ] Download paths point to `/downloads/` or appropriate subdirectories
- [ ] Connection test successful from *arr apps

### **Media Management Setup**  
- [ ] Root folders configured (`/media/tv`, `/media/movies`, `/media/music`)
- [ ] Import settings configured (hardlinks, extra files, etc.)
- [ ] Download client connections added to each *arr app
- [ ] Test downloads import successfully

### **Prowlarr Integration**
- [ ] *arr applications connected to Prowlarr
- [ ] Download clients configured in Prowlarr
- [ ] Indexers added and working
- [ ] Sync test successful

This guide provides the complete technical foundation for your media pipeline. Each section can be referenced independently when configuring specific components!