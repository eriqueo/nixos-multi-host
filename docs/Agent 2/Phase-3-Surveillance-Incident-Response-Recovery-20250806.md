# Phase 3 — Surveillance Incident Response, Recovery, & Continuous Improvement

**Agent 2: Surveillance/Frigate Optimization Agent**  
**Date:** 2025-08-06

---

## Executive Summary

Phase 3 covers full lifecycle incident response and recovery for surveillance:  
- Automated and manual recovery from Frigate/camera failures
- Self-healing and rollback scripts
- Audit logging and post-mortem generation
- Continuous improvement cycles (incident → config → prevention)
- NixOS-native methods for all playbooks

---

## Table of Contents

1. [Incident Detection and Notification](#incident-detection-and-notification)
2. [Automated Recovery & Self-Healing](#automated-recovery--self-healing)
3. [Manual Recovery & Forensic Logging](#manual-recovery--forensic-logging)
4. [Audit Logging and Post-Mortem Reporting](#audit-logging-and-post-mortem-reporting)
5. [Continuous Improvement Workflow](#continuous-improvement-workflow)
6. [References](#references)

---

## Incident Detection and Notification

- **Prometheus Alerts from Phase 2** will surface:
    - Camera offline/unavailable
    - Frigate or GPU overload
    - Storage critical
    - Backup failures
- **Alertmanager** routes to dashboard, webhook, or Telegram

---

## Automated Recovery & Self-Healing

- **systemd Restart-on-Failure for Frigate/Camera Services:**

    ```nix
    systemd.services.podman-frigate = {
      # ...existing config
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "10s";
        StartLimitBurst = 5;
        StartLimitIntervalSec = 300;
      };
    };
    ```

- **Camera Watchdog:**
    ```nix
    systemd.services.camera-watchdog = {
      description = "Restart camera service on healthcheck failure";
      startAt = "every 10 minutes";
      script = ''
        for CAM in 101 102 103 104; do
          if ! ffprobe -v error -rtsp_transport tcp -i rtsp://admin:password@192.168.1.$CAM:554/ch01/0; then
            logger "Camera $CAM unresponsive, triggering PoE cycle or alert"
            # Optional: cycle PoE or send webhook to hardware switch
          fi
        done
      '';
    };
    ```

- **Auto-Fix Storage Pruning Failures:**
    - If prune script fails (cannot delete), alert and try to forcibly remount disk, or escalate to admin.

---

## Manual Recovery & Forensic Logging

- **Log Incident Context Automatically:**
    ```nix
    systemd.services.surveillance-incident-log = {
      description = "Log and archive surveillance incident context";
      script = ''
        INCIDENT_FILE="/mnt/hot/audit/incident-$(date +%F-%T).log"
        echo "Incident at $(date)" > "$INCIDENT_FILE"
        echo "GPU status:" >> "$INCIDENT_FILE"
        nvidia-smi >> "$INCIDENT_FILE" 2>&1
        echo "Camera status:" >> "$INCIDENT_FILE"
        podman logs frigate >> "$INCIDENT_FILE" 2>&1
        df -h /mnt/hot/surveillance >> "$INCIDENT_FILE"
      '';
    };
    ```

- **Manual Playbook:**
    - If Frigate fails to recover, check logs, check `nvidia-smi`, restart with:
        ```bash
        sudo systemctl restart podman-frigate.service
        ```
    - If a camera is dead, verify network, power, and RTSP with `ffprobe`.
    - If storage is full and cannot prune, escalate and move old data manually.

---

## Audit Logging and Post-Mortem Reporting

- **Automatic Audit Log on Recovery:**  
    Every systemd service that recovers from failure logs timestamp and context to `/mnt/hot/audit/`.

- **Generate Post-Mortem:**
    - After major incident, run:
        ```bash
        ./generate-postmortem.sh /mnt/hot/audit/incident-*.log
        ```
    - Summarizes root cause, timeline, actions taken.

---

## Continuous Improvement Workflow

- **Every incident triggers:**
    - Root cause analysis
    - Config review and update (document in `/etc/nixos/docs/`)
    - Regression test before close
    - Schedule follow-up (weekly/monthly) for high-frequency issues

- **Metrics:**  
    - Track mean time to recovery, false alert rate, recurrence

---

## References

- [NixOS systemd documentation](https://nixos.org/manual/nixos/stable/#sec-systemd-units)
- [Frigate troubleshooting](https://docs.frigate.video/troubleshooting/)
- [Prometheus Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Best practices for PoE recovery](https://community.ui.com/questions)

---

*End of Phase 3 Surveillance Incident Response, Recovery, & Continuous Improvement*
