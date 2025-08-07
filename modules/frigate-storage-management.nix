# Frigate Storage Management Module
# Based on Agent 2's surveillance optimization work (corrected for existing system)
{ config, lib, pkgs, ... }:

{
  # Frigate storage pruning service to maintain 2TB cap
  systemd.services.frigate-storage-prune = {
    description = "Frigate storage pruning - maintain 2TB cap";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };
    
    script = ''
      #\!/bin/bash
      set -euo pipefail
      
      # Existing frigate media paths from current system
      FRIGATE_MEDIA="/mnt/media/surveillance/frigate/media"
      FRIGATE_BUFFER="/mnt/hot/surveillance/buffer"
      TARGET_SIZE_GB=2000  # 2TB cap
      
      log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') [frigate-prune] $*" | tee -a /var/log/frigate-storage-prune.log
      }
      
      # Function to get directory size in GB
      get_size_gb() {
        local path="$1"
        if [[ -d "$path" ]]; then
          du -s "$path" | awk '{print int($1/1024/1024)}'
        else
          echo "0"
        fi
      }
      
      # Function to prune oldest files
      prune_oldest() {
        local path="$1"
        local target_size="$2"
        
        log "Starting prune in $path, target size: $target_size GB"
        
        current_size=$(get_size_gb "$path")
        log "Current size: $current_size GB"
        
        if [[ $current_size -le $target_size ]]; then
          log "Storage under limit ($current_size GB <= $target_size GB)"
          return 0
        fi
        
        # Find and delete oldest directories (organized by camera/date)
        local removed_count=0
        while [[ $(get_size_gb "$path") -gt $target_size ]]; do
          # Find oldest camera directory with recordings
          oldest_dir=$(find "$path" -type d -name "????-??-??" | head -1)
          
          if [[ -z "$oldest_dir" ]]; then
            log "No dated directories found for pruning"
            break
          fi
          
          local dir_size=$(get_size_gb "$oldest_dir")
          log "Removing oldest directory: $oldest_dir ($dir_size GB)"
          
          rm -rf "$oldest_dir"
          ((removed_count++))
          
          # Safety break - don't delete more than 50 directories at once
          if [[ $removed_count -gt 50 ]]; then
            log "Safety limit reached - removed $removed_count directories"
            break
          fi
        done
        
        log "Pruning completed. Removed $removed_count directories. New size: $(get_size_gb "$path") GB"
      }
      
      # Main execution
      log "=== Starting Frigate Storage Pruning ==="
      
      # Check if Frigate paths exist
      if [[ \! -d "$FRIGATE_MEDIA" ]]; then
        log "WARNING: Frigate media directory not found: $FRIGATE_MEDIA"
        exit 0
      fi
      
      # Prune media directory (main storage)
      prune_oldest "$FRIGATE_MEDIA" $TARGET_SIZE_GB
      
      # Clean buffer directory of files older than 7 days
      if [[ -d "$FRIGATE_BUFFER" ]]; then
        log "Cleaning buffer directory: $FRIGATE_BUFFER"
        find "$FRIGATE_BUFFER" -type f -mtime +7 -delete 2>/dev/null || true
      fi
      
      # Update Prometheus metrics if node-exporter textfile directory exists
      if [[ -d "/var/lib/node-exporter-textfile" ]]; then
        {
          echo "# HELP frigate_storage_size_bytes Current Frigate storage usage"
          echo "# TYPE frigate_storage_size_bytes gauge"
          echo "frigate_storage_size_bytes{path=\"$FRIGATE_MEDIA\"} $(( $(get_size_gb "$FRIGATE_MEDIA") * 1024 * 1024 * 1024 ))"
          
          echo "# HELP frigate_storage_prune_timestamp_seconds Timestamp of last successful prune"
          echo "# TYPE frigate_storage_prune_timestamp_seconds gauge"
          echo "frigate_storage_prune_timestamp_seconds $(date +%s)"
        } > /var/lib/node-exporter-textfile/frigate_storage.prom.$$
        mv /var/lib/node-exporter-textfile/frigate_storage.prom.$$ /var/lib/node-exporter-textfile/frigate_storage.prom
        log "Updated Prometheus metrics"
      fi
      
      log "=== Frigate Storage Pruning Completed ==="
    '';
    
    startAt = "hourly";  # Run every hour to maintain cap
  };
  
  # Frigate camera watchdog service for monitoring camera health
  systemd.services.frigate-camera-watchdog = {
    description = "Frigate camera health monitoring";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };
    
    script = ''
      #\!/bin/bash
      set -euo pipefail
      
      FRIGATE_API="http://localhost:5000/api"
      LOG_FILE="/var/log/frigate-watchdog.log"
      
      log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') [frigate-watchdog] $*" | tee -a "$LOG_FILE"
      }
      
      # Function to check camera status via Frigate API
      check_camera_status() {
        local camera_name="$1"
        
        # Get camera stats from Frigate API
        local camera_stats
        if camera_stats=$(curl -s "$FRIGATE_API/stats" 2>/dev/null); then
          # Check if camera is in the stats (indicates it's configured and being monitored)
          if echo "$camera_stats" | grep -q "\"$camera_name\""; then
            # Extract fps and detection info
            local fps
            fps=$(echo "$camera_stats" | jq -r ".cameras[\"$camera_name\"].camera_fps // 0" 2>/dev/null || echo "0")
            
            if [[ "$fps" == "0" || "$fps" == "null" ]]; then
              log "WARNING: Camera $camera_name has no FPS data (possibly offline)"
              return 1
            else
              log "Camera $camera_name: $fps FPS (healthy)"
              return 0
            fi
          else
            log "ERROR: Camera $camera_name not found in Frigate stats"
            return 1
          fi
        else
          log "ERROR: Could not connect to Frigate API at $FRIGATE_API"
          return 1
        fi
      }
      
      # Check all configured cameras (based on existing system)
      log "=== Starting Camera Health Check ==="
      
      CAMERAS=("cobra_cam_1" "cobra_cam_2" "cobra_cam_3" "cobra_cam_4")
      healthy_count=0
      total_cameras=$${#CAMERAS[@]}
      
      for camera in "$${CAMERAS[@]}"; do
        if check_camera_status "$camera"; then
          ((healthy_count++))
        fi
      done
      
      log "Camera health check completed: $healthy_count/$total_cameras cameras healthy"
      
      # Update Prometheus metrics
      if [[ -d "/var/lib/node-exporter-textfile" ]]; then
        {
          echo "# HELP frigate_cameras_healthy Number of healthy cameras"
          echo "# TYPE frigate_cameras_healthy gauge"
          echo "frigate_cameras_healthy $healthy_count"
          
          echo "# HELP frigate_cameras_total Total configured cameras"
          echo "# TYPE frigate_cameras_total gauge"
          echo "frigate_cameras_total $total_cameras"
          
          echo "# HELP frigate_watchdog_timestamp_seconds Timestamp of last watchdog check"
          echo "# TYPE frigate_watchdog_timestamp_seconds gauge"
          echo "frigate_watchdog_timestamp_seconds $(date +%s)"
        } > /var/lib/node-exporter-textfile/frigate_cameras.prom.$$
        mv /var/lib/node-exporter-textfile/frigate_cameras.prom.$$ /var/lib/node-exporter-textfile/frigate_cameras.prom
        log "Updated Prometheus metrics"
      fi
      
      # Alert if more than 1 camera is down
      unhealthy_count=$((total_cameras - healthy_count))
      if [[ $unhealthy_count -gt 1 ]]; then
        log "ALERT: $unhealthy_count cameras are unhealthy - manual intervention may be required"
        # In a full implementation, this would trigger notifications
      fi
      
      log "=== Camera Health Check Completed ==="
    '';
    
    startAt = "*:0/30";  # Run every 30 minutes
    
    # Add jq dependency for JSON parsing
    path = [ pkgs.curl pkgs.jq ];
  };
  
  # Log rotation for frigate management logs
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/frigate-storage-prune.log" = {
        frequency = "weekly";
        rotate = 4;
        compress = true;
        missingok = true;
        notifempty = true;
        create = "644 root root";
      };
      "/var/log/frigate-watchdog.log" = {
        frequency = "weekly"; 
        rotate = 4;
        compress = true;
        missingok = true;
        notifempty = true;
        create = "644 root root";
      };
    };
  };
}
EOF < /dev/null