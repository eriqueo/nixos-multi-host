# Phase 2 — Surveillance Automation, Monitoring & Event Integration

**Agent 2: Surveillance/Frigate Optimization Agent**  
**Date:** 2025-08-06

---

## Executive Summary

This guide upgrades your surveillance system with:
- End-to-end health/uptime monitoring (cameras, Frigate, GPU, storage)
- Actionable Prometheus/Grafana dashboards for surveillance
- Event-driven notifications (alertmanager, Telegram, webhook, etc.)
- Automated backup & restore to cold storage
- NixOS-native configs and rollback/test procedures

---

## Table of Contents

1. [Surveillance Monitoring Stack: Healthchecks & Dashboards](#surveillance-monitoring-stack-healthchecks--dashboards)
2. [Prometheus Alerting & Alertmanager Setup](#prometheus-alerting--alertmanager-setup)
3. [Event Notification Integration](#event-notification-integration)
4. [Automated Backup/Restore of Surveillance Footage](#automated-backuprestore-of-surveillance-footage)
5. [Testing, Validation, and Rollback](#testing-validation-and-rollback)
6. [References](#references)

---

## Surveillance Monitoring Stack: Healthchecks & Dashboards

### Camera Healthchecks (systemd + Prometheus Blackbox Exporter)

- **Add Blackbox targets for each RTSP feed** (substitute actual camera IPs):

    ```yaml
    - job_name: 'frigate-cameras'
      metrics_path: /probe
      params:
        module: [tcp_connect]
      static_configs:
        - targets:
          - rtsp://admin:password@192.168.1.101:554/ch01/0
          - rtsp://admin:password@192.168.1.102:554/ch01/0
          # Repeat for each cam
      relabel_configs:
        - source_labels: [__address__]
          target_label: __param_target
        - source_labels: [__param_target]
          target_label: instance
        - target_label: __address__
          replacement: blackbox-exporter:9115
    ```

- **Expose Frigate `/api/stats` and `/live/*` endpoints:**

    ```yaml
    - job_name: 'frigate'
      static_configs:
        - targets: ['host.containers.internal:5000']
      metrics_path: /api/stats
      scrape_interval: 15s
    ```

### Surveillance Dashboard Panels (Grafana)

- **Add panels for:**
    - Per-camera uptime/availability
    - Frigate detection FPS and processing latency
    - GPU utilization (tie to Frigate/other containers)
    - Storage usage (recordings/events)
    - Motion events per hour
    - Healthcheck history (status heatmap)

---

## Prometheus Alerting & Alertmanager Setup

- **Prometheus Rules** for actionable surveillance alerting:

    ```yaml
    groups:
    - name: surveillance
      rules:
      - alert: CameraOffline
        expr: probe_success{job="frigate-cameras"} == 0
        for: 2m
        labels: { severity: critical }
        annotations: { summary: "Surveillance Camera Down", description: "A camera feed is offline." }

      - alert: FrigateHighGPU
        expr: nvidia_gpu_utilization_percentage > 90
        for: 5m
        labels: { severity: warning }
        annotations: { summary: "Frigate GPU Usage High" }

      - alert: SurveillanceStorageCritical
        expr: (node_filesystem_size_bytes{mountpoint="/mnt/hot/surveillance"} - node_filesystem_free_bytes{mountpoint="/mnt/hot/surveillance"}) / node_filesystem_size_bytes{mountpoint="/mnt/hot/surveillance"} * 100 > 95
        for: 2m
        labels: { severity: critical }
        annotations: { summary: "Surveillance Storage Critically Full" }
    ```

- **Alertmanager Routing:**
    - Webhook, email, Telegram, or Slack
    - Example route for critical surveillance alerts:
    ```yaml
    route:
      receiver: 'critical-surveillance'
      group_by: ['alertname']
      match_re:
        severity: critical

    receivers:
    - name: 'critical-surveillance'
      telegram_configs:
      - bot_token: '123456:ABC...'
        chat_id: 987654321
        message: '{ .CommonAnnotations.summary }'
    ```

---

## Event Notification Integration

- **Frigate Event Webhooks:**  
    In `frigate.yml`:
    ```yaml
    mqtt:
      host: mqtt.local
      topic_prefix: frigate
    detectors: ... # existing detectors

    # Frigate can also POST to webhook on events
    detectors: ...
    record:
      enabled: true

    # Add webhook for events
    ffmpeg:
      inputs:
        # ... your camera configs
    event_webhook:
      url: http://localhost:9999/api/event
    ```

- **Optional: Push critical motion to business dashboard or Telegram:**
    - Small Python or Bash API bridge (triggered on Frigate event).

---

## Automated Backup/Restore of Surveillance Footage

- **Automate backup of *important* recordings/events to cold storage:**
    - NixOS-native systemd service:

    ```nix
    systemd.services.frigate-backup = {
      description = "Backup Frigate events to cold storage";
      startAt = "daily";
      script = ''
        SRC="/mnt/hot/surveillance/events/"
        DST="/mnt/media/surveillance/events/"
        rsync -a --remove-source-files "$SRC" "$DST"
        logger "Backed up surveillance events to cold storage"
      '';
    };
    ```

- **Restore is simply rsync from cold to hot if needed.**

---

## Testing, Validation, and Rollback

- After setup:
    - Check Prometheus targets and camera status in Grafana
    - Simulate a camera disconnect (should alert within 2m)
    - Force high GPU utilization (test alert)
    - Trigger Frigate event and check webhook/notification/backup
    - Confirm backup files exist and are purged from hot after copy

- Rollback:
    - Use git for config rollback as in previous phases
    - Use `.backup` files for critical modules if needed

---

## References

- [Frigate Monitoring & Prometheus](https://docs.frigate.video/integrations/prometheus/)
- [Frigate Event Webhooks](https://docs.frigate.video/integrations/webhook/)
- [Prometheus Blackbox Exporter](https://prometheus.io/docs/blackbox_exporter/)
- [Alertmanager Telegram Example](https://prometheus.io/docs/alerting/latest/configuration/#telegram_config)
- [NixOS systemd services](https://nixos.org/manual/nixos/stable/#sec-systemd-units)

---

*End of Phase 2 Surveillance Automation, Monitoring & Event Integration*
