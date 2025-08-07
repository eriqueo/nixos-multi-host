
# Phase 1 — Backup Architecture & Coverage Map (USB/NAS/Samba Ready)

**Agent 10: Backup & Disaster Recovery Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

This guide maps a robust, NixOS-native, operator-friendly backup strategy for:
- Hot/cold media, config, receipts, databases, surveillance, SOPS secrets, and business data
- External USB drives (plug-and-play), NAS/DAS targets, and expansion to cloud/offsite
- Safe sharing with Windows/Mac/Linux (Samba integration)
- Simple operator flow for backup/restore from any supported destination

---

## Table of Contents

1. Backup Architecture Principles
2. Critical Data Inventory & Coverage Map
3. Devices: USB, NAS, and Future Cloud
4. Samba Share Integration
5. Inclusion/Exclusion Lists (Sample)
6. Operator Printouts (Plug-In/Restore)
7. Preparation for Automation & Future Phases

---

## 1. Backup Architecture Principles

- **Redundancy:** At least 2 independent backup destinations (USB + NAS/DAS, or USB + cloud in future)
- **Tested Restore:** Every backup is only as good as its latest *restore test*—automate this
- **Immutability/Rotation:** Optionally keep versions, never overwrite last-known-good
- **Encryption:** All SOPS/age secrets, sensitive data, and (optionally) full-disk backup encrypted before leaving source
- **Operator Simplicity:** Printout with “plug in, click or run this, unplug” for USB; “mount and run” for NAS/DAS

---

## 2. Critical Data Inventory & Coverage Map

| **Data Type**       | **Source Directory**       | **Priority** | **Backup Target(s)**      | **Frequency**  |
|---------------------|---------------------------|--------------|---------------------------|----------------|
| NixOS Configs       | `/etc/nixos/`             | High         | USB/NAS/Cloud             | daily/weekly   |
| Media - Movies      | `/mnt/media/movies/`      | High         | USB/NAS                   | weekly         |
| Media - TV          | `/mnt/media/tv/`          | High         | USB/NAS                   | weekly         |
| Media - Music       | `/mnt/media/music/`       | Medium       | USB/NAS                   | weekly         |
| Surveillance        | `/mnt/hot/surveillance/`  | High         | USB/NAS                   | daily/weekly   |
| Downloads (hot)     | `/mnt/hot/normalized/`    | Low          | USB (optional)            | manual         |
| Receipts/Business   | `/srv/business/receipts/` | High         | USB/NAS/Cloud             | daily          |
| PostgreSQL Dumps    | `/var/lib/postgresql/` or `/srv/db-backups/` | High | USB/NAS/Cloud | daily |
| SOPS/age Secrets    | `/etc/sops/` or `/srv/secrets/` | Critical | USB (encrypted) | daily/weekly |
| Samba Shares        | `/srv/share/`             | Medium       | USB/NAS                   | manual/weekly  |
| Operator Scripts    | `/mnt/scripts/`           | High         | USB/NAS                   | weekly         |

---

## 3. Devices: USB, NAS, and Future Cloud

- **USB:**  
  - Ext4/exFAT recommended for Linux-native; NTFS if sharing with Windows  
  - Use labels like `BU-2025-MEDIA`, `BU-2025-CONFIG`  
  - Plug-and-play scripts auto-mount and prompt backup/restore
- **NAS/DAS:**  
  - NFS, SMB/CIFS, or direct-attached block device  
  - Mounts under `/mnt/backup-nas/` or `/mnt/backup-das/`  
  - Set up fstab/systemd automount for regular use
- **Cloud/Offsite (future):**  
  - Use rclone, restic, or borg for cloud targets (B2, Wasabi, S3, etc.)
  - Preparation: keep all backup scripts cloud-target ready

---

## 4. Samba Share Integration

- **All data to be shared with Windows/Mac must live under `/srv/share/` or a subfolder**
- **Samba config (`/etc/samba/smb.conf`)** example for backup destination:
    ```
    [media_backup]
        path = /mnt/media/
        read only = yes
        guest ok = yes
    [config_backup]
        path = /etc/nixos/
        read only = yes
        guest ok = no
    ```
- **Backups of Samba shares:**  
  - Can be initiated from server or client (rsync/smbclient for Linux/macOS, drag-and-drop for Windows)

---

## 5. Inclusion/Exclusion Lists (Sample)

- **Include:**  
  - All critical directories (see map above)
  - `--links`, `--perms`, `--acls`, `--xattrs` for rsync
- **Exclude:**  
  - `.cache`, `node_modules`, `tmp`, incomplete downloads, any file >100GB (if needed)
  - Use `--exclude-from=/etc/nixos/backup_excludes.txt`

Sample `backup_excludes.txt`:
```
*.tmp
*.bak
/mnt/media/tmp/
*/.cache/
/mnt/hot/downloads/incomplete/
/mnt/hot/surveillance/tmp/
```

---

## 6. Operator Printouts (Plug-In/Restore)

**Plug in USB and back up (Linux):**
1. Insert USB drive.
2. Wait for it to mount at `/mnt/usb-backup/` (autodetect script can be used).
3. Run:
    ```bash
    sudo rsync -aAXv --delete --exclude-from=/etc/nixos/backup_excludes.txt /etc/nixos/ /mnt/usb-backup/nixos-config/
    sudo rsync -aAXv /mnt/media/ /mnt/usb-backup/media/
    ```
4. Confirm completion, safely eject.

**Mount NAS and back up:**
1. Ensure NAS/DAS is mounted at `/mnt/backup-nas/`.
2. Run backup script as above, changing destination.

**Restore from backup:**
1. Plug in USB or mount NAS.
2. Copy files from backup to original location as needed:
    ```bash
    sudo rsync -aAXv /mnt/usb-backup/nixos-config/ /etc/nixos/
    ```

---

## 7. Preparation for Automation & Future Phases

- **Phase 2** will include automated systemd timers, incremental rsync, snapshot logic, and error alerting.
- All scripts will be modular and cloud/NAS/ext-drive ready.
- Operator documentation will be kept under `/etc/nixos/docs/backup/` and updated after every test.

---

## References

- [NixOS manual: Backups](https://nixos.org/manual/nixos/stable/#sec-backups)
- [Rsync documentation](https://download.samba.org/pub/rsync/rsync.html)
- [Samba + Linux backups](https://wiki.archlinux.org/title/Samba#Backups)
- [Restic](https://restic.net/), [Rclone](https://rclone.org/)
- [Automount USB drives in NixOS](https://discourse.nixos.org/t/usb-automount/1795)

---

*End of Phase 1 Backup Architecture & Coverage Map (USB/NAS/Samba Ready)*
