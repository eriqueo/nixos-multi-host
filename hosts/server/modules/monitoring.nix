# hosts/server/modules/monitoring.nix
# Comprehensive monitoring stack with Grafana, Prometheus, and custom dashboards
{ config, lib, pkgs, ... }:

let
  # Common patterns from monitoring utilities
  mediaServiceEnv = {
    PUID = "1000";
    PGID = "1000";
    TZ = "America/Denver";
  };
  
  mediaNetworkOptions = [ "--network=media-network" ];
  configVol = service: "/opt/monitoring/${service}:/config";
  dataVol = service: "/opt/monitoring/${service}/data:/data";
  
in

{
  ####################################################################
  # 1. MONITORING CONTAINER STACK
  ####################################################################
  virtualisation.oci-containers.containers = {
    
    # Prometheus - Metrics collection and storage
    prometheus = {
      image = "prom/prometheus:latest";
      autoStart = true;
      extraOptions = mediaNetworkOptions;
      ports = [ "9090:9090" ];
      volumes = [
        "/opt/monitoring/prometheus/config:/etc/prometheus"
        "/opt/monitoring/prometheus/data:/prometheus"
        "/etc/localtime:/etc/localtime:ro"
      ];
      cmd = [
        "--config.file=/etc/prometheus/prometheus.yml"
        "--storage.tsdb.path=/prometheus"
        "--web.console.libraries=/etc/prometheus/console_libraries"
        "--web.console.templates=/etc/prometheus/consoles"
        "--storage.tsdb.retention.time=30d"
        "--web.enable-lifecycle"
        "--web.enable-admin-api"
      ];
    };

    # Grafana - Visualization and dashboards
    grafana = {
      image = "grafana/grafana:latest";
      autoStart = true;
      extraOptions = mediaNetworkOptions;
      environment = {
        TZ = "America/Denver";
        GF_SECURITY_ADMIN_PASSWORD = "admin123";
        GF_USERS_ALLOW_SIGN_UP = "false";
        GF_INSTALL_PLUGINS = "grafana-piechart-panel,grafana-worldmap-panel,grafana-clock-panel";
        GF_SERVER_ROOT_URL = "http://localhost:3000";
        GF_ANALYTICS_REPORTING_ENABLED = "false";
      };
      ports = [ "3000:3000" ];
      volumes = [
        "/opt/monitoring/grafana/data:/var/lib/grafana"
        "/opt/monitoring/grafana/config:/etc/grafana"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    # Alertmanager - Alert routing and notification
    alertmanager = {
      image = "prom/alertmanager:latest";
      autoStart = true;
      extraOptions = mediaNetworkOptions;
      ports = [ "9093:9093" ];
      volumes = [
        "/opt/monitoring/alertmanager/config:/etc/alertmanager"
        "/opt/monitoring/alertmanager/data:/alertmanager"
        "/etc/localtime:/etc/localtime:ro"
      ];
      cmd = [
        "--config.file=/etc/alertmanager/alertmanager.yml"
        "--storage.path=/alertmanager"
        "--web.external-url=http://localhost:9093"
      ];
    };

    # Node Exporter - System metrics
    node-exporter = {
      image = "prom/node-exporter:latest";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--pid=host"
        "--mount=type=bind,source=/,target=/host,ro,bind-propagation=rslave"
      ];
      ports = [ "9100:9100" ];
      cmd = [
        "--path.rootfs=/host"
        "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
        "--collector.textfile.directory=/host/var/lib/node_exporter/textfile_collector"
      ];
    };

    # cAdvisor - Container metrics
#     cadvisor = {
#       image = "gcr.io/cadvisor/cadvisor:latest";
#       autoStart = true;
#       healthCheck = null;  # disable Dockerfile HEALTHCHECK entirely
#       extraOptions = [
#         "--privileged"
#         "--device=/dev/kmsg"
#         "--volume=/:/rootfs:ro"
#         "--volume=/var/run:/var/run:ro"
#         "--volume=/sys:/sys:ro"
#         "--volume=/run/podman:/var/run/docker:ro"
#         "--volume=/run/podman/podman.sock:/var/run/docker.sock:ro"
#         "--network=host"
#       	"--health-cmd" ""
#       	"--health-interval" "10m"
#       ];
#       # Pass port as argument to cAdvisor binary (not Podman)
#       cmd = [ "--port=8083" ];  # Changed from default 8080 to avoid conflicts
#     };

    # Blackbox Exporter - Endpoint monitoring
    blackbox-exporter = {
      image = "prom/blackbox-exporter:latest";
      autoStart = true;
      extraOptions = mediaNetworkOptions;
      ports = [ "9115:9115" ];
      volumes = [
        "/opt/monitoring/blackbox/config:/etc/blackbox_exporter"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    # NVIDIA GPU Exporter
     nvidia-gpu-exporter = {
       image = "utkuozdemir/nvidia_gpu_exporter:latest";
       autoStart = true;
       extraOptions = [
         "--network=host"
         # Direct GPU device access (same as Frigate)
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
    };

    # Custom Media Pipeline Monitor
    media-pipeline-monitor = {
      image = "python:3.11-slim";
      autoStart = true;
      extraOptions = mediaNetworkOptions;
      ports = [ "8888:8888" ];
      volumes = [
        "/opt/monitoring/media-monitor:/app"
        "/mnt/media:/media:ro"
        "/mnt/hot:/hot:ro"
        "/opt/downloads:/downloads:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      cmd = [ "sh" "-c" "cd /app && pip install psutil prometheus_client requests && python media_monitor.py" ];
    };
  };

  ####################################################################
  # 2. DIRECTORY STRUCTURE SETUP
  ####################################################################
  systemd.tmpfiles.rules = [
    # Monitoring base directories
    "d /opt/monitoring 0755 eric users -"
    
    # Prometheus directories
    "d /opt/monitoring/prometheus 0755 eric users -"
    "d /opt/monitoring/prometheus/config 0755 eric users -"
    "d /opt/monitoring/prometheus/data 0755 65534 65534 -"
    
    # Grafana directories
    "d /opt/monitoring/grafana 0755 eric users -"
    "d /opt/monitoring/grafana/config 0755 eric users -"
    "d /opt/monitoring/grafana/data 0755 472 472 -"
    
    # Alertmanager directories
    "d /opt/monitoring/alertmanager 0755 eric users -"
    "d /opt/monitoring/alertmanager/config 0755 eric users -"
    "d /opt/monitoring/alertmanager/data 0755 eric users -"
    
    # Blackbox exporter directories
    "d /opt/monitoring/blackbox 0755 eric users -"
    "d /opt/monitoring/blackbox/config 0755 eric users -"
    
    # Custom monitoring scripts
    "d /opt/monitoring/media-monitor 0755 eric users -"
    
    # Node exporter textfile collector
    "d /var/lib/node_exporter 0755 root root -"
    "d /var/lib/node_exporter/textfile_collector 0755 root root -"
  ];

  ####################################################################
  # 3. CONFIGURATION GENERATION
  ####################################################################
  systemd.services.monitoring-config = {
    description = "Generate monitoring configuration files";
    wantedBy = [ 
      "podman-prometheus.service" 
      "podman-grafana.service" 
      "podman-alertmanager.service"
      "podman-blackbox-exporter.service"
      "podman-media-pipeline-monitor.service"
    ];
    before = [ 
      "podman-prometheus.service" 
      "podman-grafana.service" 
      "podman-alertmanager.service"
      "podman-blackbox-exporter.service"
      "podman-media-pipeline-monitor.service"
    ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      # Generate Prometheus configuration
      cat > /opt/monitoring/prometheus/config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # System metrics
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.containers.internal:9100']

  # Container metrics
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['host.containers.internal:8083']

  # GPU metrics
  - job_name: 'nvidia-gpu'
    static_configs:
      - targets: ['host.containers.internal:9445']

  # Container health checks
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://host.containers.internal:8989  # Sonarr
        - http://host.containers.internal:7878  # Radarr
        - http://host.containers.internal:8686  # Lidarr
        - http://host.containers.internal:9696  # Prowlarr
        - http://host.containers.internal:8096  # Jellyfin
        - http://127.0.0.1:2283  # Immich (local)
        - https://heartwood.ocelot-wahoo.ts.net/immich  # Immich (HTTPS)
        - http://host.containers.internal:4533  # Navidrome
        - http://host.containers.internal:5000  # Frigate
        - http://host.containers.internal:8123  # Home Assistant
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  # Media pipeline custom metrics
  - job_name: 'media-pipeline'
    static_configs:
      - targets: ['media-pipeline-monitor:8888']

  # Business services monitoring
  - job_name: 'business-services'
    static_configs:
      - targets: ['host.containers.internal:8501']  # Streamlit apps
EOF

      # Generate alert rules
      mkdir -p /opt/monitoring/prometheus/config/rules
      cat > /opt/monitoring/prometheus/config/rules/alerts.yml << 'EOF'
groups:
- name: system
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 80% for more than 5 minutes"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 85% for more than 5 minutes"

  - alert: LowDiskSpace
    expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100 > 85
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Low disk space"
      description: "Disk usage is above 85% on {{ $labels.mountpoint }}"

  - alert: HighDiskIOWait
    expr: irate(node_cpu_seconds_total{mode="iowait"}[5m]) * 100 > 20
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High disk I/O wait"
      description: "Disk I/O wait is above 20% for more than 5 minutes"

- name: containers
  rules:
  - alert: ContainerDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Container is down"
      description: "Container {{ $labels.instance }} has been down for more than 1 minute"

  - alert: ContainerHighCPU
    expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Container high CPU usage"
      description: "Container {{ $labels.name }} CPU usage is above 80%"

  - alert: ContainerHighMemory
    expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Container high memory usage"
      description: "Container {{ $labels.name }} memory usage is above 85%"

- name: storage
  rules:
  - alert: HotStorageFull
    expr: (node_filesystem_size_bytes{mountpoint="/mnt/hot"} - node_filesystem_free_bytes{mountpoint="/mnt/hot"}) / node_filesystem_size_bytes{mountpoint="/mnt/hot"} * 100 > 90
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Hot storage critically full"
      description: "Hot storage (/mnt/hot) is over 90% full"

  - alert: ColdStorageFull
    expr: (node_filesystem_size_bytes{mountpoint="/mnt/media"} - node_filesystem_free_bytes{mountpoint="/mnt/media"}) / node_filesystem_size_bytes{mountpoint="/mnt/media"} * 100 > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Cold storage getting full"
      description: "Cold storage (/mnt/media) is over 85% full"

- name: gpu
  rules:
  - alert: GPUHighTemperature
    expr: nvidia_gpu_temperature_celsius > 80
    for: 3m
    labels:
      severity: warning
    annotations:
      summary: "GPU temperature high"
      description: "GPU temperature is above 80°C for more than 3 minutes"

  - alert: GPUHighUtilization
    expr: nvidia_gpu_utilization_percentage > 90
    for: 10m
    labels:
      severity: info
    annotations:
      summary: "GPU high utilization"
      description: "GPU utilization is above 90% for more than 10 minutes"
EOF

      # Generate Alertmanager configuration
      cat > /opt/monitoring/alertmanager/config/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alertmanager@heartwood-craft.local'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
  - match:
      severity: warning
    receiver: 'warning-alerts'

receivers:
- name: 'default'
  webhook_configs:
  - url: 'http://host.containers.internal:9999/webhook'
    send_resolved: true

- name: 'critical-alerts'
  webhook_configs:
  - url: 'http://host.containers.internal:9999/webhook/critical'
    send_resolved: true

- name: 'warning-alerts'
  webhook_configs:
  - url: 'http://host.containers.internal:9999/webhook/warning'
    send_resolved: true

inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'dev', 'instance']
EOF

      # Generate Blackbox Exporter configuration
      cat > /opt/monitoring/blackbox/config/config.yml << 'EOF'
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []
      method: GET
      no_follow_redirects: false
      fail_if_ssl: false
      fail_if_not_ssl: false
      tls_config:
        insecure_skip_verify: false
      preferred_ip_protocol: "ip4"

  tcp_connect:
    prober: tcp
    timeout: 5s
    tcp:
      preferred_ip_protocol: "ip4"
EOF

      # Generate Grafana configuration
      cat > /opt/monitoring/grafana/config/grafana.ini << 'EOF'
[server]
http_port = 3000
root_url = http://localhost:3000

[security]
admin_user = admin
admin_password = admin123

[users]
allow_sign_up = false

[analytics]
reporting_enabled = false

[install]
check_for_updates = false
EOF

      # Set proper permissions
      chown -R eric:users /opt/monitoring/
      chown -R 472:472 /opt/monitoring/grafana/data
      chown -R 65534:65534 /opt/monitoring/prometheus/data
    '';
  };

  ####################################################################
  # 4. FIREWALL CONFIGURATION
  ####################################################################
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 3000 9090 9093 9100 8083 9115 9445 8888 ];
  };

  # Allow local network access
  networking.firewall.interfaces."enp3s0" = {
    allowedTCPPorts = [ 3000 9090 9093 ];
  };
}
