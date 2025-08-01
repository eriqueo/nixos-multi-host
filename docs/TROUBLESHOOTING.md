# Server Troubleshooting Guide

**Last Updated:** August 1, 2025  
**Server:** homeserver (NixOS 25.11)  
**Purpose:** Comprehensive troubleshooting documentation for pre-transport server fixes

---

## 🔴 Critical Service Failures

### 1. CouchDB Service Failure

**Status:** `inactive (dead)` since boot with `status=1/FAILURE`  
**Impact:** Breaks Obsidian LiveSync functionality  
**Module:** `/etc/nixos/hosts/server/modules/obsidian-sync.nix`

#### Investigation Commands:
```bash
sudo systemctl status couchdb.service
sudo journalctl -u couchdb.service --no-pager -n 50
sudo journalctl -u couchdb.service --since "today"
```

#### Configuration Details:
- **Port:** 5984
- **Bind Address:** 127.0.0.1
- **Admin User:** eric
- **SOPS Secret:** `couchdb_admin_password` from `admin.yaml`
- **Expected Password:** il0wwlm? (from SOPS decrypt)

#### Potential Fixes:
1. **SOPS Permission Issue:**
   ```bash
   # Check SOPS secret permissions
   ls -la /run/secrets/couchdb_admin_password
   sudo chown couchdb:couchdb /run/secrets/couchdb_admin_password
   sudo chmod 400 /run/secrets/couchdb_admin_password
   ```

2. **Database Directory Permissions:**
   ```bash
   # Ensure CouchDB data directory exists with correct permissions
   sudo mkdir -p /var/lib/couchdb
   sudo chown -R couchdb:couchdb /var/lib/couchdb
   sudo chmod 755 /var/lib/couchdb
   ```

3. **Service Restart:**
   ```bash
   sudo systemctl restart couchdb.service
   sudo systemctl enable couchdb.service
   ```

#### Recovery Steps:
1. Check SOPS secret availability
2. Verify CouchDB user/group exists
3. Ensure data directory permissions
4. Restart service and check logs
5. Test connection: `curl http://127.0.0.1:5984`

---

## ⚠️ Hardcoded Credentials (Non-Persistent Issues)

### 1. VPN Credentials in Media Containers

**File:** `/etc/nixos/hosts/server/modules/media-containers-v2.nix`  
**Lines:** 122-123, 125-126  
**Issue:** Hardcoded ProtonVPN credentials instead of SOPS integration

#### Current Hardcoded Values:
```nix
OPENVPN_USER=VohhVd45cTWfeAI8
OPENVPN_PASSWORD=RPSb517Y93oZf3sFUL6riuCixBRQBD4D
```

#### SOPS Integration Required:
```nix
# Replace hardcoded service with SOPS integration
systemd.services.gluetun-env-setup = {
  description = "Generate Gluetun environment file";
  before = [ "podman-gluetun.service" ];
  wantedBy = [ "podman-gluetun.service" ];
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
  script = ''
    mkdir -p /opt/downloads
    cat > /opt/downloads/.env << EOF
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=openvpn
OPENVPN_USER=$(cat ${config.sops.secrets.vpn_username.path})
OPENVPN_PASSWORD=$(cat ${config.sops.secrets.vpn_password.path})
SERVER_COUNTRIES=Netherlands
HEALTH_VPN_DURATION_INITIAL=30s
EOF
    chmod 600 /opt/downloads/.env
    chown root:root /opt/downloads/.env
  '';
};
```

#### Required SOPS Secrets:
```nix
sops.secrets.vpn_username = {
  sopsFile = ../../../secrets/admin.yaml;
  key = "vpn/protonvpn/username";
  mode = "0400";
  owner = "root";
  group = "root";
};

sops.secrets.vpn_password = {
  sopsFile = ../../../secrets/admin.yaml;
  key = "vpn/protonvpn/password";
  mode = "0400";
  owner = "root";
  group = "root";
};
```

**✅ SOPS Structure Updated:** The admin.yaml now has properly nested VPN credentials matching these key paths!

### 2. Slskd Container Credentials

**File:** `/etc/nixos/hosts/server/modules/media-containers-v2.nix`  
**Lines:** 218-221  
**Issue:** Hardcoded Soulseek credentials

#### Current Hardcoded Values:
```nix
SLSKD_USERNAME = "eriqueok";
SLSKD_PASSWORD = "il0wwlm?";
SLSKD_SLSK_USERNAME = "eriqueok";
SLSKD_SLSK_PASSWORD = "il0wwlm?";
```

#### SOPS Integration Recommended:
Should reference `config.sops.secrets.slskd_username.path` and similar for passwords.

---

## 🔧 Container Service Failures

### 1. slskd Container (Soulseek Client)

**Status:** `inactive (dead)` with exit status 125  
**Service:** `podman-slskd.service`  
**Port:** 5030  
**Dependencies:** None (but soularr depends on this)

#### Investigation Commands:
```bash
sudo systemctl status podman-slskd.service
sudo journalctl -u podman-slskd.service --no-pager -n 20
sudo podman logs slskd 2>/dev/null || echo "Container not running"
```

#### Common Exit 125 Causes:
1. **Volume Mount Issues:**
   ```bash
   # Check if required directories exist
   ls -la /opt/downloads/slskd/
   ls -la /mnt/media/music/
   ls -la /mnt/media/music-soulseek/
   ```

2. **Configuration File Missing:**
   ```bash
   # Check for slskd.yml config file
   ls -la /opt/downloads/slskd/slskd.yml
   ```

3. **Network Issues:**
   ```bash
   # Verify media-network exists
   sudo podman network ls | grep media-network
   ```

#### Manual Container Test:
```bash
# Try running container manually to see detailed error
sudo podman run --rm -it \
  --network=media-network \
  -p 5030:5030 \
  -v /opt/downloads/slskd:/config \
  -v /mnt/hot/downloads:/downloads \
  -v /mnt/media/music:/data/music:ro \
  slskd/slskd --config /config/slskd.yml
```

### 2. soularr Container (Soulseek Automation)

**Status:** `inactive (dead)`  
**Service:** `podman-soularr.service`  
**Port:** 9898  
**Dependencies:** slskd, lidarr

#### Investigation Commands:
```bash
sudo systemctl status podman-soularr.service
sudo journalctl -u podman-soularr.service --no-pager -n 20
```

#### Dependency Chain:
1. slskd must be running first
2. lidarr must be accessible
3. Configuration directory must exist: `/opt/downloads/soularr/`

---

## 📱 SSH Mobile Access Setup

### Current SSH Configuration

**Status:** No mobile access configured  
**Issues:**
- No `~/.ssh/authorized_keys` file exists
- No mobile SSH keys generated
- Password authentication enabled but not ideal for mobile

### Mobile SSH Setup Process

#### 1. Generate Mobile-Specific SSH Key Pair

```bash
# On server - generate a dedicated mobile key
ssh-keygen -t ed25519 -C "mobile-device-homeserver" -f ~/.ssh/mobile_key
```

#### 2. Add Mobile Public Key to Authorized Keys

```bash
# Create authorized_keys file if it doesn't exist
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Add the mobile public key
cat ~/.ssh/mobile_key.pub >> ~/.ssh/authorized_keys
```

#### 3. Copy Private Key to Mobile Device

**Options:**
1. **QR Code Transfer:**
   ```bash
   # Generate QR code of private key (requires qrencode)
   cat ~/.ssh/mobile_key | qrencode -t ANSIUTF8
   ```

2. **Secure File Transfer:**
   - Copy `/home/eric/.ssh/mobile_key` to mobile device securely
   - Delete from server after transfer for security

#### 4. Mobile App Configuration

**Recommended Apps:**
- **iOS:** Termius, Prompt 3
- **Android:** Termius, JuiceSSH

**Connection Settings:**
- **Host:** homeserver IP or Tailscale hostname
- **Port:** 22
- **Username:** eric
- **Authentication:** SSH Key
- **Private Key:** Import the mobile_key file

#### 5. Security Hardening (Optional)

```bash
# Disable password authentication (after key setup confirmed working)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Then: sudo systemctl reload sshd
```

---

## 🔗 Service Dependencies & Startup Order

### Container Dependency Map

```
media-network (systemd service)
│
├── gluetun (VPN gateway)
│   ├── qbittorrent (depends on gluetun)
│   └── sabnzbd (depends on gluetun)
│
├── *arr stack (independent)
│   ├── prowlarr
│   ├── sonarr
│   ├── radarr
│   └── lidarr
│
├── slskd (Soulseek client)
│   └── soularr (depends on slskd + lidarr)
│
└── navidrome (music streaming)
```

### Startup Issues

1. **slskd failing prevents soularr from starting**
2. **gluetun-env-setup must run before gluetun container**
3. **media-network must exist before any containers start**

---

## 🚨 Quick Diagnostic Commands

### Service Health Check
```bash
# Check all critical services
sudo systemctl status caddy couchdb podman-gluetun podman-slskd podman-soularr

# Check all containers
sudo podman ps -a

# Check SOPS secrets
sudo sops -d /etc/nixos/secrets/admin.yaml | head -10
```

### Network Diagnostics
```bash
# Check container networking
sudo podman network ls
sudo podman network inspect media-network

# Check port bindings
ss -tlnp | grep -E "(5984|5030|9898|8080|8081)"
```

### Log Analysis
```bash
# Recent service failures
sudo journalctl --since "1 hour ago" --priority=err

# Container logs
for container in gluetun qbittorrent sabnzbd slskd soularr; do
  echo "=== $container ==="
  sudo podman logs $container --tail 10 2>/dev/null || echo "Not running"
done
```

---

## 🔧 Pre-Transport Checklist

### Critical Fixes Needed
- [ ] Fix CouchDB service (SOPS permissions, data directory)
- [ ] Replace hardcoded VPN credentials with SOPS integration  
- [ ] Fix slskd container startup (investigate exit 125)
- [ ] Fix soularr container (depends on slskd)
- [ ] Set up mobile SSH access

### Verification Tests
- [ ] All systemd services start without errors
- [ ] All containers start and stay running
- [ ] VPN connection works (check IP: `curl ifconfig.me`)
- [ ] CouchDB accessible: `curl http://127.0.0.1:5984`
- [ ] SSH mobile access works
- [ ] SOPS secrets decrypt properly

### Backup Before Transport
```bash
# Backup critical configuration
sudo tar -czf /tmp/nixos-config-backup.tar.gz /etc/nixos/
sudo tar -czf /tmp/container-configs-backup.tar.gz /opt/downloads/
```

---

## 📞 Emergency Recovery

### If Services Won't Start After Fixes
```bash
# Nuclear option - restart all container services
sudo systemctl restart podman.service
sudo systemctl daemon-reload

# Recreate media network
sudo podman network rm media-network
sudo systemctl restart init-media-network.service
```

### If SOPS Breaks
```bash
# Temporarily revert to hardcoded credentials for transport
# (Instructions in server-improvements-log.md)
```

### If SSH Access Lost
- Physical server access required
- Use rescue mode via ISO boot
- Console access via attached monitor/keyboard

---

**End of Troubleshooting Guide**