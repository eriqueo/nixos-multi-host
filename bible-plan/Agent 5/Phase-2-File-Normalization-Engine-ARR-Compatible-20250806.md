
# Phase 2 — File Normalization Engine (ARR-Compatible, Soulseek-Ready)

**Agent 5: ARR Pipeline Automation & File Normalization Specialist**  
**Date:** 2025-08-06

---

## Executive Summary

This phase delivers a robust, testable, and NixOS-native system to guarantee **all media files**—movies, TV, music, Soulseek downloads—are:
- Properly named for *arr (Sonarr, Radarr, Lidarr) auto-import
- Free of scene/junk suffixes, nested folder mess, and illegal filesystem characters
- Migrated only when normalized

---

## Table of Contents

1. Normalization Principles & Requirements
2. Target Naming Patterns for ARR
3. Script & Systemd Integration (NixOS)
4. Edge Case Handling (Soulseek, Scene, Multi-Folder)
5. Testing, Dry Run, and Rollback
6. References

---

## Normalization Principles & Requirements

**All files/folders should:**
- Match Sonarr/Radarr/Lidarr import rules **before** cold storage migration
- Have no double/triple nesting (i.e. `/movies/Movie.Title.2023/Movie.Title.2023/`)
- Replace spaces with dots or underscores only if *arr expects it
- Strip common “Scene” junk: `[GROUP]`, `- 1080p`, `.BluRay.x264-GROUP`, etc.
- Remove special characters: `[ ] ( ) ' " : ; , ? ! { } $ # @`
- Insert year if present in source filename (vital for movie/TV matching)
- For music, handle `{Artist} - {Album} - {Track}.ext` patterns from Soulseek

---

## Target Naming Patterns for ARR

- **Movies:**  
  `{Movie.Title} ({Year})/{Movie.Title} ({Year}).ext`
- **TV:**  
  `{Series.Title} ({Year})/Season {season:02}/{Series.Title} - S{season:02}E{episode:02} - {Episode.Title}.ext`
- **Music:**  
  `{Artist}/{Album} ({Year})/{track:02} - {Track.Title}.ext`

---

## Script & Systemd Integration (NixOS)

### Bash Example for Movies, TV, and Soulseek/Music

```bash
#!/usr/bin/env bash
# normalize_media.sh

SRC="/mnt/hot/downloads"
DST="/mnt/hot/normalized"

find "$SRC" -type f | while read -r F; do
  NAME=$(basename "$F")
  EXT="${NAME##*.}"

  # Remove scene/release group patterns, junk chars
  CLEAN=$(echo "$NAME" | sed -E 's/(\[.*\]|- ?(1080|720)p|\.BluRay.*|\.x264.*|\.h264.*|\.AAC.*|WEBRip.*)//g' | tr -d '[]()"':;,@#$!{}')

  # Normalize spaces and dots
  CLEAN=$(echo "$CLEAN" | tr ' ' '.' | sed 's/\.\.+/./g')

  # Movie: try to extract title/year
  if [[ "$CLEAN" =~ ^(.*)\.([12][0-9]{3}) ]]; then
    TITLE="${BASH_REMATCH[1]}"
    YEAR="${BASH_REMATCH[2]}"
    OUTNAME="${TITLE//./ } (${YEAR}).${EXT}"
    OUTDIR="$DST/movies/${TITLE//./ } (${YEAR})"
    mkdir -p "$OUTDIR"
    mv -vn "$F" "$OUTDIR/$OUTNAME"
    continue
  fi

  # TV: SXXEXX pattern
  if [[ "$CLEAN" =~ (S[0-9]{2}E[0-9]{2}) ]]; then
    SHOWDIR="$(echo "$CLEAN" | cut -d'.' -f1 | tr '.' ' ')"
    SEASON=$(echo "$CLEAN" | grep -o 'S[0-9]\{2\}')
    OUTDIR="$DST/tv/${SHOWDIR}/Season ${SEASON:1:2}"
    mkdir -p "$OUTDIR"
    mv -vn "$F" "$OUTDIR/$CLEAN"
    continue
  fi

  # Soulseek/Music: Try to parse "Artist - Album - Track"
  if [[ "$CLEAN" =~ ^(.+)\ -\ (.+)\ -\ ([0-9]{2,})\ -\ (.*)\.${EXT}$ ]]; then
    ARTIST="${BASH_REMATCH[1]}"
    ALBUM="${BASH_REMATCH[2]}"
    TRACKNUM="${BASH_REMATCH[3]}"
    TRACKTITLE="${BASH_REMATCH[4]}"
    OUTDIR="$DST/music/${ARTIST}/${ALBUM}"
    mkdir -p "$OUTDIR"
    mv -vn "$F" "$OUTDIR/${TRACKNUM} - ${TRACKTITLE}.${EXT}"
    continue
  fi

  # Fallback: dump to /unsorted
  mkdir -p "$DST/unsorted"
  mv -vn "$F" "$DST/unsorted/$CLEAN"
done
```

### NixOS systemd Service

```nix
systemd.services.media-normalizer = {
  description = "Normalize media filenames/folders for ARR import";
  startAt = "hourly";
  script = "/mnt/scripts/normalize_media.sh";
};
```

---

## Edge Case Handling (Soulseek, Scene, Multi-Folder)

- **Soulseek:**  
  - Typically deeply nested or “all in one” downloads  
  - Flatten and reconstruct to ARR-expected pattern using script above
- **Double/Triple Folder Nesting:**  
  - Use `find ... -type d` to collapse redundant parent/child folders
- **Character Issues:**  
  - Always tr/replace or strip: `\`, `/`, `:`, `*`, `?`, `"`, `<`, `>`, `|`, `{}`, `[ ]`, `'`, `;`, `,`, `!`, `@`, `#`, `$`, `%`, `^`, `&`, `=`, `+`

---

## Testing, Dry Run, and Rollback

- **Dry-run/test mode:**  
  - Use `mv -vn` (verbose, no clobber)
  - For testing:  
    ```bash
    bash normalize_media.sh | tee normalization-dryrun.log
    ```
- **Rollback:**  
  - Always work in a staging/output folder (`/mnt/hot/normalized`)  
  - Only move to cold storage after validation and *arr import success

---

## References

- [Sonarr naming requirements](https://wiki.servarr.com/sonarr/settings#media-management)
- [Radarr folder/filename patterns](https://wiki.servarr.com/radarr/settings#media-management)
- [Lidarr import FAQ](https://wiki.servarr.com/lidarr/faq)
- [Scene naming conventions](https://scenerules.org/)
- [Soularr/SLSKD](https://github.com/advplyr/soularr)
- [NixOS systemd scripting](https://nixos.org/manual/nixos/stable/#sec-systemd-units)

---

*End of Phase 2 File Normalization Engine (ARR-Compatible, Soulseek-Ready)*
