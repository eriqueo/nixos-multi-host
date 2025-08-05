# Server Troubleshooting Guide

**Last Updated:** August 1, 2025  
**Server:** homeserver (NixOS 25.11)  
**Purpose:** Comprehensive troubleshooting documentation for server configuration and reverse proxy setup

---

## ✅ RESOLVED ISSUES

### 1. SOPS Configuration - RESOLVED ✅
**Status:** FULLY RESOLVED  
**Solution Applied:** Used deployment script `/etc/nixos/scripts/deploy-age-keys.sh`  
**Result:** SOPS now fully functional, all secrets accessible

#### What was fixed:
- Missing age keys at `/etc/sops/age/keys.txt`
- SOPS decrypt operations now working
- All encrypted secrets properly accessible

---

### 2. Git Repository Setup - RESOLVED ✅
**Status:** FULLY RESOLVED  
**Solution Applied:** 
- Generated SSH keys for GitHub access
- Initialized git repository in `/etc/nixos`
- Connected to `nixos-multi-host` repository
- Resolved branch alignment (main vs master)

#### Configuration:
```bash
# SSH key generated and added to GitHub
ssh-keygen -t ed25519 -C "homeserver@nixos"
# Repository connected
git remote add origin git@github.com:username/nixos-multi-host.git
# Branch aligned to master (default branch)
git branch -M master
```

---

### 3. CouchDB Service Failure - RESOLVED ✅
**Status:** FULLY RESOLVED  
**Solution Applied:** Refactored into focused modules with proper service ordering

#### New Module Structure:
- **`couchdb-setup.nix`** - SOPS secrets + setup service that runs BEFORE CouchDB
- **`caddy-config.nix`** - Reverse proxy configuration  
- **`obsidian-livesync.nix`** - Obsidian-specific monitoring

#### Key Fix - Service Ordering:
```nix
systemd.services.couchdb-config-setup = {
  description = "Setup CouchDB admin configuration from SOPS secrets";
  before = [ "couchdb.service" ];  # Runs BEFORE CouchDB starts
  wantedBy = [ "couchdb.service" ];
  wants = [ "sops-install-secrets.service" ];
  after = [ "sops-install-secrets.service" ];
  # Creates /var/lib/couchdb/local.ini with admin credentials
};
```

---

### 4. VPN Credentials Hardcoding - RESOLVED ✅
**Status:** FULLY RESOLVED  
**Solution Applied:** Integrated SOPS secrets for VPN credentials

#### SOPS Integration:
```nix
sops.secrets.vpn_username = {
  sopsFile = ../../../secrets/admin.yaml;
  key = "vpn/protonvpn/username";
  mode = "0400";
};

systemd.services.gluetun-env-setup = {
  # Generates /opt/downloads/.env from SOPS secrets
  script = ''
    VPN_USERNAME=$(cat ${config.sops.secrets.vpn_username.path})
    VPN_PASSWORD=$(cat ${config.sops.secrets.vpn_password.path})
    # Creates environment file for Gluetun
  '';
};
```

---

### 5. Container Directory Persistence - RESOLVED ✅
**Status:** FULLY RESOLVED  
**Solution Applied:** Added missing directories to NixOS tmpfiles system

#### Directories Added:
```nix
# In /etc/nixos/modules/filesystem/service-directories.nix
systemd.tmpfiles.rules = [
  "d /opt/downloads/sabnzbd 0755 eric users -"
  "d /opt/downloads/slskd 0755 eric users -" 
  "d /opt/downloads/soularr 0755 eric users -"
  "d /opt/downloads/gluetun 0755 eric users -"
];
```

---

### 6. File Naming Issue - RESOLVED ✅
**Status:** FULLY RESOLVED  
**Solution Applied:** Renamed `media-containers-v2.nix` to `media-containers.nix`
**Result:** Clean, descriptive filename without version suffix

---

## 🟡 CURRENT WORK IN PROGRESS

### 7. Reverse Proxy *arr Applications Configuration
**Status:** IN PROGRESS - Permanent Solution Implemented  
**Domain:** `https://hwc.ocelot-wahoo.ts.net/`

#### Domain Resolution Fixed:
- **Previous Issue:** `heartwood.ocelot-wahoo.ts.net` resolved to wrong machine (`100.110.68.48`)
- **Solution:** Changed to `hwc.ocelot-wahoo.ts.net` which correctly resolves to this server (`100.115.126.41`)
- **Benefit:** Will work consistently regardless of network location (uses hostname, not hardcoded IP)

#### Services Status:
✅ **Working Services:**
- `/sync/` → CouchDB (Obsidian LiveSync) - HTTP/2 401 (auth required)
- `/qbt/` → qBittorrent - HTTP/2 200 ✅
- `/media/` → Jellyfin - accessible
- `/navidrome/` → Music streaming - HTTP/2 405 (method not allowed for HEAD - normal)
- `/dashboard/` → Business services - HTTP/2 200 ✅
- `/immich/` → Photo management - accessible

🔴 **Issues Identified:**
- `/sonarr/`, `/radarr/`, `/lidarr/`, `/prowlarr/` - URL base not configured

#### Root Cause Analysis:
Based on Trash Guides research, *arr applications need URL base configured in their `config.xml` files, not environment variables.

**Current Config Files:**
```xml
<!-- All show empty URL base -->
<UrlBase></UrlBase>
```

**Required Config:**
```xml
<UrlBase>/sonarr</UrlBase>  <!-- for Sonarr -->
<UrlBase>/radarr</UrlBase>  <!-- for Radarr -->
<UrlBase>/lidarr</UrlBase>  <!-- for Lidarr -->
<UrlBase>/prowlarr</UrlBase> <!-- for Prowlarr -->
```

#### Permanent Solution Implemented:
Created automated systemd service `arr-urlbase-setup` that:

1. **Waits for containers to initialize** (30 second delay)
2. **Updates each config.xml file** using sed to replace empty `<UrlBase></UrlBase>` with correct paths
3. **Restarts containers** to apply configuration changes
4. **Runs automatically** on system boot and after container services start

**Service Configuration:**
```nix
systemd.services.arr-urlbase-setup = {
  description = "Configure *arr applications URL base for reverse proxy";
  after = [ "podman-sonarr.service" "podman-radarr.service" "podman-lidarr.service" "podman-prowlarr.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    User = "root";
  };
  script = ''
    # Function to update URL base in config.xml
    update_urlbase() {
      local app="$1"
      local urlbase="/$1"
      local config_file="/opt/downloads/$app/config.xml"
      
      if [ -f "$config_file" ]; then
        echo "Updating $app URL base to $urlbase"
        sed -i "s|<UrlBase></UrlBase>|<UrlBase>$urlbase</UrlBase>|g" "$config_file"
        echo "Updated $app config"
      else
        echo "Warning: $config_file not found"
      fi
    }
    
    # Update each *arr application
    update_urlbase "sonarr"
    update_urlbase "radarr" 
    update_urlbase "lidarr"
    update_urlbase "prowlarr"
    
    # Restart containers to apply config changes
    systemctl restart podman-sonarr.service
    systemctl restart podman-radarr.service  
    systemctl restart podman-lidarr.service
    systemctl restart podman-prowlarr.service
  '';
};
```

#### Next Steps:
1. **Run `sudo nixos-rebuild switch`** to apply the permanent solution
2. **Verify service execution:** `sudo systemctl status arr-urlbase-setup.service`
3. **Test all *arr endpoints** via reverse proxy
4. **Document final working configuration**

---

## 📊 SERVICE OVERVIEW

### Container Services Status:
```bash
# All running successfully:
podman-alertmanager.service       ✅ active (running)
podman-blackbox-exporter.service  ✅ active (running)
podman-business-dashboard.service ✅ active (running)
podman-business-metrics.service   ✅ active (running)
podman-gluetun.service            ✅ active (running)
podman-grafana.service            ✅ active (running)
podman-home-assistant.service     ✅ active (running)
podman-lidarr.service             ✅ active (running)
podman-navidrome.service          ✅ active (running)
podman-prometheus.service         ✅ active (running)
podman-prowlarr.service           ✅ active (running)
podman-qbittorrent.service        ✅ active (running)
podman-radarr.service             ✅ active (running)
podman-sabnzbd.service            ✅ active (running)
podman-slskd.service              ✅ active (running)
podman-sonarr.service             ✅ active (running)
podman-soularr.service            ✅ active (running)
```

### Native Services Status:
```bash
couchdb.service     ✅ active (running) - port 5984
caddy.service       ✅ active (running) - reverse proxy
jellyfin.service    ✅ active (running) - port 8096
immich-server.service ✅ active (running) - port 2283
tailscale.service   ✅ active (running)
```

### Port Mappings:
```bash
5984  - CouchDB (localhost only)
8080  - qBittorrent (via Gluetun)
8081  - SABnzbd (via Gluetun)
8989  - Sonarr
7878  - Radarr
8686  - Lidarr
9696  - Prowlarr
4533  - Navidrome
8096  - Jellyfin
2283  - Immich
8123  - Home Assistant
8501  - Business Dashboard
```

---

## 🔧 MAINTENANCE COMMANDS

### Essential Debugging Commands:
```bash
# Check all container services
systemctl list-units --type=service --state=running | grep podman

# Check reverse proxy
curl -I https://hwc.ocelot-wahoo.ts.net/SERVICE_PATH/

# Check SOPS functionality
sudo sops -d /etc/nixos/secrets/admin.yaml

# Check Tailscale status
tailscale status

# Rebuild system configuration
sudo nixos-rebuild switch

# Check specific service logs
sudo journalctl -u SERVICE_NAME --no-pager -n 20
```

### Config File Locations:
```bash
# *arr applications
/opt/downloads/sonarr/config.xml
/opt/downloads/radarr/config.xml
/opt/downloads/lidarr/config.xml
/opt/downloads/prowlarr/config.xml

# CouchDB
/var/lib/couchdb/local.ini

# VPN credentials
/opt/downloads/.env (generated from SOPS)
```

---

## 📝 ARCHITECTURAL IMPROVEMENTS MADE

### Module Refactoring:
- **Before:** Monolithic `obsidian-sync.nix` 
- **After:** Focused modules:
  - `couchdb-setup.nix` - Database with SOPS integration
  - `caddy-config.nix` - Reverse proxy configuration  
  - `obsidian-livesync.nix` - Monitoring

### Security Enhancements:
- All hardcoded credentials replaced with SOPS secrets
- Proper service ordering to prevent chicken-and-egg problems
- Automated configuration management prevents manual errors

### Network Architecture:
- **Tailscale Domain:** `hwc.ocelot-wahoo.ts.net` (location-independent)
- **Reverse Proxy:** Caddy with automatic HTTPS
- **VPN Gateway:** Gluetun for download clients
- **Container Network:** Isolated media-network for internal communication

---

## 🎯 SUCCESS METRICS

- ✅ **SOPS Integration:** 100% functional
- ✅ **Git Repository:** Fully connected and automated
- ✅ **CouchDB:** Running and accessible via reverse proxy
- ✅ **VPN Security:** No hardcoded credentials
- ✅ **Service Dependencies:** Proper ordering implemented
- ✅ **Reverse Proxy:** Most services working via HTTPS
- 🟡 ***arr Applications:** Permanent solution implemented, pending verification

**Infrastructure is now production-ready for transport to home network.**