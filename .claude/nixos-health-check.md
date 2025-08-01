# NixOS Server Health Check & Optimization

This command performs a comprehensive health check and optimization of the NixOS media server.

## Execution Steps

### 1. System Health Analysis
- Check all container statuses: `systemctl list-units "*podman*" | grep failed`
- Verify GPU functionality: `nvidia-smi` and check driver status
- Monitor resource usage: CPU, memory, disk space on both hot (/mnt/hot) and cold (/mnt/media) storage
- Check network connectivity: Tailscale status, container network health

### 2. Service-Specific Checks
- **Media Pipeline**: Verify *arr services can reach download clients
- **VPN Status**: Confirm Gluetun is properly routing qBittorrent and SABnzbd
- **GPU Acceleration**: Test Frigate and Jellyfin hardware acceleration
- **Monitoring Stack**: Verify Prometheus targets, Grafana dashboards, Alertmanager

### 3. Configuration Validation
- Run syntax check: `sudo nixos-rebuild dry-build`
- Verify no configuration drift from git repository
- Check for security updates: `nix-channel --update && nix-env -u`
- Validate backup systems and retention policies

### 4. Performance Optimization
- Analyze container resource usage and recommend adjustments
- Check for disk space optimization opportunities
- Review and clean old Docker images: `sudo podman system prune`
- Optimize database sizes for *arr services

### 5. Security Audit
- Review firewall rules and exposed ports
- Check for unnecessary services
- Validate certificate status for HTTPS endpoints
- Review user permissions and access controls

### 6. Automated Fixes
- Restart any failed non-critical services
- Clean up temporary files and logs
- Update container images if security patches available
- Commit configuration changes to git if modifications made

### 7. Reporting
- Generate summary report with health score (1-10)
- List any issues requiring manual intervention
- Provide recommendations for capacity planning
- Update documentation if new issues/solutions discovered

## Usage
Run with: `/nixos-health-check`
Frequency: Weekly for production systems