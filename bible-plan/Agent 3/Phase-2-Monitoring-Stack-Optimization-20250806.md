# Phase 2 — Monitoring Stack Optimization

**Agent 3: Media Pipeline & Monitoring Optimization**

**Date:** 2025-08-06

---

## Executive Summary

This phase hardens and expands your system monitoring and alerting using NixOS-native patterns:
- Grafana dashboards (fully provisioned, fixed JSON)
- GPU and container metrics (cAdvisor, NVIDIA GPU Exporter)
- Application and business service health monitoring
- Comprehensive Prometheus/Alertmanager alert rules
- Rollback/testing notes for every step

---

## Table of Contents

1. [Grafana Dashboard Provisioning](#grafana-dashboard-provisioning)
2. [Enable GPU & Container Metrics](#enable-gpu--container-metrics)
3. [Enhanced Alerting & Notification](#enhanced-alerting--notification)
4. [Business and Media Metrics Integration](#business-and-media-metrics-integration)
5. [Testing, Rollback, and Validation](#testing-rollback-and-validation)

---

## Grafana Dashboard Provisioning

**Goal:**  
Visualize system health, resource usage, and service status at a glance.

### Steps

1. **Replace empty or broken dashboard JSON files:**
    - In `/etc/nixos/hosts/server/modules/grafana-dashboards.nix`, use production-ready dashboard templates:
      - System Overview
      - GPU Performance
      - Media Pipeline
      - Mobile Status

    Example (System Overview):

    ```json
    {
      "dashboard": {
        "title": "System Overview",
        "uid": "system-overview",
        "version": 1,
        "panels": [
          {
            "title": "CPU Usage",
            "type": "stat",
            "targets": [
              { "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)" }
            ]
          },
          {
            "title": "Memory Usage",
            "type": "stat",
            "targets": [
              { "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100" }
            ]
          },
          {
            "title": "Disk Usage",
            "type": "bargauge",
            "targets": [
              { "expr": "(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100" }
            ]
          }
        ]
      }
    }
    ```
    *(Repeat for each dashboard as per your guide.)*

2. **Reload config:**
    ```bash
    sudo nixos-rebuild switch
    ```

3. **Verify dashboards:**  
    - Access Grafana at `http://localhost:3000` (admin/admin123).
    - All dashboards should load, show data, and be free from "title cannot be empty" errors.

---

## Enable GPU & Container Metrics

**Goal:**  
Expose GPU, container, and application metrics for Prometheus and Grafana.

### Steps

1. **Enable NVIDIA GPU Exporter:**  
    In `/etc/nixos/hosts/server/modules/monitoring.nix`:

    ```nix
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

2. **Enable cAdvisor for container metrics:**  
    ```nix
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
      ports = [ "8083:8080" ];
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

3. **Add Prometheus scrape configs:**
    ```yaml
    scrape_configs:
      - job_name: 'nvidia-gpu'
        static_configs:
          - targets: ['host.containers.internal:9445']
        scrape_interval: 15s

      - job_name: 'cadvisor'
        static_configs:
          - targets: ['host.containers.internal:8083']
        scrape_interval: 30s
    ```

4. **Reload config:**
    ```bash
    sudo nixos-rebuild switch
    ```

5. **Validate:**  
    - Prometheus targets "nvidia-gpu" and "cadvisor" should be **UP** in Prometheus web UI.
    - Grafana dashboards show live GPU/container data.

---

## Enhanced Alerting & Notification

**Goal:**  
Proactive, actionable alerts for system, GPU, storage, and media failures.

### Steps

1. **Prometheus alert rules (replace/add in `/etc/nixos/hosts/server/modules/monitoring.nix`):**

    ```yaml
    groups:
    - name: system-critical
      rules:
      - alert: SystemDown
        expr: up{job="node-exporter"} == 0
        for: 1m
        labels: { severity: critical }
        annotations: { summary: "System is down" }

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 10m
        labels: { severity: warning }
        annotations: { summary: "High CPU usage detected" }

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
        for: 5m
        labels: { severity: critical }
        annotations: { summary: "High memory usage detected" }

      - alert: DiskSpaceCritical
        expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100 > 90
        for: 5m
        labels: { severity: critical }
        annotations: { summary: "Disk space critically low" }

    - name: gpu-monitoring
      rules:
      - alert: GPUHighTemperature
        expr: nvidia_gpu_temperature_celsius > 80
        for: 5m
        labels: { severity: warning }
        annotations: { summary: "GPU temperature high" }

      - alert: GPUMemoryHigh
        expr: (nvidia_gpu_memory_used_bytes / nvidia_gpu_memory_total_bytes) * 100 > 90
        for: 10m
        labels: { severity: warning }
        annotations: { summary: "GPU memory usage high" }
    ```

2. **Alertmanager notification config (webhook/email):**
    ```yaml
    receivers:
      - name: 'critical-alerts'
        webhook_configs:
        - url: 'http://host.containers.internal:9999/webhook/critical'
          send_resolved: true
          title: 'CRITICAL: { range .Alerts }{ .Annotations.summary }{ end }'

      - name: 'warning-alerts'
        webhook_configs:
        - url: 'http://host.containers.internal:9999/webhook/warning'
          send_resolved: true
          title: 'WARNING: { range .Alerts }{ .Annotations.summary }{ end }'
    ```

3. **Reload config:**
    ```bash
    sudo nixos-rebuild switch
    ```

4. **Validate:**  
    - Test an alert (e.g., fill disk, simulate GPU overuse).
    - Check notifications are delivered (webhook or email).

---

## Business and Media Metrics Integration

**Goal:**  
Expose business dashboard and metrics for full-stack observability.

### Steps

1. **Expose business service metrics in Nix config:**
    ```nix
    business-metrics = {
      environment = {
        PROMETHEUS_ENABLED = "true";
        METRICS_PORT = "9999";
      };
      ports = [ "9999:9999" "8501:8501" ];
    };
    business-dashboard = {
      environment = {
        PROMETHEUS_ENABLED = "true";
        METRICS_PORT = "9998";
      };
      ports = [ "8501:8501" "9998:9998" ];
    };
    ```

2. **Prometheus scrape configs:**
    ```yaml
    scrape_configs:
      - job_name: 'business-services'
        static_configs:
          - targets: ['host.containers.internal:9999', 'host.containers.internal:9998']
        scrape_interval: 30s
    ```

3. **Reload config:**
    ```bash
    sudo nixos-rebuild switch
    ```

4. **Validate:**  
    - Prometheus targets "business-services" should be **UP**.
    - Grafana dashboards include business metrics.

---

## Testing, Rollback, and Validation

### Testing

- After each change:
    ```bash
    sudo nixos-rebuild test --flake .#$(hostname)
    sudo podman ps
    sudo podman logs <service>
    ```

- Check Grafana dashboards, Prometheus targets, and Alertmanager status.

### Rollback

- All configs are version-controlled.  
- To revert:
    ```bash
    sudo git checkout <previous-commit>
    sudo nixos-rebuild switch
    ```

- For a single module:
    ```bash
    sudo cp /etc/nixos/hosts/server/modules/<file>.backup /etc/nixos/hosts/server/modules/<file>
    sudo nixos-rebuild switch
    ```

---

## References

- `MONITORING_OPTIMIZATION_GUIDE.md`
- `GPU_ACCELERATION_GUIDE.md`
- NixOS official docs: https://nixos.org/manual

---

*End of Phase 2 Monitoring Stack Optimization*
