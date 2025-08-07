# Backup System Module  
# Based on Agent 10's backup architecture work (corrected paths and NixOS integration)
{ config, lib, pkgs, ... }:

{
  # USB backup script with corrected paths for existing system
  systemd.services.backup-usb = {
    description = "USB backup service for NixOS homeserver";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };
    
    script = ''
      #\!/bin/bash
      set -euo pipefail
      
      # Backup configuration - corrected paths for current system
      BACKUP_SOURCE_PATHS=(
        "/etc/nixos/"                    # NixOS configuration
        "/etc/nixos/secrets/"            # SOPS secrets (not /etc/sops/)
        "/opt/business/"                 # Business data (not /srv/business/) 
        "/opt/sonarr/config/"            # Container configs
        "/opt/radarr/config/"
        "/opt/lidarr/config/"
        "/opt/prowlarr/config/"
        "/opt/jellyfin/config/"
        "/opt/frigate/config/"
        "/var/lib/postgresql/"           # Databases
      )
      
      MEDIA_PATHS=(
        "/mnt/media/surveillance/frigate/media/"  # Critical surveillance footage
      )
      
      LOG_FILE="/var/log/backup-usb.log"
      USB_MOUNT_POINT="/media/backup-usb"
      
      log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') [backup-usb] $*" | tee -a "$LOG_FILE"
      }
      
      # Function to find USB backup drive
      find_backup_usb() {
        # Look for USB drive with specific label
        local usb_device
        usb_device=$(lsblk -o NAME,LABEL,MOUNTPOINT | grep -i "BACKUP\|homeserver" | head -1 | awk '{print $1}')
        
        if [[ -n "$usb_device" ]]; then
          echo "/dev/$usb_device"
          return 0
        fi
        
        # Fallback: look for large USB drives
        lsblk -o NAME,SIZE,TRAN | grep usb | awk '$2 ~ /[0-9]+G/ && $2+0 >= 100 {print "/dev/" $1}' | head -1
      }
      
      # Function to mount USB drive
      mount_backup_drive() {
        local device="$1"
        
        log "Attempting to mount backup drive: $device"
        
        # Create mount point if it doesn't exist
        mkdir -p "$USB_MOUNT_POINT"
        
        # Mount the device
        if mount "$device" "$USB_MOUNT_POINT" 2>/dev/null; then
          log "Successfully mounted $device at $USB_MOUNT_POINT"
          return 0
        else
          log "ERROR: Failed to mount $device"
          return 1
        fi
      }
      
      # Function to perform backup
      perform_backup() {
        local backup_root="$USB_MOUNT_POINT/nixos-homeserver-backup"
        local backup_date
        backup_date=$(date '+%Y-%m-%d_%H-%M-%S')
        local current_backup="$backup_root/current"
        local dated_backup="$backup_root/backups/$backup_date"
        
        log "Starting backup to $current_backup"
        
        # Create backup directories
        mkdir -p "$current_backup"
        mkdir -p "$dated_backup"
        
        # Backup system configurations and container configs
        for path in "$${BACKUP_SOURCE_PATHS[@]}"; do
          if [[ -d "$path" ]]; then
            local target_name
            target_name=$(basename "$path")
            
            log "Backing up $path"
            
            # Use rsync for efficient incremental backup
            if rsync -aAXv --delete "$path" "$current_backup/$target_name/" 2>>"$LOG_FILE"; then
              log "✓ Successfully backed up $path"
            else
              log "✗ Failed to backup $path"
            fi
          else
            log "WARNING: Path does not exist: $path"
          fi
        done
        
        # Create snapshot of current backup
        log "Creating snapshot: $dated_backup"
        cp -al "$current_backup"/* "$dated_backup/" 2>/dev/null || true
        
        # Cleanup old backups (keep last 10)
        log "Cleaning up old backups"
        find "$backup_root/backups/" -mindepth 1 -maxdepth 1 -type d | sort | head -n -10 | xargs rm -rf 2>/dev/null || true
        
        # Create backup manifest
        {
          echo "# Backup Manifest"
          echo "Date: $(date)"
          echo "Host: $(hostname)"
          echo "Backup ID: $backup_date"
          echo ""
          echo "## Backup Contents"
          du -sh "$current_backup"/* | sort -hr
        } > "$current_backup/BACKUP_MANIFEST.txt"
        
        log "Backup manifest created"
      }
      
      # Function to backup critical media (selective)
      backup_critical_media() {
        local media_backup="$USB_MOUNT_POINT/nixos-homeserver-backup/media"
        
        mkdir -p "$media_backup"
        
        # Only backup recent critical surveillance footage (last 30 days)
        log "Backing up critical surveillance footage (last 30 days)"
        
        find "/mnt/media/surveillance/frigate/media/" -type f -mtime -30 -name "*.mp4" | head -1000 | while read -r file; do
          # Create relative directory structure
          local rel_path
          rel_path=$(realpath --relative-to="/mnt/media/surveillance/frigate/media/" "$file")
          local dest_dir
          dest_dir="$media_backup/surveillance/$(dirname "$rel_path")"
          
          mkdir -p "$dest_dir"
          
          if [[ \! -f "$media_backup/surveillance/$rel_path" ]]; then
            cp "$file" "$media_backup/surveillance/$rel_path" 2>/dev/null || true
          fi
        done
        
        log "Critical media backup completed"
      }
      
      # Main backup execution
      log "=== Starting USB Backup Process ==="
      
      # Find and mount USB backup drive
      USB_DEVICE=$(find_backup_usb)
      
      if [[ -z "$USB_DEVICE" ]]; then
        log "ERROR: No suitable backup USB drive found"
        exit 1
      fi
      
      log "Found backup device: $USB_DEVICE"
      
      if mount_backup_drive "$USB_DEVICE"; then
        # Check available space
        local available_space
        available_space=$(df "$USB_MOUNT_POINT" | awk 'NR==2 {print $4}')
        local available_gb
        available_gb=$((available_space / 1024 / 1024))
        
        log "Available space on backup drive: $available_gb GB"
        
        if [[ $available_gb -lt 10 ]]; then
          log "ERROR: Insufficient space on backup drive ($available_gb GB available)"
        else
          # Perform backups
          perform_backup
          backup_critical_media
          
          # Update backup metrics for monitoring
          if [[ -d "/var/lib/node-exporter-textfile" ]]; then
            {
              echo "# HELP backup_last_success_timestamp_seconds Timestamp of last successful backup"
              echo "# TYPE backup_last_success_timestamp_seconds gauge"
              echo "backup_last_success_timestamp_seconds $(date +%s)"
              
              echo "# HELP backup_size_bytes Size of last backup"
              echo "# TYPE backup_size_bytes gauge"
              echo "backup_size_bytes $(du -sb "$USB_MOUNT_POINT/nixos-homeserver-backup/current" | awk '{print $1}')"
            } > /var/lib/node-exporter-textfile/backup_status.prom.$$
            mv /var/lib/node-exporter-textfile/backup_status.prom.$$ /var/lib/node-exporter-textfile/backup_status.prom
          fi
          
          log "Backup completed successfully"
        fi
        
        # Unmount USB drive
        umount "$USB_MOUNT_POINT" 2>/dev/null || true
        log "USB drive unmounted"
      else
        log "ERROR: Failed to mount backup drive"
        exit 1
      fi
      
      log "=== USB Backup Process Completed ==="
    '';
    
    # Don't run automatically - only on demand or when USB is inserted
    # startAt = "weekly";  # Uncomment for automatic weekly backups
  };
  
  # Backup verification service
  systemd.services.backup-verify = {
    description = "Backup verification and integrity checking";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };
    
    script = ''
      #\!/bin/bash
      set -euo pipefail
      
      LOG_FILE="/var/log/backup-verify.log"
      USB_MOUNT_POINT="/media/backup-usb"
      
      log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') [backup-verify] $*" | tee -a "$LOG_FILE"
      }
      
      # Function to verify backup integrity
      verify_backup() {
        local backup_path="$1"
        
        log "Verifying backup at: $backup_path"
        
        # Check if backup manifest exists
        if [[ \! -f "$backup_path/BACKUP_MANIFEST.txt" ]]; then
          log "ERROR: Backup manifest not found"
          return 1
        fi
        
        # Verify critical directories exist
        local critical_dirs=("etc-nixos" "secrets" "business")
        local missing_dirs=0
        
        for dir in "$${critical_dirs[@]}"; do
          if [[ \! -d "$backup_path/$dir" ]]; then
            log "ERROR: Critical directory missing: $dir"
            ((missing_dirs++))
          else
            log "✓ Found critical directory: $dir"
          fi
        done
        
        if [[ $missing_dirs -gt 0 ]]; then
          log "ERROR: $missing_dirs critical directories missing"
          return 1
        fi
        
        # Test restore of a small file (NixOS configuration.nix)
        if [[ -f "$backup_path/etc-nixos/configuration.nix" ]]; then
          local test_restore="/tmp/backup-test-restore.nix"
          if cp "$backup_path/etc-nixos/configuration.nix" "$test_restore" 2>/dev/null; then
            # Verify file is readable and contains expected content
            if grep -q "system.stateVersion" "$test_restore" 2>/dev/null; then
              log "✓ Test restore successful"
              rm -f "$test_restore"
            else
              log "ERROR: Test restore file corrupted"
              return 1
            fi
          else
            log "ERROR: Test restore failed"
            return 1
          fi
        else
          log "ERROR: Critical file missing for restore test"
          return 1
        fi
        
        log "Backup verification completed successfully"
        return 0
      }
      
      log "=== Starting Backup Verification ==="
      
      # Find and mount USB backup drive
      USB_DEVICE=$(lsblk -o NAME,LABEL,MOUNTPOINT | grep -i "BACKUP\|homeserver" | head -1 | awk '{print "/dev/" $1}')
      
      if [[ -n "$USB_DEVICE" ]]; then
        mkdir -p "$USB_MOUNT_POINT"
        
        if mount "$USB_DEVICE" "$USB_MOUNT_POINT" 2>/dev/null; then
          log "Mounted backup drive: $USB_DEVICE"
          
          backup_root="$USB_MOUNT_POINT/nixos-homeserver-backup"
          
          if [[ -d "$backup_root/current" ]]; then
            if verify_backup "$backup_root/current"; then
              log "✅ Backup verification PASSED"
              
              # Update verification metrics
              if [[ -d "/var/lib/node-exporter-textfile" ]]; then
                {
                  echo "# HELP backup_verification_success Last backup verification result (1=success, 0=failure)"
                  echo "# TYPE backup_verification_success gauge"
                  echo "backup_verification_success 1"
                  
                  echo "# HELP backup_verification_timestamp_seconds Timestamp of last verification"
                  echo "# TYPE backup_verification_timestamp_seconds gauge"  
                  echo "backup_verification_timestamp_seconds $(date +%s)"
                } > /var/lib/node-exporter-textfile/backup_verification.prom.$$
                mv /var/lib/node-exporter-textfile/backup_verification.prom.$$ /var/lib/node-exporter-textfile/backup_verification.prom
              fi
            else
              log "❌ Backup verification FAILED"
            fi
          else
            log "ERROR: No current backup found at $backup_root"
          fi
          
          umount "$USB_MOUNT_POINT" 2>/dev/null || true
        else
          log "ERROR: Could not mount backup drive"
        fi
      else
        log "ERROR: No backup USB drive found"
      fi
      
      log "=== Backup Verification Completed ==="
    '';
  };
  
  # USB hotplug rule to trigger backup when backup drive is inserted
  services.udev.extraRules = ''
    # Trigger backup when USB drive with BACKUP label is inserted
    SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_LABEL}=="BACKUP", ENV{ID_FS_TYPE}=="ext4", RUN+="${pkgs.systemd}/bin/systemctl start backup-usb.service"
    SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_LABEL}=="homeserver-backup", ENV{ID_FS_TYPE}=="ext4", RUN+="${pkgs.systemd}/bin/systemctl start backup-usb.service"
  '';
  
  # Log rotation for backup logs
  services.logrotate.settings = {
    "/var/log/backup-usb.log" = {
      frequency = "weekly";
      rotate = 8;
      compress = true;
      missingok = true;
      notifempty = true;
      create = "644 root root";
    };
    "/var/log/backup-verify.log" = {
      frequency = "weekly";
      rotate = 4; 
      compress = true;
      missingok = true;
      notifempty = true;
      create = "644 root root";
    };
  };
}
EOF < /dev/null