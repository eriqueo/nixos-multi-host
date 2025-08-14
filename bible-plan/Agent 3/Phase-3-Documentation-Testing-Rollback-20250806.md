# Phase 3 — Documentation, Testing, and Rollback

**Agent 3: Media Pipeline & Monitoring Optimization**

**Date:** 2025-08-06

---

## Executive Summary

This phase establishes rigorous documentation, testing, and rollback procedures to ensure your NixOS media and monitoring system remains stable, auditable, and easy to recover or iterate on.  
All actions are NixOS-native and designed for high reliability, with minimal manual intervention.

---

## Table of Contents

1. [Documentation Standards](#documentation-standards)
2. [Testing and Validation Checklist](#testing-and-validation-checklist)
3. [Rollback and Recovery Procedures](#rollback-and-recovery-procedures)
4. [Version Control Best Practices](#version-control-best-practices)
5. [Post-Upgrade Monitoring](#post-upgrade-monitoring)

---

## Documentation Standards

**Goal:**  
Make every configuration and operational step reproducible and reviewable.

### Steps

1. **Every change must be described in a Markdown doc in `/etc/nixos/docs/`**:
    - What was changed and why
    - Exact file(s) and line(s) touched
    - Rollback command (git or manual)
    - Links to code blocks or previous guide phases

2. **Template for each change:**
    ```
    ### [Title of Change]

    - **Date**: YYYY-MM-DD
    - **Purpose**: Brief reason
    - **Files/Lines Modified**: /etc/nixos/...
    - **How to Roll Back**: [git commit hash or cp .backup]
    - **Validation**: How to confirm it worked
    - **Notes**: [Links, references]
    ```

3. **Store all monitoring, *arr, GPU, and storage scripts/configs with in-file comments:**
    - At top: Purpose, date, author/agent, rollback instructions

---

## Testing and Validation Checklist

**Goal:**  
Ensure changes don’t break production, are observable, and can be validated easily.

### System Rebuild/Config Validation

```bash
sudo nixos-rebuild test --flake .#$(hostname)
```
- *Does not reload services; safe for pre-checking syntax and configuration logic.*

### Service/Container Health

```bash
sudo podman ps
sudo podman logs <service>
```
- Confirm all services are up, with no restart loops or errors.

### GPU/Hardware Validation

```bash
nvidia-smi
watch -n 1 nvidia-smi
```
- Should show usage/activity for media and monitoring workloads.

### Grafana & Prometheus Validation

- Open Grafana: `http://localhost:3000`
    - Dashboards load and show recent data.
- Open Prometheus: `http://localhost:9090`
    - All targets UP (nvidia-gpu, cadvisor, node-exporter, etc).

### Alert Testing

- Simulate conditions (fill disk, stress GPU, stop service) to trigger:
    - Prometheus alert rules
    - Alertmanager notifications

### Business & Media Metric Checks

- Access business dashboard and metrics URLs (ports 8501, 9999, 9998).
- Confirm data is scraped and visualized in Grafana.

---

## Rollback and Recovery Procedures

**Goal:**  
Enable immediate reversion if a change causes breakage or instability.

### Git-Based Rollback

- All config directories are under git.
- To view history:

    ```bash
    cd /etc/nixos
    git log --oneline
    ```

- To revert to a specific commit:

    ```bash
    sudo git checkout <commit-hash>
    sudo nixos-rebuild switch
    ```

### Per-Module Backup and Restore

- Before editing, backup each Nix module/file:

    ```bash
    sudo cp /etc/nixos/hosts/server/modules/media-containers.nix /etc/nixos/hosts/server/modules/media-containers.nix.backup
    ```

- To restore:

    ```bash
    sudo cp /etc/nixos/hosts/server/modules/media-containers.nix.backup /etc/nixos/hosts/server/modules/media-containers.nix
    sudo nixos-rebuild switch
    ```

### Emergency Service Restart

- Restart all services:

    ```bash
    sudo systemctl restart podman.service
    sudo systemctl daemon-reload
    ```

- Check container health again.

---

## Version Control Best Practices

- **Commit after each successful test and deploy:**

    ```bash
    sudo git add .
    sudo git commit -m "Describe change: e.g. Add GPU exporter and fix Grafana dashboard"
    sudo git push
    ```

- **Use `grebuild` if defined for atomic commit+deploy:**

    ```bash
    grebuild "Describe change"
    ```

- **Push regularly, and always before/after major config or module edits.**

---

## Post-Upgrade Monitoring

- After every major deployment or rollback:
    - Monitor:
        - System load (`htop`)
        - Service status (`podman ps`)
        - Grafana dashboards (uptime, errors, lag)
        - Prometheus alerts and silence status

- Schedule a manual review (weekly/monthly) of:
    - Hot/cold storage utilization
    - Backup status
    - Alert trends (false positives/negatives)

---

## References

- All prior Markdown files (Phase 1, Phase 2)
- NixOS best practices: https://nixos.org/manual
- Your system docs: `/etc/nixos/docs/`, `MASTER_TODO_LIST.md`, `TROUBLESHOOTING.md`

---

*End of Phase 3 Documentation, Testing, and Rollback*

