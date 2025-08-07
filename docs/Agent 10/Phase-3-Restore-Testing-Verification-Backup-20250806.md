
# Phase 3 — Restore Testing & Verification

**Agent 10: Backup & Disaster Recovery Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

This phase ensures your backups are **provably restorable**—not just theoretically present.  
- Scheduled and on-demand restore tests (USB, NAS, and future cloud)
- Checksums and integrity validation for NixOS configs, media, business data, and secrets
- Logging/audit for every restore operation
- Operator runbook for both partial and full restores

---

## Table of Contents

1. Scheduled and On-Demand Restore Tests
2. Checksum Verification (Pre/Post Restore)
3. Restore Testing Script Examples
4. Logging and Audit Trails
5. Operator Runbook (Restore, Test, and Sign-Off)
6. Alerting for Restore Failures
7. References

---

## 1. Scheduled and On-Demand Restore Tests

- **Full restore test**:  
  - At least quarterly: Restore full NixOS config, sample media, and critical business/secret data to a *test location* (not overwriting production)
- **Partial restore**:  
  - After each backup, restore a random sample file or directory and check content/ownership/perms

**Example test directories:**
- `/mnt/usb-backup-test/`
- `/mnt/backup-nas-test/`
- `/mnt/restore-sandbox/`

---

## 2. Checksum Verification (Pre/Post Restore)

- Generate file checksums before and after restore:
    ```bash
    find /etc/nixos/ -type f -exec sha256sum {} \; | sort > /tmp/nixos-config.chk
    # After restore:
    find /mnt/restore-sandbox/nixos-config/ -type f -exec sha256sum {} \; | sort > /tmp/nixos-config-restore.chk
    diff /tmp/nixos-config.chk /tmp/nixos-config-restore.chk
    ```
- For large media: verify only files over 1GB (spot check or full scan)
- For databases: use built-in pg_dump/restore with checksum, or script a sample restore and check queries

---

## 3. Restore Testing Script Examples

### Example: NixOS Config Restore Test

```bash
#!/usr/bin/env bash
# test_restore_nixos_config.sh

SRC="/mnt/usb-backup/nixos-config/"
DEST="/mnt/restore-sandbox/nixos-config/"
mkdir -p "$DEST"
rsync -aAXv "$SRC" "$DEST"
find "$SRC" -type f -exec sha256sum {} \; | sort > /tmp/nixos-config.src.chk
find "$DEST" -type f -exec sha256sum {} \; | sort > /tmp/nixos-config.dest.chk
if diff /tmp/nixos-config.src.chk /tmp/nixos-config.dest.chk; then
  echo "Restore test PASSED: hashes match"
else
  echo "Restore test FAILED: files differ"
fi
```

### Example: Media Restore Test

```bash
rsync -aAXv /mnt/usb-backup/media/movies/Movie.Title.2022/ /mnt/restore-sandbox/media/movies/Movie.Title.2022/
diff <(ls -l /mnt/usb-backup/media/movies/Movie.Title.2022/) <(ls -l /mnt/restore-sandbox/media/movies/Movie.Title.2022/)
```

---

## 4. Logging and Audit Trails

- Every restore test logs to `/var/log/restore_test_$(date +%F).log`
- Include:
    - Timestamp
    - Source/destination
    - Files checked/restored
    - Result (PASS/FAIL) and diffs

---

## 5. Operator Runbook (Restore, Test, and Sign-Off)

1. **Choose restore source**: USB, NAS, or cloud backup.
2. **Select restore target:**  
   - For tests, use `/mnt/restore-sandbox/` or another non-production location.
   - For live restores, ensure a backup of current state exists!
3. **Run restore test script** (examples above).
4. **Verify logs and/or checksums.**
5. **If test fails:**  
   - Investigate and attempt restore from alternate backup if possible.
   - Document outcome and remediate cause.
6. **Record test outcome in `/etc/nixos/docs/backup/restore-tests.md`.**

---

## 6. Alerting for Restore Failures

- If any restore or checksum verification fails:
    - Send email, webhook, or desktop notification to operator/admin
    - Mark as “REQUIRES ATTENTION” in `/etc/nixos/docs/backup/restore-tests.md`

Example mail alert in script:
```bash
if [ "$RESULT" = "FAILED" ]; then
  mail -s "Restore Test Failed" you@domain.com < "$LOG"
fi
```

---

## 7. References

- [NixOS backup/restore manual](https://nixos.org/manual/nixos/stable/#sec-backups)
- [rsync](https://download.samba.org/pub/rsync/rsync.html)
- [sha256sum](https://man7.org/linux/man-pages/man1/sha256sum.1.html)
- [systemd timers](https://nixos.org/manual/nixos/stable/#sec-timers)

---

*End of Phase 3 Restore Testing & Verification*
