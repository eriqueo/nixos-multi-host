{ config, lib, pkgs, ... }:

{
  systemd.services.grafana-dashboards = {
    description = "Provision Grafana dashboards and datasources";
    wantedBy = [ "multi-user.target" ]; # Run at boot
    before = [ "podman-grafana.service" ]; # Ensure it runs before Grafana
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
          "thresholds": {
            "steps": [
              { "color": "green", "value": 0 },
              { "color": "yellow", "value": 70 },
              { "color": "red", "value": 85 }
            ]
          }
        }
      },
      "gridPos": { "h": 8, "w": 6, "x": 0, "y": 0 }
    }
    // ... Add other panels here
  ],
  "refresh": "30s",
  "time": {
    "from": "now-1h",
    "to": "now"
  }
}
EOF

      echo "Fixing permissions..."
      chown -R eric:users /opt/monitoring/grafana/config
    '';
  };
}
