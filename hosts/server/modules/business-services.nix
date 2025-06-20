{ config, pkgs, ... }:

{
  # Business-specific packages
  environment.systemPackages = with pkgs; [
    # OCR and document processing
    tesseract
    imagemagick
    poppler_utils  # PDF processing
    
    # Python packages for business automation
    python3Packages.fastapi
    python3Packages.sqlalchemy
    python3Packages.psycopg2
    python3Packages.pandas
    python3Packages.streamlit
    python3Packages.python-multipart  # For file uploads
    python3Packages.pillow  # Image processing
    python3Packages.opencv4  # Advanced image processing
    python3Packages.pytesseract
    # python3Packages.spacy  # Temporarily disabled due to wandb build issues
    python3Packages.httpx  # For API requests
    python3Packages.asyncpg
    python3Packages.redis
    
    # Additional utilities
    curl
    jq
    postgresql  # Client tools
  ];
  
  # PostgreSQL database service for business data
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    
    # Create business database and user
    initialScript = pkgs.writeText "postgres-init.sql" ''
      CREATE DATABASE heartwood_business;
      CREATE USER business_user WITH PASSWORD 'secure_password_change_me';
      GRANT ALL PRIVILEGES ON DATABASE heartwood_business TO business_user;
      
      -- Connect to the business database
      \c heartwood_business;
      
      -- Enable UUID extension
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    '';
    
    # Basic PostgreSQL optimizations
    settings = {
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
    };
  };
  
  # Redis for caching and sessions
  services.redis.servers.business = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
     };
  
  # Create business directories
  systemd.tmpfiles.rules = [
    "d /opt/business 0755 eric users -"
    "d /opt/business/api 0755 eric users -"
    "d /opt/business/dashboard 0755 eric users -"
    "d /opt/business/uploads 0755 eric users -"
    "d /opt/business/receipts 0755 eric users -"
    "d /opt/business/processed 0755 eric users -"
    "d /opt/business/backups 0755 eric users -"
  ];
  
  # Backup script for business data
  systemd.services.business-backup = {
    description = "Daily backup of business database";
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = pkgs.writeShellScript "business-backup" ''
        DATE=$(date +%Y%m%d_%H%M%S)
        ${pkgs.postgresql}/bin/pg_dump \
          -U business_user \
          -h localhost \
          heartwood_business \
          | gzip > /opt/business/backups/heartwood_business_$DATE.sql.gz
        
        # Keep only last 30 days of backups
        find /opt/business/backups -name "heartwood_business_*.sql.gz" -mtime +30 -delete
      '';
    };
  };
  
  # Schedule daily backups
  systemd.timers.business-backup = {
    description = "Daily business database backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  
  # Firewall rules for business services (only on internal network)
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 8000 8501 5432 6379 ];
  };
}
