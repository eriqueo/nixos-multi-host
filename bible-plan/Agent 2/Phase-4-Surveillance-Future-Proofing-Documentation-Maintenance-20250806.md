# Phase 4 — Surveillance Future-Proofing, Documentation, and Proactive Maintenance

**Agent 2: Surveillance/Frigate Optimization Agent**  
**Date:** 2025-08-06

---

## Executive Summary

Phase 4 future-proofs your NixOS-based surveillance system:  
- Structured documentation and runbooks for all Frigate/camera/NVR procedures  
- Scheduled quarterly/annual reviews for capacity, retention, and upgrades  
- Security hardening, backup verification, and onboarding guide  
- Strategic planning for hardware/software growth

---

## Table of Contents

1. [Documentation Best Practices & Templates](#documentation-best-practices--templates)
2. [Quarterly & Annual Maintenance Tasks](#quarterly--annual-maintenance-tasks)
3. [Runbook Printouts for Operators](#runbook-printouts-for-operators)
4. [Security Hardening & Backup Verification](#security-hardening--backup-verification)
5. [Upgrade & Expansion Planning](#upgrade--expansion-planning)
6. [References](#references)

---

## Documentation Best Practices & Templates

- **All surveillance configs (NixOS modules, Frigate YAMLs, scripts) should be documented in `/etc/nixos/docs/surveillance/`**
- **Use Markdown runbook template:**
    ```
    ## [Procedure Name]

    - **Date**: YYYY-MM-DD
    - **Purpose**: Why/When to use
    - **Operator Steps**:
        1. ...
        2. ...
    - **Config Files**: [Path, backup method]
    - **Validation**: How to confirm it worked
    - **Rollback**: How to undo
    - **Incident Contacts**: Name, contact, escalation steps
    ```

- **Document every major upgrade, retention policy change, and incident post-mortem.**

---

## Quarterly & Annual Maintenance Tasks

- **Quarterly:**
    - Review Frigate/NixOS channel and camera firmware upgrades
    - Test rollback for every service (`nixos-rebuild test` + git)
    - Validate backup restore from cold storage
    - Clean PoE and camera cabling/connections
    - Confirm motion masks/zones still match scene (cameras move, trees grow!)

- **Annual:**
    - Recalculate retention based on footage use (are 2TB and 10 days still optimal?)
    - Benchmark detection latency and storage overhead (report in audit logs)
    - Full security audit (SOPS, operator credentials, firewall)
    - Update onboarding/runbooks for any new system features

---

## Runbook Printouts for Operators

- **Store “last known good” printout (digital and paper) of:**
    - Camera IPs, passwords (secure location)
    - Frigate config locations and restart commands
    - Storage layout, free/used space, prune scripts
    - Emergency recovery: “If Frigate won’t start,” “If storage is full,” etc.
    - Incident report template (for techs)

---

## Security Hardening & Backup Verification

- **Rotate all passwords and SOPS secrets annually**
- **Confirm only authorized operator SSH keys present**
- **Review systemd service permissions (run as non-root where possible)**
- **Test restore of a random week’s surveillance backup every quarter**
- **Review and, if needed, harden firewall rules (NixOS firewall module)**
- **Document any cloud or remote monitoring endpoints for external access (VPN, Tailscale, etc.)**

---

## Upgrade & Expansion Planning

- **Frigate Upgrades:**
    - Schedule at least one annual test of new Frigate releases on non-production or test hardware
    - Monitor official changelogs for breaking changes to detection, database, or event systems

- **NVIDIA/Hardware:**
    - If you consistently hit GPU or VRAM limits, spec next-generation (Ampere or Ada) for increased concurrent streams
    - Budget for camera expansion (PoE, NVR port count, SSD/HDD upgrades)
    - Consider hot-spare camera for physical redundancy

- **Capacity Planning:**
    - Keep logs of annual storage use, prune frequency, and retention
    - Document justification for retention policy in audit log

---

## References

- [Frigate documentation](https://docs.frigate.video/)
- [NixOS systemd maintenance](https://nixos.org/manual/nixos/stable/#sec-systemd-units)
- [Uptime/health monitoring best practices](https://grafana.com/docs/grafana/latest/)
- [SOPS key rotation](https://github.com/mozilla/sops)

---

*End of Phase 4 Surveillance Future-Proofing, Documentation, and Proactive Maintenance*
