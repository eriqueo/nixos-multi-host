
# Phase 2 — Automated Rsync & Offsite Backup Engine (USB/NAS/Cloud-Ready)

**Agent 10: Backup & Disaster Recovery Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

Automate, schedule, and verify backups to USB, NAS/DAS, and future cloud targets:
- NixOS-native systemd timers/services for recurring rsync
- Auto-mount/detect for USB backup drives
- Ready for expansion: add cloud or other local destinations at any time
- Operator and automation runbooks, error notifications, and logging

---

## Table of Contents

1. Automated Rsync Backup Scripts
2. NixOS Systemd Service/Timer Setup
3. USB Drive Automount & Backup Trigger
4. NAS Mounting & Scheduled Backups
5. Logging, Notification, and Audit Trails
6. Operator Runbook & Dry Run Testing
7. Preparation for Cloud/Offsite
8. References

---

## 1. Automated Rsync Backup Scripts

Place all backup scripts in `/mnt/scripts/` or similar, chmod +x.

### Example: `backup_to_usb.sh`

```bash
#!/usr/bin/env bash
# backup_to_usb.sh

USB_MOUNT="/mnt/usb-backup"
LOG="/var/log/backup_usb_$(date +%F).log"

# Wait for USB mount (or exit after 60s)
for i in {1..12}; do
  [ -d "$USB_MOUNT" ] && break
  sleep 5
done

[ -d "$USB_MOUNT" ] || { echo "USB backup drive not mounted!" | tee -a "$LOG"; exit 1; }

echo "Starting backup to $USB_MOUNT at $(date)" | tee -a "$LOG"
sudo rsync -aAXv --delete --exclude-from=/etc/nixos/backup_excludes.txt /etc/nixos/ "$USB_MOUNT/nixos-config/" | tee -a "$LOG"
sudo rsync -aAXv /mnt/media/ "$USB_MOUNT/media/" | tee -a "$LOG"
sudo rsync -aAXv /srv/business/receipts/ "$USB_MOUNT/receipts/" | tee -a "$LOG"
# Add more targets as needed
echo "Backup complete at $(date)" | tee -a "$LOG"
```

---

## 2. NixOS Systemd Service/Timer Setup

**`/etc/nixos/system/backup-usb.nix`:**

```nix
systemd.services.backup-to-usb = {
  description = "Automated USB Backup";
  script = "/mnt/scripts/backup_to_usb.sh";
  startAt = "daily";
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
};
systemd.timers.backup-to-usb = {
  wantedBy = [ "timers.target" ];
  timerConfig.OnCalendar = "daily";
  timerConfig.Persistent = true;
};
```

Repeat for NAS backups, just change script and paths.

---

## 3. USB Drive Automount & Backup Trigger

- Use `udisks2` or systemd automount for Linux-native auto-mounting at `/mnt/usb-backup`
- For plug-and-play:  
    - Write a `udev` rule to trigger backup script on mount
    - Or, prompt operator when USB is inserted

Sample `udev` rule (place in `/etc/udev/rules.d/99-backup.rules`):

```
ACTION=="mount", SUBSYSTEM=="block", KERNEL=="sd*", RUN+="/mnt/scripts/backup_to_usb.sh"
```

*Or use a desktop notifier to remind operator to start backup.*

---

## 4. NAS Mounting & Scheduled Backups

- Add NFS/SMB mount to `/etc/fstab` or use systemd.automount:

Example `/etc/fstab`:

```
nas-server:/volume1/backup /mnt/backup-nas nfs defaults 0 0
```

- Schedule with a second service/timer, e.g. `backup-to-nas.service`/`backup-to-nas.timer`

---

## 5. Logging, Notification, and Audit Trails

- All backup scripts log to `/var/log/backup_usb_*.log` and `/var/log/backup_nas_*.log`
- Failed runs trigger optional notification:
    - Email, webhook, or desktop alert

**Example notification via `mail`:**

```bash
if [ $? -ne 0 ]; then
  mail -s "Backup Failed" you@domain.com < "$LOG"
fi
```

---

## 6. Operator Runbook & Dry Run Testing

- **Dry-run:**
    ```bash
    sudo rsync -aAXvn --delete ... (add -n for dry run)
    ```
- **Manual run:**
    ```bash
    sudo /mnt/scripts/backup_to_usb.sh
    ```
- **Test restore by copying sample backup set to a temp location**

---

## 7. Preparation for Cloud/Offsite

- Use same scripting/service model, swap rsync for `rclone`, `restic`, or `borg`
- Store cloud credentials in SOPS/age-encrypted secrets, never in plain text

---

## 8. References

- [NixOS systemd manual](https://nixos.org/manual/nixos/stable/#sec-systemd-units)
- [udisks2 auto-mount](https://wiki.archlinux.org/title/Udisks)
- [rsync](https://download.samba.org/pub/rsync/rsync.html)
- [rclone](https://rclone.org/), [restic](https://restic.net/)

---

*End of Phase 2 Automated Rsync & Offsite Backup Engine (USB/NAS/Cloud-Ready)*
