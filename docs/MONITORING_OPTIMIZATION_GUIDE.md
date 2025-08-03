# Monitoring Stack Optimization Guide

## 📋 Current Status Assessment

### ✅ Strong Foundation
- **Core Stack**: Prometheus, Grafana, Alertmanager, Node Exporter, Blackbox Exporter
- **Infrastructure**: Proper systemd integration with NixOS
- **Storage**: Appropriate retention policies (30 days Prometheus, organized structure)
- **Security**: No hardcoded credentials, proper network isolation

### 🔧 Current Gaps and Optimization Opportunities

#### 1. Dashboard Configuration Issues
**Status**: Grafana running but dashboard provisioning failing
**Issue**: `Dashboard title cannot be empty` errors in logs
**Impact**: No functional dashboards despite monitoring data collection

#### 2. Incomplete Metrics Coverage
**Status**: Basic system metrics only, missing application-specific monitoring
**Gaps**: No GPU monitoring, limited container metrics, no business service metrics

#### 3. Alerting Configuration
**Status**: Alertmanager configured but minimal alert rules
**Gaps**: No notification channels configured, basic alert coverage only

## 🚀 Step-by-Step Optimization Instructions

### Phase 1: Fix Dashboard Provisioning

#### Step 1.1: Fix Grafana Dashboard Configuration
**File**: `/etc/nixos/hosts/server/modules/grafana-dashboards.nix`

**Current Issue**: Empty dashboard JSON files causing provisioning failures

**Fix Dashboard Templates**:
```nix
# Replace empty dashboard files with proper configuration
systemd.services.grafana-dashboard-provisioning = {
  description = "Generate Grafana dashboards";
  before = [ "podman-grafana.service" ];
  script = ''
    mkdir -p /opt/monitoring/grafana/config/dashboards
    
    # System Overview Dashboard
    cat > /opt/monitoring/grafana/config/dashboards/system-overview.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "System Overview",
    "uid": "system-overview",
    "version": 1,
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
          }
        ]
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
            "legendFormat": "Memory Usage %"
          }
        ]
      },
      {
        "id": 3,
        "title": "Disk Usage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100",
            "legendFormat": "{{mountpoint}}"
          }
        ]
      }
    ]
  }
}
EOF

    # GPU Performance Dashboard
    cat > /opt/monitoring/grafana/config/dashboards/gpu-performance.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "GPU Performance",
    "uid": "gpu-performance", 
    "version": 1,
    "panels": [
      {
        "id": 1,
        "title": "GPU Utilization",
        "type": "graph",
        "targets": [
          {
            "expr": "nvidia_gpu_utilization_percentage",
            "legendFormat": "GPU {{instance}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "GPU Temperature",
        "type": "graph",
        "targets": [
          {
            "expr": "nvidia_gpu_temperature_celsius",
            "legendFormat": "GPU {{instance}} Temp"
          }
        ]
      },
      {
        "id": 3,
        "title": "GPU Memory Usage",
        "type": "graph", 
        "targets": [
          {
            "expr": "nvidia_gpu_memory_used_bytes / nvidia_gpu_memory_total_bytes * 100",
            "legendFormat": "GPU {{instance}} Memory %"
          }
        ]
      }
    ]
  }
}
EOF

    # Media Pipeline Dashboard
    cat > /opt/monitoring/grafana/config/dashboards/media-pipeline.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Media Pipeline Status",
    "uid": "media-pipeline",
    "version": 1,
    "panels": [
      {
        "id": 1,
        "title": "Service Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"blackbox-http\"}",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Download Queue Size", 
        "type": "graph",
        "targets": [
          {
            "expr": "media_pipeline_queue_size",
            "legendFormat": "{{service}} Queue"
          }
        ]
      },
      {
        "id": 3,
        "title": "Storage Usage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "node_filesystem_size_bytes{mountpoint=~\"/mnt/(hot|media)\"} - node_filesystem_free_bytes{mountpoint=~\"/mnt/(hot|media)\"}) / node_filesystem_size_bytes{mountpoint=~\"/mnt/(hot|media)\"} * 100",
            "legendFormat": "{{mountpoint}}"
          }
        ]
      }
    ]
  }
}
EOF

    # Mobile Status Dashboard
    cat > /opt/monitoring/grafana/config/dashboards/mobile-status.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Mobile Service Status",
    "uid": "mobile-status",
    "version": 1,
    "panels": [
      {
        "id": 1,
        "title": "Services Uptime",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"blackbox-http\"}",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Response Times",
        "type": "graph",
        "targets": [
          {
            "expr": "probe_duration_seconds{job=\"blackbox-http\"}",
            "legendFormat": "{{instance}}"
          }
        ]
      }
    ]
  }
}
EOF

    chown -R 472:472 /opt/monitoring/grafana/config/dashboards
  '';
};
```

#### Step 1.2: Configure Dashboard Provisioning
**File**: `/etc/nixos/hosts/server/modules/monitoring.nix`

**Add dashboard provisioning configuration** around line 497:
```nix
# Add dashboard provisioning config
cat > /opt/monitoring/grafana/config/provisioning/dashboards/default.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/dashboards
EOF
```

### Phase 2: Enhanced Metrics Collection

#### Step 2.1: Enable GPU Monitoring
**File**: `/etc/nixos/hosts/server/modules/monitoring.nix`

**Uncomment and configure GPU exporter** around line 136:
```nix
# Uncomment and fix this section
nvidia-gpu-exporter = {
  image = "utkuozdemir/nvidia_gpu_exporter:latest";
  autoStart = true;
  extraOptions = [
    "--network=host"
    "--device=/dev/nvidia0:/dev/nvidia0:rwm"
    "--device=/dev/nvidiactl:/dev/nvidiactl:rwm" 
    "--device=/dev/nvidia-modeset:/dev/nvidia-modeset:rwm"
    "--device=/dev/nvidia-uvm:/dev/nvidia-uvm:rwm"
    "--device=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools:rwm"
  ];
  environment = {
    NVIDIA_VISIBLE_DEVICES = "all";
    NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
  };
  ports = [ "9445:9445" ];
};
```

#### Step 2.2: Add Container Metrics Collection
**File**: `/etc/nixos/hosts/server/modules/monitoring.nix`

**Uncomment and configure cAdvisor** around line 103:
```nix
# Enable container monitoring
cadvisor = {
  image = "gcr.io/cadvisor/cadvisor:latest";
  autoStart = true;
  extraOptions = [
    "--privileged"
    "--volume=/:/rootfs:ro"
    "--volume=/var/run:/var/run:ro"
    "--volume=/sys:/sys:ro"
    "--volume=/run/podman/podman.sock:/var/run/docker.sock:ro"
    "--volume=/dev/disk/:/dev/disk:ro"
    "--network=host"
  ];
  ports = [ "8083:8080" ];  # Changed port to avoid conflicts
  cmd = [ 
    "--port=8080"
    "--housekeeping_interval=30s"
    "--max_housekeeping_interval=35s" 
    "--machine_id_file=/rootfs/etc/machine-id"
    "--allow_dynamic_housekeeping=true"
    "--global_housekeeping_interval=1m0s"
  ];
};
```

#### Step 2.3: Enhanced Business Service Monitoring
**Add custom metrics endpoint** to business services:

**File**: `/etc/nixos/hosts/server/modules/business-monitoring.nix`

**Update business services** to expose metrics:
```nix
business-metrics = {
  # existing configuration
  environment = {
    # existing environment
    PROMETHEUS_ENABLED = "true";
    METRICS_PORT = "9999";
  };
  ports = [ "9999:9999" "8501:8501" ];  # Add metrics port
};

business-dashboard = {
  # existing configuration
  environment = {
    # existing environment  
    PROMETHEUS_ENABLED = "true";
    METRICS_PORT = "9998";
  };
  ports = [ "8501:8501" "9998:9998" ];  # Add metrics port
};
```

### Phase 3: Comprehensive Alerting

#### Step 3.1: Enhanced Alert Rules
**File**: `/etc/nixos/hosts/server/modules/monitoring.nix`

**Replace basic alert rules** around line 302 with comprehensive rules:
```yaml
# Enhanced alert rules
groups:
- name: system-critical
  rules:
  - alert: SystemDown
    expr: up{job="node-exporter"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "System is down"
      description: "Node exporter has been down for more than 1 minute"

  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 85% for more than 10 minutes"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 90% for more than 5 minutes"

  - alert: DiskSpaceCritical
    expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100 > 90
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Disk space critically low"
      description: "Disk usage is above 90% on {{ $labels.mountpoint }}"

- name: media-services
  rules:
  - alert: MediaServiceDown
    expr: up{job="blackbox-http"} == 0
    for: 3m
    labels:
      severity: warning
    annotations:
      summary: "Media service is down"
      description: "Service {{ $labels.instance }} has been down for more than 3 minutes"

  - alert: DownloadQueueStuck
    expr: media_pipeline_queue_size > 20
    for: 30m
    labels:
      severity: warning
    annotations:
      summary: "Download queue appears stuck"
      description: "Queue size has been above 20 for 30 minutes"

- name: gpu-monitoring
  rules:
  - alert: GPUHighTemperature
    expr: nvidia_gpu_temperature_celsius > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "GPU temperature high"
      description: "GPU temperature is above 80°C for more than 5 minutes"

  - alert: GPUMemoryHigh
    expr: (nvidia_gpu_memory_used_bytes / nvidia_gpu_memory_total_bytes) * 100 > 90
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "GPU memory usage high"
      description: "GPU memory usage is above 90% for more than 10 minutes"

- name: storage-monitoring
  rules:
  - alert: HotStorageFull
    expr: (node_filesystem_size_bytes{mountpoint="/mnt/hot"} - node_filesystem_free_bytes{mountpoint="/mnt/hot"}) / node_filesystem_size_bytes{mountpoint="/mnt/hot"} * 100 > 85
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Hot storage is getting full"
      description: "Hot storage (/mnt/hot) is over 85% full"

  - alert: ColdStorageFull
    expr: (node_filesystem_size_bytes{mountpoint="/mnt/media"} - node_filesystem_free_bytes{mountpoint="/mnt/media"}) / node_filesystem_size_bytes{mountpoint="/mnt/media"} * 100 > 95
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Cold storage is critically full"
      description: "Cold storage (/mnt/media) is over 95% full"
```

#### Step 3.2: Configure Notification Channels
**File**: `/etc/nixos/hosts/server/modules/monitoring.nix`

**Update Alertmanager configuration** around line 412:
```yaml
# Enhanced Alertmanager configuration
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@heartwood-craft.local'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
    repeat_interval: 1h
  - match:
      severity: warning
    receiver: 'warning-alerts'
    repeat_interval: 8h

receivers:
- name: 'default'
  webhook_configs:
  - url: 'http://host.containers.internal:9999/webhook'
    send_resolved: true

- name: 'critical-alerts'
  webhook_configs:
  - url: 'http://host.containers.internal:9999/webhook/critical'
    send_resolved: true
    title: 'CRITICAL: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

- name: 'warning-alerts'  
  webhook_configs:
  - url: 'http://host.containers.internal:9999/webhook/warning'
    send_resolved: true
    title: 'WARNING: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'instance']
```

### Phase 4: Performance Monitoring Enhancement

#### Step 4.1: Add Custom Metrics Collection
**Create custom metrics service**:

**File**: `/etc/nixos/hosts/server/modules/monitoring.nix`

**Add custom system metrics collector**:
```nix
# Add custom metrics collection service
systemd.services.custom-metrics = {
  description = "Collect custom system metrics";
  startAt = "*:*:30";  # Every 30 seconds
  script = ''
    # Collect GPU metrics if available
    if command -v nvidia-smi >/dev/null 2>&1; then
      GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
      GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
      echo "gpu_temperature_celsius $GPU_TEMP" > /var/lib/node_exporter/textfile_collector/gpu.prom
      echo "gpu_utilization_percentage $GPU_UTIL" >> /var/lib/node_exporter/textfile_collector/gpu.prom
    fi
    
    # Collect storage tier metrics
    HOT_USAGE=$(df /mnt/hot | tail -1 | awk '{print $5}' | sed 's/%//')
    COLD_USAGE=$(df /mnt/media | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "storage_hot_usage_percentage $HOT_USAGE" > /var/lib/node_exporter/textfile_collector/storage.prom
    echo "storage_cold_usage_percentage $COLD_USAGE" >> /var/lib/node_exporter/textfile_collector/storage.prom
    
    # Collect container metrics
    CONTAINER_COUNT=$(podman ps -q | wc -l)
    echo "containers_running_total $CONTAINER_COUNT" > /var/lib/node_exporter/textfile_collector/containers.prom
  '';
};
```

#### Step 4.2: Enhanced Prometheus Scraping
**Update Prometheus configuration** around line 242:
```yaml
# Enhanced scrape configuration
scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    scrape_interval: 15s

  # System metrics with custom collectors
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.containers.internal:9100']
    scrape_interval: 15s

  # Container metrics
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['host.containers.internal:8083']
    scrape_interval: 30s

  # GPU metrics
  - job_name: 'nvidia-gpu'
    static_configs:
      - targets: ['host.containers.internal:9445']
    scrape_interval: 15s

  # Media service health monitoring
  - job_name: 'blackbox-media-services'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://host.containers.internal:8989  # Sonarr
        - http://host.containers.internal:7878  # Radarr
        - http://host.containers.internal:8686  # Lidarr
        - http://host.containers.internal:9696  # Prowlarr
        - http://host.containers.internal:8080  # qBittorrent
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  # Business services monitoring
  - job_name: 'business-services'
    static_configs:
      - targets: 
        - 'host.containers.internal:9999'  # Business metrics
        - 'host.containers.internal:9998'  # Business dashboard metrics
    scrape_interval: 30s

  # Media pipeline custom metrics
  - job_name: 'media-pipeline'
    static_configs:
      - targets: ['media-pipeline-monitor:8888']
    scrape_interval: 30s
```

### Phase 5: Dashboard and Visualization Enhancement

#### Step 5.1: Create Comprehensive Dashboards
**File**: Create new dashboard service in monitoring.nix

**Add automated dashboard import**:
```nix
systemd.services.grafana-dashboard-import = {
  description = "Import community dashboards";
  after = [ "podman-grafana.service" ];
  script = ''
    sleep 30  # Wait for Grafana to start
    
    # Import Node Exporter dashboard
    curl -X POST \
      http://admin:admin123@localhost:3000/api/dashboards/import \
      -H "Content-Type: application/json" \
      -d '{
        "dashboard": {
          "id": 1860,
          "title": "Node Exporter Full"
        },
        "overwrite": true
      }'
    
    # Import NVIDIA GPU dashboard  
    curl -X POST \
      http://admin:admin123@localhost:3000/api/dashboards/import \
      -H "Content-Type: application/json" \
      -d '{
        "dashboard": {
          "id": 14574,
          "title": "NVIDIA GPU Metrics"
        },
        "overwrite": true
      }'
  '';
};
```

## 🧪 Testing and Validation

### After Each Phase:

1. **Test configuration**:
   ```bash
   grebuild "Monitoring optimization phase X"
   ```

2. **Verify services**:
   ```bash
   sudo systemctl status podman-grafana.service
   sudo systemctl status podman-prometheus.service
   ```

3. **Check dashboard availability**:
   ```bash
   curl -f http://localhost:3000/api/health
   ```

4. **Test alerting**:
   ```bash
   # Trigger test alert
   curl -X POST http://localhost:9093/api/v1/alerts
   ```

### Performance Validation:

- **Prometheus targets**: All targets should be "UP" in web interface
- **Grafana dashboards**: All dashboards load without errors
- **Alert rules**: No syntax errors in Prometheus rules
- **Data retention**: Appropriate retention policies active

## 🚨 Common Issues and Solutions

### Issue: "Dashboard title cannot be empty"
**Solution**: Replace empty JSON files with proper dashboard configurations

### Issue: "No data in Grafana"
**Solution**: Check Prometheus targets and data source configuration

### Issue: "GPU metrics not available"
**Solution**: Ensure nvidia-gpu-exporter has proper device access

### Issue: "Alerts not firing"
**Solution**: Verify alert rule syntax and notification channel configuration

## 📈 Success Metrics

After optimization:
- ✅ All dashboards loading without errors
- ✅ Comprehensive metrics collection (system, GPU, containers, applications)
- ✅ Alert rules covering critical system states
- ✅ Notification channels configured and tested
- ✅ Performance monitoring active for all services
- ✅ Storage and resource utilization tracked
- ✅ Business service metrics available