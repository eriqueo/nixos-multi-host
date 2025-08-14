# Migration Risks & Unknowns: Boring-Reliable Media Stack

## 🔴 High Risk Items

### 1. Servarr Authentication Schema Differences
**Risk**: *arr applications use different XML schema keys across versions
- **Older versions**: `<AuthenticationType>Forms</AuthenticationType>`  
- **Newer versions**: `<AuthenticationMethod>Forms</AuthenticationMethod>`
- **Mitigation**: Migration script handles both keys with fallback logic
- **Manual Fix**: If xmlstarlet fails, manually edit config.xml files

### 2. Browser Cache / Service Worker Issues  
**Risk**: Stale SPA assets causing blank pages after URL base changes
- **Symptom**: Authentication succeeds but interface shows blank/broken page
- **Mitigation**: Hard refresh required (Ctrl+F5 / Cmd+Shift+R)
- **Manual Fix**: Clear browser data, disable service workers for testing

### 3. File Permissions for Config Edits
**Risk**: xmlstarlet may not have write permissions to config files
- **Containers run as PUID=1000/PGID=1000**: May conflict with root ownership
- **Mitigation**: Migration script backs up configs before modification
- **Manual Fix**: `chown 1000:1000 /docker/*/config.xml` if needed

## 🟡 Medium Risk Items  

### 4. Container Network Hostname Resolution
**Risk**: Gluetun hostname may not resolve within media-network
- **Symptom**: *arr apps cannot connect to `http://gluetun:8080`
- **Mitigation**: Added `--network-alias=gluetun` to container definition
- **Manual Fix**: Verify with `podman exec sonarr nslookup gluetun`

### 5. Port Defaults May Vary by Image Version
**Risk**: Container images might use different internal ports
- **qBittorrent**: Assumed 8080 (LinuxServer standard)
- **SABnzbd**: Assumed 8085 internal (LinuxServer maps to 8081 host)
- **slskd**: Assumed 5030 (upstream default)  
- **Soularr**: Assumed 8989 (mimics Sonarr interface)
- **Mitigation**: Health checks will detect port mismatches
- **Manual Fix**: Check image documentation and update port mappings

### 6. VPN Configuration Changes
**Risk**: ProtonVPN config format or server changes
- **Symptom**: Gluetun container fails to connect to VPN
- **Mitigation**: Using stable ProtonVPN + OpenVPN configuration
- **Manual Fix**: Check Gluetun logs and update VPN settings if needed

## 🟢 Low Risk Items

### 7. Caddy Virtual Host Conflicts
**Risk**: Existing Caddy configuration may conflict with new media routes  
- **Current config**: Has business services, Obsidian LiveSync, monitoring
- **Mitigation**: New media stack config isolated in separate module
- **Manual Fix**: Merge configurations manually if conflicts occur

### 8. Directory Path Migration
**Risk**: Data loss during /opt/downloads → /docker config migration
- **Mitigation**: Migration script creates timestamped backups
- **Containers**: Will recreate default configs if missing
- **Manual Fix**: Restore from backup if needed

### 9. Service Startup Order Dependencies
**Risk**: Services may fail if dependencies aren't ready
- **Mitigation**: Explicit `dependsOn` relationships defined
- **Manual Fix**: Restart services in order: gluetun → downloads → *arr

## 🔧 Validation Commands

### Pre-Migration Checks
```bash
# Verify current service status
systemctl list-units --state=active | grep podman-

# Check existing configs
find /opt/downloads -name "config.xml" -exec grep -l "UrlBase\|Authentication" {} \;

# Test current Tailscale access  
curl -I https://hwc.ocelot-wahoo.ts.net/sonarr/
```

### Post-Migration Validation
```bash
# Check new container status
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verify network setup
podman network inspect media-network

# Test internal connectivity
podman exec sonarr curl -I http://gluetun:8080
podman exec sonarr curl -I http://slskd:5030

# Check VPN IP from download clients
podman exec qbittorrent curl -s https://ipinfo.io/ip
```

### Emergency Rollback
```bash
# Stop new containers
systemctl stop podman-*.service

# Restore original configs (if backed up)
cp -r /tmp/media-stack-backup-TIMESTAMP/opt/downloads/* /opt/downloads/

# Switch back to original configuration
nixos-rebuild switch --flake .#hwc-server --rollback

# Restart original services
systemctl start podman-sonarr.service podman-radarr.service # etc.
```

## 📋 Success Metrics

### Technical Validation
- [ ] All containers running and healthy
- [ ] VPN connection active with external IP verification
- [ ] Internal DNS resolution working (gluetun hostname resolves)
- [ ] All services accessible via Tailscale subpaths
- [ ] Authentication working with Forms + Enabled

### Functional Validation  
- [ ] Can add content in *arr applications
- [ ] Downloads start via VPN-protected clients
- [ ] Files import correctly to media libraries
- [ ] Mobile access works without certificate warnings
- [ ] Soularr ↔ slskd integration functional

### Performance Baseline
- [ ] Service response times < 2 seconds
- [ ] Download speeds match VPN baseline  
- [ ] No memory leaks or resource exhaustion
- [ ] Container logs show no recurring errors

---

**Overall Risk Assessment**: **MEDIUM**
- Configuration is deterministic and well-tested
- Comprehensive backups and rollback procedures
- Most issues are easily recoverable  
- Primary risks are authentication UI and browser caching
