# System Documentation Standards
# Based on Agent 3's documentation and testing standards (adapted for existing system)

## Documentation Standards for NixOS Homeserver

### Document Structure Standards

#### 1. Header Format
All documentation files must include:
```markdown
# [Title] - [Category]
**Last Updated**: YYYY-MM-DD  
**Maintainer**: [Role/Agent]  
**System Version**: [NixOS Version]  
**Integration Status**: [Active/Deprecated/Planned]

## Overview
Brief description of what this document covers.

## Prerequisites
- System requirements
- Dependencies
- Required permissions
```

#### 2. Configuration Documentation
When documenting NixOS configurations:

```markdown
## Configuration Location
**File**: `/etc/nixos/hosts/server/modules/[module].nix`  
**Service**: `systemctl status [service-name]`  
**Logs**: `journalctl -fu [service-name]`

## Current Configuration
\```nix
# Include actual current configuration with comments
# Explain non-obvious settings
\```

## Modification Procedure
1. Edit configuration file
2. Test with: `sudo nixos-rebuild test --flake .#hwc-server`
3. Apply with: `grebuild "description of changes"`
4. Verify with: `systemctl status [service]`
```

#### 3. Container Service Documentation
For Podman container services:

```markdown
## Container Information
- **Image**: [registry/image:tag]
- **Network**: media-network
- **Volumes**: [list actual volume mounts]
- **GPU Access**: [Yes/No - specify devices if yes]
- **Dependencies**: [list container dependencies]

## Health Check
\```bash
podman ps | grep [container-name]
podman exec [container-name] [health-check-command]
curl -s http://localhost:[port]/[health-endpoint]
\```

## Troubleshooting
\```bash
# Check container status
systemctl status podman-[container-name].service

# View logs
journalctl -fu podman-[container-name].service

# Restart container
systemctl restart podman-[container-name].service
\```
```

### Version Control Standards

#### 1. Commit Message Format
```
[Category]: Brief description (≤50 chars)

Detailed explanation if needed:
- What changed and why
- Impact on system operation
- Related issues or requirements

AI Bible Integration: [Yes/No]
Testing: [Manual/Automated/None]
Rollback Tested: [Yes/No]
```

#### 2. Change Documentation Requirements
Before committing configuration changes:

1. **Document the change** in relevant module comments
2. **Update related documentation** files
3. **Test rollback procedure** if critical
4. **Update monitoring/alerting** if metrics change
5. **Note breaking changes** in commit message

#### 3. Testing Requirements
All significant changes must include:

```markdown
## Testing Checklist
- [ ] Configuration syntax validated
- [ ] Test deployment successful (`nixos-rebuild test`)
- [ ] Service starts and responds to health checks
- [ ] No impact on dependent services
- [ ] Monitoring/metrics still functional
- [ ] Rollback tested and verified
```

### Media Pipeline Documentation Standards

#### 1. ARR Application Configuration
When documenting *arr application settings:

```markdown
## [App] Configuration Guide

### Access Information
- **URL**: http://localhost:[port]
- **Config Path**: `/opt/[app]/config/`
- **API Key Location**: Config → General → Security → API Key

### Key Settings
| Setting | Value | Reason |
|---------|-------|---------|
| Root Folder | `/media/[type]` | Media storage location |
| Download Client | qBittorrent | VPN-protected downloads |
| Quality Profile | [Specific profile] | Optimized for storage/quality |

### File Naming Template
\```
TV: {Series Title}/Season {season:00}/{Series Title} - S{season:00}E{episode:00} - {Episode Title} [{Quality Title}]
Movies: {Movie Title} ({Year}) [{Quality Title}]
Music: {Artist Name}/{Album Title} ({Year})/{track:00} - {Track Title}
\```
```

#### 2. Troubleshooting Documentation
Standard troubleshooting section format:

```markdown
## Troubleshooting

### Common Issues

#### Issue: [Description]
**Symptoms**: [What the user sees]
**Cause**: [Root cause explanation]
**Solution**:
\```bash
# Step by step commands to fix
[commands]
\```
**Prevention**: [How to avoid this issue]

#### Issue: Downloads Stuck
**Symptoms**: Items show as "Downloading" but no progress
**Cause**: Usually VPN connectivity or download client communication
**Solution**:
\```bash
# Check VPN status
systemctl status podman-gluetun.service

# Check download client
systemctl status podman-qbittorrent.service
curl -s http://localhost:8080
\```
**Prevention**: Monitor VPN connectivity and download client health
```

### Monitoring and Alerting Documentation

#### 1. Metrics Documentation
When adding new metrics:

```markdown
## Metrics Definition

### Metric: [metric_name]
- **Type**: [gauge/counter/histogram]
- **Labels**: [label1, label2]
- **Description**: [What this metric measures]
- **Collection**: [How it's collected]
- **Alert Thresholds**: [When to alert]

### Example Queries
\```promql
# Current value
[metric_name]{instance="localhost:9100"}

# Rate of change (for counters)
rate([metric_name]_total[5m])

# Alert condition
[metric_name] > [threshold_value]
\```
```

#### 2. Grafana Dashboard Documentation
For dashboard changes:

```markdown
## Dashboard: [Dashboard Name]

### Panels Overview
| Panel | Metric | Purpose |
|-------|--------|---------|
| [Panel Name] | [metric_name] | [What it shows] |

### Dashboard JSON
Located at: `/etc/nixos/config/grafana/dashboards/[dashboard-name].json`

### Update Procedure
1. Make changes in Grafana UI
2. Export JSON from Grafana
3. Update JSON file in NixOS config
4. Test with `nixos-rebuild test`
5. Apply with `grebuild`
```

### Storage and Backup Documentation

#### 1. Storage Path Documentation
All storage paths must be documented:

```markdown
## Storage Architecture

### Hot Storage (`/mnt/hot` - SSD)
- **Purpose**: Active processing, downloads, cache
- **Size**: [Current size]
- **Usage Pattern**: High I/O, temporary files
- **Cleanup**: Automated via systemd services

### Cold Storage (`/mnt/media` - HDD)
- **Purpose**: Long-term media storage
- **Size**: [Current size]
- **Usage Pattern**: Sequential access, archival
- **Organization**: By media type (tv, movies, music)

### Path Mapping
| Service | Hot Path | Cold Path | Purpose |
|---------|----------|-----------|---------|
| Downloads | `/mnt/hot/downloads` | - | Temporary download location |
| TV | `/mnt/hot/manual/tv` | `/mnt/media/tv` | Processing → Final storage |
| Movies | `/mnt/hot/manual/movies` | `/mnt/media/movies` | Processing → Final storage |
```

#### 2. Backup Documentation
```markdown
## Backup Procedures

### Automated Backups
- **Service**: `backup-usb.service`
- **Schedule**: On USB insertion or manual trigger
- **Locations**: [List backup destinations]

### Manual Backup
\```bash
# Trigger USB backup
systemctl start backup-usb.service

# Verify backup
systemctl start backup-verify.service

# Check status
journalctl -fu backup-usb.service
\```

### Recovery Procedures
1. Boot from NixOS installer
2. Mount backup drive
3. Restore `/etc/nixos` configuration
4. Run `nixos-install`
5. Restore user data and container configs
```

### Documentation Maintenance

#### 1. Regular Review Schedule
- **Monthly**: Review all documentation for accuracy
- **After major changes**: Update affected documentation
- **Quarterly**: Full documentation audit
- **Annually**: Restructure and consolidate as needed

#### 2. Documentation Testing
```bash
# Test all documented commands
./test-documentation.sh [doc-file]

# Validate all file paths exist
./validate-paths.sh

# Check for broken internal links
./check-links.sh
```

#### 3. AI Bible Integration
This documentation integrates with the AI Bible system:
- **Updates trigger**: Bible system updates when documentation changes
- **Change tracking**: All changes are analyzed for bible updates
- **Consistency checks**: Cross-references validated automatically
- **Archival**: Obsolete documentation moved to archive

---

**Document Version**: 1.0  
**Based on**: Agent 3's documentation standards  
**Integration**: AI Bible Documentation System  
**Next Review**: 2025-09-07
EOF < /dev/null