
# Phase 4 — Disaster Recovery Runbook & Operator Printouts

**Agent 10: Backup & Disaster Recovery Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

This is your emergency, print-friendly runbook for restoring any or all of your infrastructure after loss, corruption, or catastrophic failure.  
- All essential backup and recovery steps for configs, media, business data, surveillance, secrets, databases, and Samba shares  
- Operator checklists for USB/NAS/cloud restore  
- “Break glass” disaster card for fast recovery under stress  
- Documentation for ongoing training, onboarding, and periodic review

---

## Table of Contents

1. When to Use This Runbook
2. Pre-Recovery Device/Access Checklist
3. Full System Recovery (All-Drives, Config, Media, Surveillance, Business)
4. Single Directory or Single Machine Recovery
5. Samba Share Recovery (Windows/Mac Clients)
6. Secrets & Database Recovery
7. Post-Recovery Validation & Sign-Off
8. Printout & Storage Guidance
9. References

---

## 1. When to Use This Runbook

- System won’t boot, critical files lost/corrupt, malware/ransomware event
- Accidental rm -rf, filesystem error, or physical disaster
- Media/business/surveillance content unrecoverable from main storage
- Routine annual restore test (training, compliance)

---

## 2. Pre-Recovery Device/Access Checklist

- At least one *known-good* backup device: USB, NAS, or cloud login
- Live USB/CD for booting into rescue mode (NixOS installer, Ubuntu, etc.)
- All required credentials for decrypting backups/SOPS secrets
- Physical access to server, all cables, power
- Printout of this runbook (keep one in IT “break glass” binder!)

---

## 3. Full System Recovery (All-Drives, Config, Media, Surveillance, Business)

1. **Boot from live USB/CD if system won’t boot**
2. **Mount root partition and backup device(s):**
    ```bash
    sudo mount /dev/sdXY /mnt
    sudo mount /dev/sdXZ /mnt/usb-backup
    ```
3. **Restore NixOS config:**
    ```bash
    sudo rsync -aAXv /mnt/usb-backup/nixos-config/ /mnt/etc/nixos/
    ```
4. **Restore media, surveillance, business:**
    ```bash
    sudo rsync -aAXv /mnt/usb-backup/media/ /mnt/media/
    sudo rsync -aAXv /mnt/usb-backup/receipts/ /mnt/srv/business/receipts/
    sudo rsync -aAXv /mnt/usb-backup/surveillance/ /mnt/hot/surveillance/
    ```
5. **Restore secrets:**
    ```bash
    sudo rsync -aAXv /mnt/usb-backup/sops/ /mnt/etc/sops/
    ```
6. **Restore database:**
    - PostgreSQL: Copy dump and restore using `pg_restore` or `psql`
    - Example:
        ```bash
        sudo -u postgres pg_restore -C -d postgres /mnt/usb-backup/db-backups/db-latest.dump
        ```
7. **Reboot or chroot for bootloader/grub repair if needed**

---

## 4. Single Directory or Single Machine Recovery

1. **Mount backup and production target:**
    ```bash
    sudo mount /mnt/usb-backup
    sudo mount /mnt/media/
    ```
2. **Restore target directory:**
    ```bash
    sudo rsync -aAXv /mnt/usb-backup/media/movies/ /mnt/media/movies/
    ```
3. **For configs/scripts:**  
    Restore `/mnt/usb-backup/nixos-config/` to `/etc/nixos/`

---

## 5. Samba Share Recovery (Windows/Mac Clients)

- Confirm server-side files are restored in `/srv/share/`
- Check `/etc/samba/smb.conf` and restart samba:
    ```bash
    sudo systemctl restart smb.service nmb.service
    ```
- Windows/Mac users reconnect using original credentials

---

## 6. Secrets & Database Recovery

- All SOPS/age secrets must be present and decrypted using age keyfile or GPG
- For full-system restore, restore `/etc/sops/` or `/srv/secrets/`
- For database, use most recent `pg_dump` or `pg_restore`  
    - Test DB connectivity before production switchover

---

## 7. Post-Recovery Validation & Sign-Off

- Verify:
    - NixOS boots and services start
    - Media, business, surveillance data accessible
    - Samba shares visible to clients
    - Databases/restored apps respond to queries
- Run full audit/restore test script:
    ```bash
    bash /mnt/scripts/test_restore_nixos_config.sh
    ```
- Log outcome and lessons-learned in `/etc/nixos/docs/backup/restore-tests.md`

---

## 8. Printout & Storage Guidance

- Print this runbook and store a copy:
    - In server rack “break glass” envelope
    - In IT/ops documentation binder
    - With offsite/cloud recovery keys if possible
- Review and reprint after every major config/data update, or at least annually

---

## 9. References

- [NixOS recovery manual](https://nixos.org/manual/nixos/stable/#ch-installation)
- [rsync documentation](https://download.samba.org/pub/rsync/rsync.html)
- [PostgreSQL restore](https://www.postgresql.org/docs/current/app-pgrestore.html)
- [SOPS/age documentation](https://github.com/mozilla/sops)

---

*End of Phase 4 Disaster Recovery Runbook & Operator Printouts*
