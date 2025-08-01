# Heartwood Craft Monitoring System

Comprehensive real-time monitoring solution for the entire Heartwood Craft infrastructure including 12 containers, hot/cold storage tiers, and business intelligence services.

## 🏗️ Architecture Overview

### Core Monitoring Stack
- **Grafana** (Port 3000) - Visualization and dashboards
- **Prometheus** (Port 9090) - Metrics collection and storage  
- **Alertmanager** (Port 9093) - Alert routing and notifications
- **Node Exporter** (Port 9100) - System metrics
- **cAdvisor** (Port 8080) - Container metrics
- **Blackbox Exporter** (Port 9115) - Endpoint monitoring
- **NVIDIA GPU Exporter** (Port 9445) - GPU metrics

### Custom Monitoring
- **Media Pipeline Monitor** (Port 8888) - Custom media processing metrics
- **Business Dashboard** (Port 8501) - Business intelligence dashboard
- **Business Metrics** (Port 9999) - Custom business metrics

## 📊 Dashboards

### 1. System Overview Dashboard
- **System Health**: CPU, Memory, Storage usage
- **Service Status**: All container health checks
- **Resource Utilization**: Real-time performance metrics
- **Alert Summary**: Current system alerts

### 2. Media Pipeline Dashboard
- **Download Queues**: Active torrents, usenet downloads
- **Processing Status**: Import rates, failed imports
- **Storage Flow**: Hot→Cold storage movement
- **Service Health**: Sonarr, Radarr, Lidarr response times
- **Transcoding Activity**: Jellyfin active sessions

### 3. GPU & Performance Dashboard
- **GPU Utilization**: Real-time NVIDIA Quadro P1000 usage
- **GPU Temperature**: Thermal monitoring with alerts
- **GPU Memory**: VRAM usage tracking
- **Network Throughput**: Interface bandwidth monitoring
- **Disk I/O**: Storage performance metrics

### 4. Mobile Status Dashboard
- **Simplified View**: Mobile-optimized interface
- **Service Status**: Quick health overview
- **Storage Alerts**: Critical space warnings
- **Recent Activity**: Latest downloads and imports

### 5. Business Intelligence Dashboard
- **Library Analytics**: Media collection statistics
- **Processing Efficiency**: Import success rates
- **Cost Analysis**: Storage and processing cost estimates
- **Storage Efficiency**: Hot/cold tier optimization

## 🚨 Alerting Rules

### System Alerts
- **High CPU Usage** (>80% for 5min) - Warning
- **High Memory Usage** (>85% for 5min) - Warning  
- **Low Disk Space** (>85% usage) - Critical
- **High Disk I/O Wait** (>20% for 5min) - Warning

### Container Alerts
- **Container Down** (>1min) - Critical
- **Container High CPU** (>80% for 5min) - Warning
- **Container High Memory** (>85% for 5min) - Warning

### Storage Alerts
- **Hot Storage Full** (>90%) - Critical
- **Cold Storage Full** (>85%) - Warning

### GPU Alerts
- **GPU High Temperature** (>80°C for 3min) - Warning
- **GPU High Utilization** (>90% for 10min) - Info

### Media Pipeline Alerts
- **Failed Import Rate** (>20%) - Warning
- **Download Queue Stuck** (no progress 30min) - Warning
- **Service Unresponsive** (>5s response) - Critical

## 📱 Mobile Access

All dashboards are optimized for mobile devices with:
- Responsive design for phones and tablets
- Touch-friendly interfaces
- Simplified metrics for quick status checks
- Auto-refresh capabilities
- Offline indicator when network unavailable

## 🔧 Configuration

### Prometheus Configuration
```yaml
# Main config: /opt/monitoring/prometheus/config/prometheus.yml
# Scrape intervals: 15s
# Retention: 30 days
# Targets: All containers + system metrics
```

### Grafana Configuration
```yaml
# Data source: Prometheus (http://prometheus:9090)
# Admin credentials: admin/admin123
# Dashboard provisioning: /opt/monitoring/grafana/config/dashboards/
```

### Alert Routing
```yaml
# Webhook alerts: http://host.containers.internal:9999/webhook
# Critical alerts: Immediate notification
# Warning alerts: 5-minute grouping
# Info alerts: 12-hour grouping
```

## 📈 Key Metrics Tracked

### System Metrics
- CPU utilization per core
- Memory usage (total, available, cached)
- Disk usage and I/O (all mount points)
- Network throughput (all interfaces)
- System load averages

### Container Metrics
- Container CPU and memory usage
- Container network traffic
- Container restart counts
- Container health check status
- Container resource limits vs usage

### GPU Metrics
- GPU utilization percentage
- GPU memory usage (used/total)
- GPU temperature (°C)
- GPU power consumption
- GPU processes and users

### Storage Metrics
- Hot storage usage by category
- Cold storage usage by media type
- Storage transfer rates (hot↔cold)
- File count and size distributions
- Storage efficiency ratios

### Media Pipeline Metrics
- Download queue sizes (by client)
- Import success/failure rates
- Processing times by media type
- Manual intervention requirements
- Quarantine file counts

### Business Metrics
- Total media library size and count
- Processing efficiency percentages
- Storage cost estimates
- User activity patterns
- API response times

## 🚀 Quick Start

1. **Deploy monitoring stack:**
   ```bash
   sudo nixos-rebuild switch
   ```

2. **Run setup script:**
   ```bash
   /etc/nixos/scripts/setup-monitoring.sh
   ```

3. **Access dashboards:**
   - Grafana: http://localhost:3000 (admin/admin123)
   - Prometheus: http://localhost:9090
   - Business Dashboard: http://localhost:8501

4. **Mobile access:**
   - Use any dashboard URL on mobile devices
   - Dashboards automatically adapt to screen size
   - Touch gestures supported for navigation

## 🔍 Troubleshooting

### Common Issues

**Containers not starting:**
```bash
# Check container logs
sudo podman logs prometheus
sudo podman logs grafana
```

**Missing metrics:**
```bash
# Verify exporters are running
curl http://localhost:9100/metrics  # Node exporter
curl http://localhost:8080/metrics  # cAdvisor
```

**Dashboard not loading:**
```bash
# Check Grafana logs
sudo podman logs grafana
# Verify Prometheus connection
curl http://localhost:9090/api/v1/targets
```

**Alerts not firing:**
```bash
# Check alert rules
curl http://localhost:9090/api/v1/rules
# Check alertmanager
curl http://localhost:9093/api/v1/alerts
```

### Performance Optimization

**High metric cardinality:**
- Reduce scrape frequency for expensive metrics
- Use recording rules for complex queries
- Implement metric filtering

**Storage optimization:**
- Adjust retention period (default 30 days)
- Use remote storage for long-term retention
- Implement data compaction

**Network optimization:**
- Use compression for remote targets
- Batch multiple metrics per request
- Implement metric relabeling

## 📋 Maintenance

### Regular Tasks
- **Weekly**: Review alert configurations
- **Monthly**: Check storage usage and cleanup old data
- **Quarterly**: Update dashboard configurations
- **Annually**: Review retention policies and storage costs

### Backup Strategy
```bash
# Backup Grafana dashboards
sudo cp -r /opt/monitoring/grafana/config/dashboards /backup/

# Backup Prometheus configuration
sudo cp -r /opt/monitoring/prometheus/config /backup/

# Backup alert rules
sudo cp /opt/monitoring/alertmanager/config/alertmanager.yml /backup/
```

### Updates
```bash
# Update monitoring containers
sudo podman pull prom/prometheus:latest
sudo podman pull grafana/grafana:latest
sudo nixos-rebuild switch
```

## 🔗 Integration Points

- **Tailscale VPN**: Remote access to all monitoring interfaces
- **Home Assistant**: Integration with surveillance system
- **Business API**: Custom metrics integration
- **Media Services**: Health check endpoints
- **Storage Systems**: Hot/cold tier monitoring
- **GPU Acceleration**: Hardware utilization tracking

## 📊 Performance Benchmarks

Expected resource usage:
- **Prometheus**: ~500MB RAM, ~10GB storage/month
- **Grafana**: ~200MB RAM
- **Exporters**: ~50MB RAM total
- **Custom monitors**: ~100MB RAM total

Network overhead:
- **Metrics collection**: ~1Mbps sustained
- **Dashboard access**: ~100Kbps per user
- **Alert notifications**: <1Kbps

This monitoring system provides comprehensive visibility into the entire Heartwood Craft infrastructure while maintaining optimal performance and mobile accessibility.