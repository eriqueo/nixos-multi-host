# hosts/server/modules/grafana-dashboards.nix
# Custom Grafana dashboards for media pipeline and system monitoring
{ config, lib, pkgs, ... }:

{
  systemd.services.grafana-dashboards = {
    description = "Setup Grafana dashboards and datasources";
    wantedBy = [ "podman-grafana.service" ];
    after = [ "podman-grafana.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      # Wait for Grafana to be ready
      sleep 30
      
      # Setup datasources
      mkdir -p /opt/monitoring/grafana/config/provisioning/datasources
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

      # Setup dashboard provisioning
      mkdir -p /opt/monitoring/grafana/config/provisioning/dashboards
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

      # Create dashboards directory
      mkdir -p /opt/monitoring/grafana/config/dashboards
      
      # System Overview Dashboard
      cat > /opt/monitoring/grafana/config/dashboards/system-overview.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Heartwood Craft - System Overview",
    "tags": ["system", "overview"],
    "style": "dark",
    "timezone": "browser",
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
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
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
          {
            "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
            "legendFormat": "Memory Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
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
          {
            "expr": "node_filesystem_size_bytes - node_filesystem_free_bytes",
            "legendFormat": "{{mountpoint}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 4,
        "title": "Service Status",
        "type": "table",
        "targets": [
          {
            "expr": "up",
            "legendFormat": "{{job}}"
          }
        ],
        "transformations": [
          {
            "id": "organize",
            "options": {
              "excludeByName": {},
              "indexByName": {},
              "renameByName": {
                "Value": "Status"
              }
            }
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

      # Media Pipeline Dashboard
      cat > /opt/monitoring/grafana/config/dashboards/media-pipeline.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Media Pipeline Health",
    "tags": ["media", "pipeline"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Download Queue Status",
        "type": "table",
        "targets": [
          {
            "expr": "download_queue_size",
            "legendFormat": "{{client}} - {{status}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Hot Storage Usage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "hot_storage_usage_bytes",
            "legendFormat": "{{path}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Media Import Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "media_import_rate_per_hour",
            "legendFormat": "{{type}} imports/hour"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Service Response Times",
        "type": "graph",
        "targets": [
          {
            "expr": "service_response_time_seconds",
            "legendFormat": "{{service}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16}
      },
      {
        "id": 5,
        "title": "Active Transcoding Sessions",
        "type": "stat",
        "targets": [
          {
            "expr": "jellyfin_active_transcoding",
            "legendFormat": "Active Sessions"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16}
      }
    ],
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "refresh": "1m"
  }
}
EOF

      # GPU and Performance Dashboard
      cat > /opt/monitoring/grafana/config/dashboards/gpu-performance.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "GPU & Performance Monitoring",
    "tags": ["gpu", "performance"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "GPU Utilization",
        "type": "graph",
        "targets": [
          {
            "expr": "nvidia_gpu_utilization_percentage",
            "legendFormat": "GPU {{gpu}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "GPU Temperature",
        "type": "graph",
        "targets": [
          {
            "expr": "nvidia_gpu_temperature_celsius",
            "legendFormat": "GPU {{gpu}} Temperature"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "celsius"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "GPU Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "nvidia_gpu_memory_used_bytes",
            "legendFormat": "Used Memory"
          },
          {
            "expr": "nvidia_gpu_memory_total_bytes",
            "legendFormat": "Total Memory"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Network Throughput",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(node_network_receive_bytes_total[5m])",
            "legendFormat": "{{device}} RX"
          },
          {
            "expr": "rate(node_network_transmit_bytes_total[5m])",
            "legendFormat": "{{device}} TX"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "Bps"
          }
        },
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 16}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

      # Mobile Status Dashboard
      cat > /opt/monitoring/grafana/config/dashboards/mobile-status.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Mobile Status Dashboard",
    "tags": ["mobile", "status"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "System Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"node-exporter\"}",
            "legendFormat": "System"
          }
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
      },
      {
        "id": 2,
        "title": "Services",
        "type": "stat",
        "targets": [
          {
            "expr": "count(up == 1)",
            "legendFormat": "Online"
          },
          {
            "expr": "count(up == 0)",
            "legendFormat": "Offline"
          }
        ],
        "gridPos": {"h": 4, "w": 18, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "Storage",
        "type": "bargauge",
        "targets": [
          {
            "expr": "(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100",
            "legendFormat": "{{mountpoint}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "steps": [
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 85}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 4}
      },
      {
        "id": 4,
        "title": "Recent Activity",
        "type": "table",
        "targets": [
          {
            "expr": "download_queue_size > 0",
            "legendFormat": "{{client}} - {{status}}"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 12}
      }
    ],
    "time": {
      "from": "now-15m",
      "to": "now"
    },
    "refresh": "1m"
  }
}
EOF

      # Set proper permissions
      chown -R eric:users /opt/monitoring/grafana/
    '';
  };
}