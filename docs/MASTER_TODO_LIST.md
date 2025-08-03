# Master TODO List

## Current Active Tasks
*Updated: 2025-08-03*

### High Priority (Immediate Action Required)

#### 🔴 System Deployment
- [ ] **Deploy Frigate fixes**: Run `grebuild "Fix Frigate camera configuration and enable GPU monitoring"`
- [ ] **Verify camera streams**: Check Frigate web interface at http://localhost:5000 after deployment
- [ ] **Test GPU metrics**: Validate NVIDIA GPU exporter metrics in Prometheus/Grafana

#### 🔴 Hardware Issues  
- [ ] **Investigate cobra_cam_4**: Physical network connectivity issue ("No route to host")
  - Check camera power and network cable
  - Verify IP address 192.168.1.104 is reachable
  - Consider IP address change if needed

### Medium Priority (Next Sprint)

#### 🟡 Configuration Optimization
- [ ] **Enable cobra_cam_4 detection**: Set `enabled: true` in detect section after fixing connectivity
- [ ] **Frigate performance tuning**: 
  - Add motion masks to reduce false detections
  - Configure detection zones for each camera
  - Optimize object filters (min_area, thresholds)

#### 🟡 Monitoring Enhancement
- [ ] **Frigate dashboard**: Create Grafana dashboard for camera system metrics
- [ ] **GPU alerting**: Configure alerts for high GPU temperature and utilization
- [ ] **Storage monitoring**: Enhance hot/cold storage capacity alerts

#### 🟡 Documentation
- [ ] **Update CLAUDE.md**: Add common operations and troubleshooting commands
- [ ] **Network diagram**: Create visual network topology documentation
- [ ] **Service dependencies**: Document container startup order and dependencies

### Low Priority (Future Improvements)

#### 🟢 Features and Enhancements
- [ ] **Home Assistant integration**: Complete Frigate MQTT integration setup
- [ ] **Notification system**: Configure camera motion detection alerts
- [ ] **Backup automation**: Implement surveillance recording backup to cold storage
- [ ] **Container healthchecks**: Add comprehensive health monitoring for all services
- [ ] **Performance monitoring**: Implement container resource usage tracking

#### 🟢 Security Improvements
- [ ] **Reverse proxy**: Implement Nginx/Traefik for external service access
- [ ] **Certificate management**: Set up automatic SSL certificate management
- [ ] **Access control**: Implement authentication for external service access
- [ ] **Firewall hardening**: Review and optimize firewall rules

#### 🟢 Infrastructure
- [ ] **Container registry**: Set up local container registry for custom images
- [ ] **Update automation**: Implement automated container image updates
- [ ] **Disaster recovery**: Document full system restore procedures
- [ ] **Hardware monitoring**: Add temperature sensors and fan control

## Completed Tasks Archive

### 2025-08-03 Session ✅
- [x] Fixed Frigate cobra_cam_1 input roles duplication error
- [x] Enhanced cobra_cam_2 with detection capabilities  
- [x] Fixed cobra_cam_4 authentication credentials
- [x] Verified GPU acceleration across all media services
- [x] Enabled NVIDIA GPU exporter for monitoring
- [x] Fixed jellyfin-gpu.nix syntax error
- [x] Documented system architecture and completed tasks
- [x] Consolidated all documentation into master documents

### Previous Sessions ✅
- [x] Implemented two-tier storage architecture (hot/cold)
- [x] Deployed comprehensive monitoring stack (Prometheus/Grafana)
- [x] Configured GPU acceleration for core services
- [x] Set up VPN integration with SOPS secrets management
- [x] Implemented automated media pipeline processing
- [x] Configured Tailscale mesh networking

## Notes and Context

### Current System Status
- **Cameras**: 3/4 operational (cam4 network issue)
- **GPU Acceleration**: Fully implemented across all services
- **Monitoring**: Complete stack with GPU metrics enabled
- **Storage**: Two-tier system operational with automation

### Next Session Priorities
1. Deploy current fixes and validate functionality
2. Resolve cobra_cam_4 connectivity issue
3. Performance testing and optimization
4. Documentation updates and maintenance

### Dependencies and Blockers
- **cobra_cam_4**: Hardware/network issue blocking full surveillance system
- **GPU monitoring**: Requires system rebuild to enable metrics collection
- **Performance tuning**: Depends on successful deployment of current fixes