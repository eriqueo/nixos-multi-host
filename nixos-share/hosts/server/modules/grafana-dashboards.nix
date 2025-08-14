# hosts/server/modules/grafana-dashboards.nix
{ config, lib, pkgs, ... }:

{
  systemd.services.grafana-dashboards = {
    description = "Provision Grafana dashboards and datasources";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-grafana.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      echo "Creating Grafana provisioning directories..."
      mkdir -p /opt/monitoring/grafana/config/provisioning/datasources
      mkdir -p /opt/monitoring/grafana/config/provisioning/dashboards
      mkdir -p /opt/monitoring/grafana/config/dashboards

      echo "Writing Prometheus datasource..."
      cat > /opt/monitoring/grafana/config/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

      echo "Writing dashboard provisioning config..."
      cat > /opt/monitoring/grafana/config/provisioning/dashboards/default.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/dashboards
EOF

      echo "Writing system overview dashboard..."
      cat > /opt/monitoring/grafana/config/dashboards/system-overview.json << 'EOF'
{
  "id": null,
  "title": "Heartwood Craft - System Overview",
  "tags": ["system", "overview"],
  "timezone": "browser",
  "refresh": "30s",
  "time": { "from": "now-1h", "to": "now" },
  "panels": [
    {
      "id": 1,
      "title": "CPU Usage",
      "type": "stat",
      "targets": [
        { "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)", "legendFormat": "CPU Usage %" }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "thresholds": {
            "steps": [
              {"color": "green", "value": 0},
              {"color": "yellow", "value": 70},
              {"color": "red", "value": 85}
            ]
          }
        }
      },
      "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
    },
    {
      "id": 2,
      "title": "Memory Usage",
      "type": "stat",
      "targets": [
        { "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100", "legendFormat": "Memory Usage %" }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "thresholds": {
            "steps": [
              {"color": "green", "value": 0},
              {"color": "yellow", "value": 70},
              {"color": "red", "value": 85}
            ]
          }
        }
      },
      "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
    },
    {
      "id": 3,
      "title": "Storage Usage",
      "type": "piechart",
      "targets": [
        { "expr": "node_filesystem_size_bytes - node_filesystem_free_bytes", "legendFormat": "{{mountpoint}}" }
      ],
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
    },
    {
      "id": 4,
      "title": "Service Status",
      "type": "table",
      "targets": [
        { "expr": "up", "legendFormat": "{{job}}" }
      ],
      "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
    }
  ]
}
EOF

      echo "Writing media pipeline dashboard..."
      cat > /opt/monitoring/grafana/config/dashboards/media-pipeline.json << 'EOF'
{
  "id": null,
  "title": "Media Pipeline Health",
  "tags": ["media", "pipeline"],
  "timezone": "browser",
  "refresh": "1m",
  "time": { "from": "now-6h", "to": "now" },
  "panels": [
    {
      "id": 1,
      "title": "Download Queue Status",
      "type": "table",
      "targets": [
        { "expr": "download_queue_size", "legendFormat": "{{client}} - {{status}}" }
      ],
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
    },
    {
      "id": 2,
      "title": "Hot Storage Usage",
      "type": "bargauge",
      "targets": [
        { "expr": "hot_storage_usage_bytes", "legendFormat": "{{path}}" }
      ],
      "fieldConfig": { "defaults": { "unit": "bytes" } },
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
    }
  ]
}
EOF

      echo "Writing GPU performance dashboard..."
      cat > /opt/monitoring/grafana/config/dashboards/gpu-performance.json << 'EOF'
{
  "id": null,
  "title": "GPU & Performance Monitoring",
  "tags": ["gpu", "performance"],
  "timezone": "browser",
  "refresh": "30s",
  "time": { "from": "now-1h", "to": "now" },
  "panels": [
    {
      "id": 1,
      "title": "GPU Utilization",
      "type": "graph",
      "targets": [
        { "expr": "nvidia_gpu_utilization_percentage", "legendFormat": "GPU {{gpu}}" }
      ],
      "fieldConfig": { "defaults": { "unit": "percent", "min": 0, "max": 100 } },
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
    },
    {
      "id": 2,
      "title": "GPU Temperature",
      "type": "graph",
      "targets": [
        { "expr": "nvidia_gpu_temperature_celsius", "legendFormat": "GPU {{gpu}} Temperature" }
      ],
      "fieldConfig": { "defaults": { "unit": "celsius" } },
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
    }
  ]
}
EOF

      echo "Writing mobile status dashboard..."
      cat > /opt/monitoring/grafana/config/dashboards/mobile-status.json << 'EOF'
{
  "id": null,
  "title": "Mobile Status Dashboard",
  "tags": ["mobile", "status"],
  "timezone": "browser",
  "refresh": "1m",
  "time": { "from": "now-15m", "to": "now" },
  "panels": [
    {
      "id": 1,
      "title": "System Health",
      "type": "stat",
      "targets": [
        { "expr": "up{job=\"node-exporter\"}", "legendFormat": "System" }
      ],
      "fieldConfig": {
        "defaults": {
          "mappings": [
            {"options": {"0": {"text": "DOWN", "color": "red"}}, "type": "value"},
            {"options": {"1": {"text": "UP", "color": "green"}}, "type": "value"}
          ]
        }
      },
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0}
    }
  ]
}
EOF

      echo "Fixing permissions..."
      chown -R eric:users /opt/monitoring/grafana/config
    '';
  };
}
