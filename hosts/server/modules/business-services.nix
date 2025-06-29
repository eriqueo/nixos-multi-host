{ config, pkgs, ... }:

{
  # SOPS secrets configuration for database credentials
  sops.secrets.database_password = {
    sopsFile = ../../../secrets/database.yaml;
    key = "postgres/password";
    mode = "0400";
    owner = "postgres";
    group = "postgres";
  };
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
    
    # Create business database and user with proper PostgreSQL syntax
    initialScript = pkgs.writeShellScript "postgres-init.sh" ''
      # Read password from SOPS secret
      DB_PASSWORD=$(cat ${config.sops.secrets.database_password.path})
      
      # Check if database exists, create if not
      if ! ${pkgs.postgresql_15}/bin/psql -U postgres -lqt | cut -d \| -f 1 | grep -qw heartwood_business; then
        echo "Creating heartwood_business database..."
        ${pkgs.postgresql_15}/bin/psql -U postgres -c "CREATE DATABASE heartwood_business;"
      else
        echo "Database heartwood_business already exists"
      fi
      
      # Create role (user) with proper conditional syntax
      ${pkgs.postgresql_15}/bin/psql -U postgres -c "
      DO \$\$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'business_user') THEN
          CREATE ROLE business_user WITH LOGIN PASSWORD '$DB_PASSWORD';
        END IF;
      END
      \$\$;
      "
      
      # Grant privileges
      ${pkgs.postgresql_15}/bin/psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE heartwood_business TO business_user;"
      
      # Enable UUID extension in the business database
      ${pkgs.postgresql_15}/bin/psql -U postgres -d heartwood_business -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
      
      echo "PostgreSQL initialization completed successfully"
    '';
    
    # Basic PostgreSQL optimizations
    settings = {
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
    };
  };

  # Ensure PostgreSQL waits for SOPS secrets to be available
  systemd.services.postgresql.after = [ "sops-install-secrets.service" ];
  systemd.services.postgresql.wants = [ "sops-install-secrets.service" ];
  
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
