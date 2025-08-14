# Phase 4 — Advanced Features and Future-Proofing

**Agent 3: Media Pipeline & Monitoring Optimization**

**Date:** 2025-08-06

---

## Executive Summary

Phase 4 advances your NixOS media/monitoring platform into a future-ready, high-reliability system with advanced automation, resource management, and self-healing.  
This guide covers GPU utilization optimization, automated storage management, cross-application integration, and proactive monitoring enhancements.

---

## Table of Contents

1. [GPU Acceleration Enhancement](#gpu-acceleration-enhancement)
2. [Automated Storage & Media Pipeline Management](#automated-storage--media-pipeline-management)
3. [Cross-Application Integration & Automation](#cross-application-integration--automation)
4. [Advanced Monitoring and Alerting](#advanced-monitoring-and-alerting)
5. [Long-Term Maintenance, Upgrades, and Capacity Planning](#long-term-maintenance-upgrades-and-capacity-planning)

---

## GPU Acceleration Enhancement

**Goal:**  
Ensure all services leverage the GPU efficiently, with resource sharing and limits to avoid contention.

### Steps

1. **Add/Refine GPU Options Globally:**

    In `/etc/nixos/modules/containers/common.nix` or service modules:

    ```nix
    nvidiaRuntimeOptions = [ "--runtime=nvidia" "--gpus=all" ];
    gpuLimits = [
      "--gpus=device=0"
      "--memory=4g"
    ];
    ```

2. **Apply to all media/business/monitoring services:**

    ```nix
    extraOptions = mediaNetworkOptions ++ nvidiaGpuOptions ++ nvidiaRuntimeOptions ++ gpuLimits;
    ```

3. **Enable CUDA MPS for multi-process sharing:**  
    - Add to environment:

    ```nix
    environment = nvidiaEnv // {
      CUDA_MPS_PIPE_DIRECTORY = "/tmp/nvidia-mps";
      CUDA_MPS_LOG_DIRECTORY = "/tmp/nvidia-log";
      NVIDIA_MPS_PIPE_DIRECTORY = "/tmp/nvidia-mps";
    };
    ```

4. **Validate in each container:**

    ```bash
    sudo podman exec -it <container> nvidia-smi
    ```

    - Confirm all containers see the GPU, but VRAM usage is managed and does not exceed 4GB.

---

## Automated Storage & Media Pipeline Management

**Goal:**  
Achieve self-healing storage, automated migration, and predictive cleanup.

### Steps

1. **Predictive Storage Cleanup (expand on earlier cron):**

    ```nix
    systemd.services.advanced-storage-cleanup = {
      description = "Predictive and intelligent storage cleanup";
      startAt = "hourly";
      script = ''
        HOT_USED=$(df /mnt/hot | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ $HOT_USED -gt 85 ]; then
          # Aggressively delete temp files and oldest downloads
          find /mnt/hot/downloads -type f -mtime +7 -delete
          find /mnt/hot/cache -type f -mtime +3 -delete
          logger "Advanced storage cleanup: aggressive mode triggered"
        fi
      '';
    };
    ```

2. **Automated Migration with Validation:**

    ```nix
    systemd.services.advanced-media-migration = {
      description = "Migrate verified media to cold storage";
      startAt = "hourly";
      script = ''
        for DIR in movies tv music; do
          SRC="/mnt/hot/downloads/$DIR/complete"
          DST="/mnt/media/$DIR/"
          if [ -d "$SRC" ]; then
            rsync -av --remove-source-files --checksum "$SRC/" "$DST"
            logger "Migrated $DIR from hot to cold storage"
          fi
        done
      '';
    };
    ```

3. **Self-Healing Orphan Cleanup:**

    ```nix
    systemd.services.orphan-cleanup = {
      description = "Clean up orphaned files and broken links";
      startAt = "weekly";
      script = ''
        find /mnt/hot -type l ! -exec test -e {} \; -delete
        logger "Orphaned symlink cleanup complete"
      '';
    };
    ```

---

## Cross-Application Integration & Automation

**Goal:**  
Achieve deep linking between media, monitoring, business, and request/notification flows.

### Steps

1. **Cross-App Notification Scripts:**  
    - Add scripts that send events (motion, downloads, failures) from Frigate/*arr to business dashboard, or pushwebhook/email.

    ```nix
    systemd.services.frigate-to-business-notify = {
      description = "Forward Frigate events to business dashboard";
      path = [ pkgs.curl ];
      script = ''
        curl -X POST http://localhost:9999/api/event             -d "type=frigate_motion&camera=$CAM"             -d "timestamp=$(date +%s)"
      '';
    };
    ```

2. **Overseerr Request Management Integration (optional):**

    ```nix
    overseerr = {
      image = "sctx/overseerr:latest";
      autoStart = true;
      extraOptions = mediaNetworkOptions;
      ports = [ "5055:5055" ];
      volumes = [
        "/mnt/hot/config/overseerr:/app/config"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = mediaServiceEnv;
    };
    ```

---

## Advanced Monitoring and Alerting

**Goal:**  
Add custom metrics, trend analysis, and advanced alerting beyond defaults.

### Steps

1. **Custom Metric Collectors:**  
    - Extend `/etc/nixos/hosts/server/modules/monitoring.nix`:

    ```nix
    systemd.services.custom-metrics = {
      description = "Collect advanced custom metrics";
      startAt = "*:*:30";
      script = ''
        # Example: Media pipeline queue latency
        LAT=$(curl -s http://localhost:8501/metrics | grep media_pipeline_latency | awk '{print $2}')
        echo "media_pipeline_latency_seconds $LAT" > /var/lib/node_exporter/textfile_collector/media_pipeline.prom
      '';
    };
    ```

2. **Prometheus recording rules for trend analysis:**

    ```yaml
    groups:
    - name: advanced-metrics
      rules:
      - record: job:gpu_util_5m:avg
        expr: avg_over_time(nvidia_gpu_utilization_percentage[5m])
      - record: job:hot_storage_1h:max
        expr: max_over_time(storage_hot_usage_percentage[1h])
    ```

3. **Alert rules for trends (not just instant values):**

    ```yaml
    - alert: HotStorageSlowlyFilling
      expr: increase(storage_hot_usage_percentage[6h]) > 10
      for: 30m
      labels: { severity: warning }
      annotations: { summary: "Hot storage filling rapidly over last 6h" }
    ```

---

## Long-Term Maintenance, Upgrades, and Capacity Planning

**Goal:**  
Plan for growth, proactive upgrades, and maintain high reliability.

### Steps

1. **Quarterly Review Tasks:**
    - Review NixOS channel and service upgrades.
    - Test disaster recovery with simulated failures.
    - Monitor hardware utilization, plan RAM/disk/GPU upgrades.
    - Review security (SOPS keys, user/group membership).

2. **Capacity Planning Checklist:**
    - Check `/mnt/hot` and `/mnt/media` utilization.
    - Monitor concurrent GPU workload counts.
    - Analyze alert frequency for tuning thresholds.
    - Keep system diagrams and docs up to date.

3. **Performance Benchmarking:**
    - Use Grafana trends and Prometheus recording rules to benchmark:
        - Transcode speed
        - Detection latency
        - Pipeline queue depth
        - Alert response time

4. **Upgrade Recommendations:**
    - When concurrent GPU sessions exceed 2 and blocking occurs, plan for RTX or Quadro card with more VRAM.
    - Monitor NixOS release notes for kernel/driver upgrades impacting hardware support.

---

## References

- `OPTIMIZATION_SUMMARY.md`
- `MONITORING_OPTIMIZATION_GUIDE.md`
- `GPU_ACCELERATION_GUIDE.md`
- NixOS channels: https://channels.nixos.org/
- Official Prometheus and Grafana docs

---

*End of Phase 4 Advanced Features and Future-Proofing*

