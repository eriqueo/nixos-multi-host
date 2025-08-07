
# Phase 3 — ARR Library Hygiene & Cold Storage Migration

**Agent 5: ARR Pipeline Automation & File Normalization Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

This phase provides a robust, testable automation for:
- **Moving normalized media** (movies, TV, music, Soulseek/SLSKD) from hot storage to cold storage
- Ensuring files are fully normalized and *arr-compatible before migration
- Verifying ARR import success before cleanup
- Avoiding double/multiple folder nesting and bad names
- Including test, dry-run, and rollback for safety

---

## Table of Contents

1. Migration Principles & Policy
2. Migration Script (Movies, TV, Music, Soulseek)
3. ARR Import Verification Step
4. NixOS Systemd Integration
5. Testing, Dry Run, and Rollback
6. References

---

## 1. Migration Principles & Policy

- **Move only from /mnt/hot/normalized → /mnt/media** (never from downloads directly)
- **File/folder must match ARR import patterns before migration**
- **Confirm ARR (Sonarr/Radarr/Lidarr) has imported the file (API or post-import scan)**
- **No double/triple folder nesting allowed in cold storage**
- **Do not overwrite newer files in cold storage**
- **All moves are logged for audit/recovery**

---

## 2. Migration Script (Movies, TV, Music, Soulseek)

```bash
#!/usr/bin/env bash
# migrate_to_cold_storage.sh

SRC="/mnt/hot/normalized"
DST="/mnt/media"
LOG="/mnt/hot/audit/migrate-$(date +%F-%H%M).log"

move_and_log() {
  FROM="$1"
  TO="$2"
  if [ -f "$FROM" ]; then
    if [ ! -f "$TO" ]; then
      mkdir -p "$(dirname "$TO")"
      mv -vn "$FROM" "$TO" && echo "Moved: $FROM -> $TO" >> "$LOG"
    else
      echo "Skipped (already exists): $TO" >> "$LOG"
    fi
  fi
}

# Movies
find "$SRC/movies" -type f | while read -r FILE; do
  OUT="${DST}/movies/$(basename "$(dirname "$FILE")")/$(basename "$FILE")"
  move_and_log "$FILE" "$OUT"
done

# TV
find "$SRC/tv" -type f | while read -r FILE; do
  SHOW="$(basename "$(dirname "$(dirname "$FILE")")")"
  SEASON="$(basename "$(dirname "$FILE")")"
  OUT="${DST}/tv/${SHOW}/${SEASON}/$(basename "$FILE")"
  move_and_log "$FILE" "$OUT"
done

# Music (Soulseek)
find "$SRC/music" -type f | while read -r FILE; do
  ARTIST="$(basename "$(dirname "$(dirname "$FILE")")")"
  ALBUM="$(basename "$(dirname "$FILE")")"
  OUT="${DST}/music/${ARTIST}/${ALBUM}/$(basename "$FILE")"
  move_and_log "$FILE" "$OUT"
done

# Unsorted (manual review)
if [ -d "$SRC/unsorted" ]; then
  mv -vn "$SRC/unsorted" "$DST/unsorted-$(date +%F-%H%M)" >> "$LOG"
fi
```

---

## 3. ARR Import Verification Step

**Best practice:**  
- Use ARR API or CLI to force a rescan/import after migration, e.g.:
    - Sonarr: `/api/command` with `type: 'RescanSeries'`
    - Radarr: `/api/command` with `type: 'RescanMovie'`
    - Lidarr: `/api/command` with `type: 'RescanArtist'`
- Only delete from hot storage after verifying ARR import success (check logs or API status).

---

## 4. NixOS Systemd Integration

```nix
systemd.services.media-migrate-to-cold = {
  description = "Move normalized media to cold storage after ARR verification";
  startAt = "daily";
  script = "/mnt/scripts/migrate_to_cold_storage.sh";
};
```

---

## 5. Testing, Dry Run, and Rollback

- **Dry run:**  
  - Comment out `mv` commands, add `echo "Would move $FROM -> $TO"` for testing
  - Review `$LOG` after test

- **Rollback:**  
  - All moves are logged with full path
  - Use log to restore moved files (move from cold storage back to staging/hot if needed)
  - Do not delete from hot until migration + import is verified

- **Manual review:**  
  - Check `/mnt/media/unsorted-*` for files needing manual naming/folder adjustment

---

## 6. References

- [Sonarr API](https://wiki.servarr.com/sonarr/api)
- [Radarr API](https://wiki.servarr.com/radarr/api)
- [Lidarr API](https://wiki.servarr.com/lidarr/api)
- [NixOS systemd scripting](https://nixos.org/manual/nixos/stable/#sec-systemd-units)

---

*End of Phase 3 ARR Library Hygiene & Cold Storage Migration*
