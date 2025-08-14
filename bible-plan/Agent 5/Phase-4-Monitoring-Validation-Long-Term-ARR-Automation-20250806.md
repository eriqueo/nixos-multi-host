
# Phase 4 — Monitoring, Validation, and Long-Term ARR Automation

**Agent 5: ARR Pipeline Automation & File Normalization Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

This phase makes your ARR + Soulseek pipeline self-monitoring, auditable, and robust for the long term:
- Pipeline health monitoring at each stage (download, normalization, migration, ARR import)
- Automated error/alerting via Prometheus/Grafana
- Operator runbooks for incident response and continuous improvement
- Best practices for ARR pipeline resilience and maintainability

---

## Table of Contents

1. Pipeline Monitoring & Metrics
2. Alerting & Grafana Panels
3. Ongoing Validation & Self-Checks
4. Operator Runbook (Incident Response)
5. Long-Term Maintenance & Best Practices
6. References

---

## 1. Pipeline Monitoring & Metrics

### Prometheus Metrics to Track

- Container health for:  
  - sonarr, radarr, lidarr, prowlarr, slskd, soularr, qbittorrent, sabnzbd
- Script success/failure for:  
  - normalization  
  - migration to cold storage
- ARR import API response/error rate
- Number of files in:
  - `/mnt/hot/downloads`
  - `/mnt/hot/normalized`
  - `/mnt/media/unsorted-*`
- Stale file detection (files not processed in >24h)

#### Example Custom Metric Collector

```bash
#!/usr/bin/env bash
# collect_arr_metrics.sh

HOT_COUNT=$(find /mnt/hot/downloads -type f | wc -l)
NORM_COUNT=$(find /mnt/hot/normalized -type f | wc -l)
COLD_UNSORTED=$(find /mnt/media -type d -name "unsorted*" | wc -l)
echo "arr_pipeline_hot_files $HOT_COUNT" > /var/lib/node_exporter/textfile_collector/arr_pipeline.prom
echo "arr_pipeline_normalized_files $NORM_COUNT" >> /var/lib/node_exporter/textfile_collector/arr_pipeline.prom
echo "arr_pipeline_cold_unsorted_dirs $COLD_UNSORTED" >> /var/lib/node_exporter/textfile_collector/arr_pipeline.prom
```

Integrate via NixOS systemd:

```nix
systemd.services.arr-metrics-collector = {
  description = "Collect ARR pipeline metrics for Prometheus";
  startAt = "*:0/5";
  script = "/mnt/scripts/collect_arr_metrics.sh";
};
```

---

## 2. Alerting & Grafana Panels

### Prometheus Alert Rules

```yaml
groups:
- name: arr-pipeline
  rules:
  - alert: ARRNormalizationFailure
    expr: arr_pipeline_hot_files > 0 and arr_pipeline_normalized_files == 0
    for: 1h
    labels: { severity: warning }
    annotations: { summary: "Files stuck in downloads, not normalizing." }

  - alert: ColdStorageUnsortedGrowing
    expr: arr_pipeline_cold_unsorted_dirs > 1
    for: 2h
    labels: { severity: warning }
    annotations: { summary: "Unsorted cold storage directories need review." }

  - alert: ARRServiceDown
    expr: up{job=~"sonarr|radarr|lidarr|prowlarr|slskd|soularr"} == 0
    for: 5m
    labels: { severity: critical }
    annotations: { summary: "One or more ARR/Soulseek services are down." }
```

### Grafana Panels

- Files in each pipeline stage (downloads, normalized, cold/unsorted)
- *arr service status and response time
- Script and import failure rates
- Long-term trend: average time from download to cold storage

---

## 3. Ongoing Validation & Self-Checks

- **Self-test systemd timer:**  
  - Run daily dry-run of normalization/migration with verbose output to log and alert on failure
- **Automated ARR API sanity check:**  
  - Schedule API pings (health endpoint, import scan) and alert if non-200/OK

---

## 4. Operator Runbook (Incident Response)

**If an alert fires:**

1. **Pipeline stuck (downloads not normalizing):**
   - Check normalization script logs and container health (`sudo podman logs media-normalizer`)
   - Look for unusual filenames or permissions issues in `/mnt/hot/downloads`

2. **Files in cold/unsorted:**
   - Manually review and rename/move files
   - Adjust normalization rules if new patterns encountered

3. **ARR/Soulseek service down:**
   - Check with `systemctl status podman-<service>`
   - Restart as needed, check for config or network issues

4. **ARR import failures:**
   - Review API/log output
   - If import consistently fails for certain patterns, add those cases to normalization logic

---

## 5. Long-Term Maintenance & Best Practices

- Schedule regular review of metrics and pipeline logs (quarterly)
- Update normalization scripts for new scene/Soulseek naming patterns as they evolve
- Document new edge cases and update runbook
- Periodically test full rollback from audit/migration logs
- Maintain all scripts in version control

---

## 6. References

- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)
- [Grafana Panel Configuration](https://grafana.com/docs/grafana/latest/panels/)
- [Sonarr/Radarr API](https://wiki.servarr.com/)
- [NixOS systemd scripting](https://nixos.org/manual/nixos/stable/#sec-systemd-units)

---

*End of Phase 4 Monitoring, Validation, and Long-Term ARR Automation*
