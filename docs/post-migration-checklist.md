# Post-Migration Checklist: Boring-Reliable Media Stack

## ✅ Service Access Verification

### 1. *arr Applications Authentication
- [ ] **Sonarr**: https://hwc.ocelot-wahoo.ts.net/sonarr/
  - [ ] Shows Forms login page (not blank page)
  - [ ] Settings → General → Authentication: `Forms` + `Enabled`
  - [ ] Settings → General → URL Base: `/sonarr`
- [ ] **Radarr**: https://hwc.ocelot-wahoo.ts.net/radarr/
  - [ ] Shows Forms login page (not blank page)  
  - [ ] Settings → General → Authentication: `Forms` + `Enabled`
  - [ ] Settings → General → URL Base: `/radarr`
- [ ] **Lidarr**: https://hwc.ocelot-wahoo.ts.net/lidarr/
  - [ ] Shows Forms login page (not blank page)
  - [ ] Settings → General → Authentication: `Forms` + `Enabled` 
  - [ ] Settings → General → URL Base: `/lidarr`
- [ ] **Prowlarr**: https://hwc.ocelot-wahoo.ts.net/prowlarr/
  - [ ] Shows Forms login page (not blank page)
  - [ ] Settings → General → Authentication: `Forms` + `Enabled`
  - [ ] Settings → General → URL Base: `/prowlarr`

### 2. New Services
- [ ] **Soularr**: https://hwc.ocelot-wahoo.ts.net/soularr/
  - [ ] Web interface loads correctly
  - [ ] Can configure Lidarr connection
- [ ] **slskd**: https://hwc.ocelot-wahoo.ts.net/slskd/
  - [ ] Soulseek client interface accessible
  - [ ] Can configure download directory: `/downloads`

### 3. Download Clients (VPN-routed)
- [ ] **qBittorrent**: https://hwc.ocelot-wahoo.ts.net/qbt/
  - [ ] Interface accessible via Gluetun proxy
  - [ ] External IP shows VPN location (not local ISP)
- [ ] **SABnzbd**: https://hwc.ocelot-wahoo.ts.net/sab/
  - [ ] Interface accessible via Gluetun proxy  
  - [ ] External IP shows VPN location (not local ISP)

## 🔗 Inter-Service Configuration

### 1. Prowlarr → *arr Integration
Configure applications in Prowlarr with **internal container URLs**:
- [ ] **Sonarr**: `http://sonarr:8989` (not hwc.ocelot-wahoo.ts.net)
- [ ] **Radarr**: `http://radarr:7878`
- [ ] **Lidarr**: `http://lidarr:8686`

### 2. *arr → Download Client Integration
Configure download clients in each *arr app:
- [ ] **qBittorrent**: `http://gluetun:8080` 
  - [ ] Test connection successful
  - [ ] Category mapping configured
- [ ] **SABnzbd**: `http://gluetun:8081`
  - [ ] Test connection successful  
  - [ ] Category mapping configured

### 3. Soularr ↔ slskd Integration  
- [ ] **Soularr → Lidarr**: Internal connection at `http://lidarr:8686`
- [ ] **Soularr → slskd**: Internal connection for downloads
- [ ] **Download Directory**: `/downloads` mapping verified
- [ ] **Music Library**: `/music` read-only access for sharing ratio

## 📱 Mobile/Remote Access

### 1. Tailscale Certificate Validation
- [ ] **Certificate Valid**: No browser warnings on mobile
- [ ] **DNS Resolution**: `hwc.ocelot-wahoo.ts.net` resolves correctly
- [ ] **All Subpaths**: Every service accessible at `/servicename/`

### 2. Mobile Interface Testing
Test on phone/tablet over Tailscale:
- [ ] All service interfaces render properly
- [ ] Authentication flows work correctly  
- [ ] No broken assets or 404 errors on SPA routes
- [ ] **Hard refresh performed** (clear service worker cache)

## 🧪 End-to-End Workflow Test

### 1. Add Test Content
- [ ] **Prowlarr**: Add indexer and test search
- [ ] **Sonarr**: Add test TV series, trigger search
- [ ] **Radarr**: Add test movie, trigger search  
- [ ] **Lidarr**: Add test album, trigger search
- [ ] **Soularr**: Configure music discovery and test

### 2. Download Pipeline Verification
- [ ] **Downloads Start**: qBittorrent/SABnzbd receive jobs
- [ ] **VPN Protection**: Downloads show VPN IP (not local ISP)
- [ ] **Directory Mapping**: Files appear in correct `/mnt/media/downloads/` subdirs
- [ ] **Import Process**: *arr apps detect and import completed downloads
- [ ] **Final Storage**: Media appears in `/mnt/media/{tv,movies,music}/`

## ⚠️ Troubleshooting Checklist

### 1. Service Won't Start
- [ ] Check logs: `journalctl -fu podman-SERVICENAME.service`
- [ ] Verify container status: `podman ps`
- [ ] Check network: `podman network ls` (media-network exists?)
- [ ] Verify volumes: Directory permissions and ownership correct?

### 2. Authentication Issues  
- [ ] **Config Files**: Check `/docker/SERVICE/config.xml` has Forms + Enabled
- [ ] **URL Base**: Matches subpath (`/sonarr` etc.)
- [ ] **Browser Cache**: Hard refresh performed (Ctrl+F5)
- [ ] **Service Worker**: Clear browser data if SPA assets cached

### 3. VPN Issues
- [ ] **Gluetun Status**: `systemctl status podman-gluetun.service`
- [ ] **VPN Connection**: Check Gluetun logs for connection success
- [ ] **Download Clients**: Can access via `http://gluetun:PORT` from *arr apps
- [ ] **External IP**: Download clients show VPN IP, not local ISP

### 4. Network Connectivity
- [ ] **Container Network**: `podman network inspect media-network`
- [ ] **DNS Resolution**: Can containers resolve `gluetun`, `sonarr`, etc.?
- [ ] **Port Bindings**: Only 127.0.0.1:PORT exposed, not 0.0.0.0:PORT
- [ ] **Firewall**: Only 80/443 open publicly

## 📊 Success Criteria Summary

### Core Requirements Met:
- ✅ All services accessible via Tailscale at `/servicename/` subpaths
- ✅ Deterministic Forms authentication (no DisabledForLocalAddresses)  
- ✅ VPN-routed downloads with IP verification
- ✅ Internal container networking for *arr ↔ download client communication
- ✅ Soularr + slskd integration functional
- ✅ Mobile access working with valid certificates

### Post-Migration Actions:
1. **Create initial user accounts** in each *arr application  
2. **Configure indexers** in Prowlarr and sync to applications
3. **Set up download client categories** and path mappings
4. **Test complete workflow** with actual content
5. **Monitor system** for 24-48 hours to ensure stability

---

**Migration completed successfully when all checkboxes are ✅**  
**Next step**: Begin normal media management operations
