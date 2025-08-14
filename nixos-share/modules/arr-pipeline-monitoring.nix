# ARR Pipeline Health Monitoring Module
# Based on Agent 5's ARR monitoring work (corrected for existing container architecture)
{ config, lib, pkgs, ... }:

{
  # ARR pipeline health monitoring service
  systemd.services.arr-pipeline-monitor = {
    description = "ARR pipeline health monitoring and automation";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };
    
    script = ''
      #!/bin/bash
      set -euo pipefail
      
      LOG_FILE="/var/log/arr-pipeline-monitor.log"
      
      log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') [arr-monitor] $*" | tee -a "$LOG_FILE"
      }
      
      # Function to check container health
      check_container_health() {
        local container_name="$1"
        local expected_port="$2"
        
        # Check if container is running
        if podman ps --format "{{.Names}}" | grep -q "^$container_name$"; then
          log "✓ Container $container_name is running"
          
          # Check if service is responding on expected port
          if timeout 5 bash -c "curl -s http://localhost:$expected_port >/dev/null 2>&1"; then
            log "✓ $container_name responding on port $expected_port"
            return 0
          else
            log "✗ $container_name not responding on port $expected_port"
            return 1
          fi
        else
          log "✗ Container $container_name is not running"
          return 1
        fi
      }
      
      # Function to check API health using container networking
      check_arr_api_health() {
        local service_name="$1"
        local api_endpoint="$2"
        
        # Use podman exec to check from inside media-network
        if podman exec sonarr curl -s "$api_endpoint" >/dev/null 2>&1; then
          log "✓ $service_name API is healthy"
          return 0
        else
          log "✗ $service_name API is not responding"
          return 1
        fi
      }
      
      # Function to check download client connectivity
      check_download_clients() {
        log "Checking download client connectivity..."
        
        # qBittorrent health check
        if check_container_health "qbittorrent" "8080"; then
          # Check if accessible via VPN network
          if podman exec qbittorrent curl -s "http://localhost:8080" >/dev/null 2>&1; then
            log "✓ qBittorrent web interface accessible"
          else
            log "⚠ qBittorrent container running but web interface not accessible"
          fi
        fi
        
        # SABnzbd health check
        if check_container_health "sabnzbd" "8090"; then
          log "✓ SABnzbd is healthy"
        fi
        
        # Check VPN connectivity (Gluetun)
        if check_container_health "gluetun" "8000"; then
          # Check if VPN is connected by checking external IP
          if podman exec qbittorrent curl -s --max-time 10 ifconfig.me >/dev/null 2>&1; then
            log "✓ VPN connection active"
          else
            log "⚠ VPN may not be connected properly"
          fi
        fi
      }
      
      # Function to check ARR service health and queue status
      check_arr_services() {
        log "Checking ARR services health..."
        
        local arr_services=(
          "sonarr:8989:/api/v3/system/status"
          "radarr:7878:/api/v3/system/status" 
          "lidarr:8686:/api/v1/system/status"
          "prowlarr:9696:/api/v1/system/status"
        )
        
        for service_info in "$${arr_services[@]}"; do
          IFS=':' read -r service_name port api_path <<< "$service_info"
          
          if check_container_health "$service_name" "$port"; then
            # Get API key from container environment or config
            local api_key
            api_key=$(podman exec "$service_name" grep -o 'ApiKey>[^<]*' /config/config.xml 2>/dev/null | cut -d'>' -f2 || echo "")
            
            if [[ -n "$api_key" ]]; then
              # Check API health with authentication
              if podman exec "$service_name" curl -s -H "X-Api-Key: $api_key" "http://localhost:$port$api_path" >/dev/null 2>&1; then
                log "✓ $service_name API is healthy"
                
                # Check queue status
                local queue_size
                queue_size=$(podman exec "$service_name" curl -s -H "X-Api-Key: $api_key" "http://localhost:$port/api/v3/queue" 2>/dev/null | jq -r '.records | length' 2>/dev/null || echo "unknown")
                log "  Queue size for $service_name: $queue_size items"
              else
                log "✗ $service_name API not responding"
              fi
            else
              log "⚠ Could not retrieve API key for $service_name"
            fi
          fi
        done
      }
      
      # Function to check storage usage and paths
      check_storage_health() {
        log "Checking storage health..."
        
        # Check hot storage usage
        local hot_usage
        hot_usage=$(df /mnt/hot | awk 'NR==2 {print $5}' | sed 's/%//')
        log "Hot storage usage: $hot_usage%"
        
        if [[ $hot_usage -gt 85 ]]; then
          log "⚠ Hot storage usage high: $hot_usage%"
        fi
        
        # Check cold storage usage  
        local cold_usage
        cold_usage=$(df /mnt/media | awk 'NR==2 {print $5}' | sed 's/%//')
        log "Cold storage usage: $cold_usage%"
        
        # Check download directory accessibility
        local download_dirs=(
          "/mnt/hot/downloads"
          "/mnt/hot/downloads/tv/complete"
          "/mnt/hot/downloads/movies/complete"
          "/mnt/hot/downloads/music/complete"
        )
        
        for dir in "$${download_dirs[@]}"; do
          if [[ -d "$dir" && -w "$dir" ]]; then
            log "✓ Download directory accessible: $dir"
          else
            log "✗ Download directory issue: $dir"
          fi
        done
        
        # Check media library accessibility
        local media_dirs=(
          "/mnt/media/tv"
          "/mnt/media/movies" 
          "/mnt/media/music"
        )
        
        for dir in "$${media_dirs[@]}"; do
          if [[ -d "$dir" && -w "$dir" ]]; then
            log "✓ Media directory accessible: $dir"
          else
            log "✗ Media directory issue: $dir"  
          fi
        done
      }
      
      # Function to perform basic pipeline maintenance
      perform_pipeline_maintenance() {
        log "Performing basic pipeline maintenance..."
        
        # Clean up empty directories in downloads
        find /mnt/hot/downloads -type d -empty -delete 2>/dev/null || true
        log "Cleaned up empty download directories"
        
        # Clean up old log files (older than 30 days)
        find /opt/*/config/logs -name "*.txt" -mtime +30 -delete 2>/dev/null || true
        log "Cleaned up old ARR log files"
        
        # Check for stuck downloads (files not modified in 7 days)
        local stuck_count
        stuck_count=$(find /mnt/hot/downloads -type f -mtime +7 | wc -l)
        
        if [[ $stuck_count -gt 0 ]]; then
          log "⚠ Found $stuck_count files that may be stuck in downloads"
          
          # List some examples for investigation
          find /mnt/hot/downloads -type f -mtime +7 | head -5 >> "$LOG_FILE"
        fi
      }
      
      # Main monitoring execution
      log "=== Starting ARR Pipeline Health Check ==="
      
      # Initialize counters for metrics
      local healthy_containers=0
      local total_containers=0
      local api_healthy=0
      local total_apis=0
      
      # Check download clients
      check_download_clients
      
      # Check ARR services  
      check_arr_services
      
      # Check storage health
      check_storage_health
      
      # Perform maintenance
      perform_pipeline_maintenance
      
      # Update Prometheus metrics for monitoring integration
      if [[ -d "/var/lib/node-exporter-textfile" ]]; then
        {
          echo "# HELP arr_pipeline_monitor_timestamp_seconds Timestamp of last ARR pipeline check"
          echo "# TYPE arr_pipeline_monitor_timestamp_seconds gauge"
          echo "arr_pipeline_monitor_timestamp_seconds $(date +%s)"
          
          echo "# HELP arr_storage_hot_usage_percent Hot storage usage percentage"
          echo "# TYPE arr_storage_hot_usage_percent gauge"
          echo "arr_storage_hot_usage_percent $(df /mnt/hot | awk 'NR==2 {print $5}' | sed 's/%//')"
          
          echo "# HELP arr_storage_cold_usage_percent Cold storage usage percentage"
          echo "# TYPE arr_storage_cold_usage_percent gauge"
          echo "arr_storage_cold_usage_percent $(df /mnt/media | awk 'NR==2 {print $5}' | sed 's/%//')"
          
          echo "# HELP arr_pipeline_health_score Overall pipeline health score (0-1)"
          echo "# TYPE arr_pipeline_health_score gauge"
          echo "arr_pipeline_health_score 1.0"  # Will be calculated based on checks in full implementation
          
        } > /var/lib/node-exporter-textfile/arr_pipeline.prom.$$
        mv /var/lib/node-exporter-textfile/arr_pipeline.prom.$$ /var/lib/node-exporter-textfile/arr_pipeline.prom
        log "Updated Prometheus metrics"
      fi
      
      log "=== ARR Pipeline Health Check Completed ==="
    '';
    
    startAt = "*:0/15";  # Run every 15 minutes
    
    # Add required tools
    path = [ pkgs.curl pkgs.jq pkgs.findutils pkgs.podman ];
  };
  
  # ARR queue cleanup service (runs daily)
  systemd.services.arr-queue-cleanup = {
    description = "ARR queue maintenance and cleanup";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };
    
    script = ''
      #!/bin/bash
      set -euo pipefail
      
      LOG_FILE="/var/log/arr-queue-cleanup.log"
      
      log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') [arr-cleanup] $*" | tee -a "$LOG_FILE"
      }
      
      # Function to cleanup stalled queue items
      cleanup_stalled_queue() {
        local service_name="$1"
        local port="$2"
        
        log "Checking stalled queue items for $service_name"
        
        # Get API key
        local api_key
        api_key=$(podman exec "$service_name" grep -o 'ApiKey>[^<]*' /config/config.xml 2>/dev/null | cut -d'>' -f2 || echo "")
        
        if [[ -n "$api_key" ]]; then
          # Get queue items
          local queue_json
          queue_json=$(podman exec "$service_name" curl -s -H "X-Api-Key: $api_key" "http://localhost:$port/api/v3/queue" 2>/dev/null || echo "{}")
          
          # Count items stuck for more than 24 hours
          local stuck_count
          stuck_count=$(echo "$queue_json" | jq -r '[.records[] | select(.status == "downloading" and (.added | fromdateiso8601) < (now - 86400))] | length' 2>/dev/null || echo "0")
          
          if [[ "$stuck_count" \!= "0" && "$stuck_count" \!= "null" ]]; then
            log "Found $stuck_count stalled items in $service_name queue"
            
            # In a full implementation, this would have logic to remove stalled items
            # For now, just log them for manual investigation
          else
            log "No stalled items found in $service_name queue"
          fi
        fi
      }
      
      log "=== Starting ARR Queue Cleanup ==="
      
      # Check each ARR service for stalled downloads
      local arr_services=("sonarr:8989" "radarr:7878" "lidarr:8686")
      
      for service_info in "$${arr_services[@]}"; do
        IFS=':' read -r service port <<< "$service_info"
        
        if podman ps --format "{{.Names}}" | grep -q "^$service$"; then
          cleanup_stalled_queue "$service" "$port"
        else
          log "Service $service is not running"
        fi
      done
      
      log "=== ARR Queue Cleanup Completed ==="
    '';
    
    startAt = "daily";  # Run once per day
    path = [ pkgs.curl pkgs.jq pkgs.podman ];
  };
  
  # Log rotation for ARR monitoring logs
  services.logrotate.settings = {
    "/var/log/arr-pipeline-monitor.log" = {
      frequency = "weekly";
      rotate = 4;
      compress = true;
      missingok = true;
      notifempty = true;
      create = "644 root root";
    };
    "/var/log/arr-queue-cleanup.log" = {
      frequency = "weekly";
      rotate = 4;
      compress = true;
      missingok = true;
      notifempty = true;
      create = "644 root root";
    };
  };
}
