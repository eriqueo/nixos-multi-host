# hosts/server/modules/hot-storage.nix
{ config, pkgs, ... }:

{
  # SSD Mount Configuration
  fileSystems."/mnt/hot" = {
    device = "/dev/disk/by-label/hot";
    fsType = "ext4";
    options = [ 
      "defaults"
      "noatime"              # Performance optimization for SSD
      "user_xattr"           # Extended attributes support
      "acl"                  # Access control lists
    ];
  };

  # Hot Storage Directory Structure
  # Following the established "Safety-First" design from the handoff guide
  systemd.tmpfiles.rules = [
    # Root hot storage directory
    "d /mnt/hot 0755 eric users -"
    
    # DOWNLOAD STAGING AREA (hot processing)
    "d /mnt/hot/downloads 0755 eric users -"
    "d /mnt/hot/downloads/torrents 0755 eric users -"
    "d /mnt/hot/downloads/torrents/music 0755 eric users -"
    "d /mnt/hot/downloads/torrents/movies 0755 eric users -"
    "d /mnt/hot/downloads/torrents/tv 0755 eric users -"
    "d /mnt/hot/downloads/usenet 0755 eric users -"
    "d /mnt/hot/downloads/usenet/music 0755 eric users -"
    "d /mnt/hot/downloads/usenet/movies 0755 eric users -"
    "d /mnt/hot/downloads/usenet/tv 0755 eric users -"
    "d /mnt/hot/downloads/usenet/software 0755 eric users -"
    "d /mnt/hot/downloads/soulseek 0755 eric users -"
    
    # SAFE PROCESSING ZONES (moved to SSD for faster processing)
    "d /mnt/hot/manual 0755 eric users -"
    "d /mnt/hot/manual/music 0755 eric users -"
    "d /mnt/hot/manual/movies 0755 eric users -"
    "d /mnt/hot/manual/tv 0755 eric users -"
    "d /mnt/hot/quarantine 0755 eric users -"
    "d /mnt/hot/quarantine/music 0755 eric users -"
    "d /mnt/hot/quarantine/movies 0755 eric users -"
    "d /mnt/hot/quarantine/tv 0755 eric users -"
    
    # *ARR WORKING DIRECTORIES (temp processing on SSD)
    "d /mnt/hot/processing 0755 eric users -"
    "d /mnt/hot/processing/lidarr-temp 0755 eric users -"
    "d /mnt/hot/processing/sonarr-temp 0755 eric users -"
    "d /mnt/hot/processing/radarr-temp 0755 eric users -"
    
    # DATABASE STORAGE (when they grow beyond tiny)
    "d /mnt/hot/databases 0755 eric users -"
    "d /mnt/hot/databases/postgresql 0755 eric users -"
    "d /mnt/hot/databases/arr-databases 0755 eric users -"
    
    # AI MODEL STORAGE (for faster Ollama loading)
    "d /mnt/hot/ai 0755 eric users -"
    "d /mnt/hot/ai/models 0755 eric users -"
    "d /mnt/hot/ai/cache 0755 eric users -"
    
    # CONTAINER CACHE & TEMP FILES
    "d /mnt/hot/cache 0755 eric users -"
    "d /mnt/hot/cache/frigate 0755 eric users -"
    "d /mnt/hot/cache/jellyfin 0755 eric users -"
    "d /mnt/hot/cache/immich 0755 eric users -"
    
    # SURVEILLANCE BUFFER (for immediate recordings before archival)
    "d /mnt/hot/surveillance 0755 eric users -"
    "d /mnt/hot/surveillance/buffer 0755 eric users -"

    # Create log file for SSD health monitoring (ADD THIS LINE to the existing rules)
    "f /var/log/ssd-health.log 0644 root root -"
  ];

  # Performance optimizations for SSD
  services.fstrim.enable = true;  # Enable automatic TRIM for SSD health
  
  # SSD monitoring and health check
  systemd.services.ssd-health-check = {
    description = "SSD health monitoring";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "ssd-health-check" ''
        #!/bin/bash
        
        # Get SSD device path
        SSD_DEVICE=$(findmnt -n -o SOURCE /mnt/hot | head -1)
        
        if [[ -n "$SSD_DEVICE" ]]; then
          echo "$(date): SSD Health Check for $SSD_DEVICE" >> /var/log/ssd-health.log
          
          # Check SMART status
          ${pkgs.smartmontools}/bin/smartctl -H "$SSD_DEVICE" >> /var/log/ssd-health.log 2>&1
          
          # Log wear leveling info
          ${pkgs.smartmontools}/bin/smartctl -A "$SSD_DEVICE" | grep -E "(Wear_Leveling_Count|Total_LBAs_Written|Power_On_Hours)" >> /var/log/ssd-health.log 2>&1
          
          # Check disk usage
          echo "Disk usage:" >> /var/log/ssd-health.log
          df -h /mnt/hot >> /var/log/ssd-health.log
          
          echo "---" >> /var/log/ssd-health.log
        fi
      '';
    };
  };
  
  # Schedule weekly SSD health checks
  systemd.timers.ssd-health-check = {
    description = "Weekly SSD health check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };


  # SSD usage monitoring script
  environment.systemPackages = with pkgs; [
    smartmontools              # SSD health monitoring
    iotop                      # I/O monitoring
    (writeScriptBin "hot-storage-status" ''
      #!/bin/bash
      echo "🔥 Hot Storage Status"
      echo "===================="
      echo
      echo "📊 Disk Usage:"
      df -h /mnt/hot
      echo
      echo "📁 Directory Sizes:"
      du -sh /mnt/hot/downloads /mnt/hot/manual /mnt/hot/processing /mnt/hot/cache 2>/dev/null || echo "Some directories not yet created"
      echo
      echo "💾 SSD Health:"
      SSD_DEVICE=$(findmnt -n -o SOURCE /mnt/hot | head -1)
      if [[ -n "$SSD_DEVICE" ]]; then
        smartctl -H "$SSD_DEVICE" | grep -E "(overall-health|result)"
      fi
    '')
  ];

  # Backup script for hot storage critical data
  systemd.services.hot-storage-backup = {
    description = "Backup critical hot storage data";
    serviceConfig = {
      Type = "oneshot";
      User = "eric";
      ExecStart = pkgs.writeShellScript "hot-storage-backup" ''
        #!/bin/bash
        
        BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
        BACKUP_DIR="/mnt/media/backups/hot-storage"
        
        mkdir -p "$BACKUP_DIR"
        
        # Backup manual processing queues (critical data that needs preservation)
        if [[ -d "/mnt/hot/manual" ]]; then
          echo "Backing up manual processing queue..."
          rsync -av --progress /mnt/hot/manual/ "$BACKUP_DIR/manual_$BACKUP_DATE/"
        fi
        
        # Backup quarantine (corrupted files for potential recovery)
        if [[ -d "/mnt/hot/quarantine" ]]; then
          echo "Backing up quarantine..."
          rsync -av --progress /mnt/hot/quarantine/ "$BACKUP_DIR/quarantine_$BACKUP_DATE/"
        fi
        
        # Clean up old backups (keep last 7 days)
        find "$BACKUP_DIR" -type d -name "*_*" -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
        
        echo "Hot storage backup completed: $BACKUP_DIR"
      '';
    };
  };
  
  # Schedule daily backups of critical hot storage data
  systemd.timers.hot-storage-backup = {
    description = "Daily hot storage backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
