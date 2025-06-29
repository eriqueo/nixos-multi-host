# modules/filesystem/service-directories.nix
# Consolidated service configuration directory structure
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # SERVICE CONFIGURATION DIRECTORIES
  ####################################################################
  systemd.tmpfiles.rules = [
    ####################################################################
    # *ARR APPLICATIONS (Media Management)
    ####################################################################
    # Lidarr (Music)
    "d /opt/lidarr 0755 eric users -"
    "d /opt/lidarr/config 0755 eric users -"
    "d /opt/lidarr/custom-services.d 0755 eric users -"
    "d /opt/lidarr/custom-cont-init.d 0755 eric users -"
    
    # Radarr (Movies)
    "d /opt/radarr 0755 eric users -"
    "d /opt/radarr/config 0755 eric users -"
    "d /opt/radarr/custom-services.d 0755 eric users -"
    "d /opt/radarr/custom-cont-init.d 0755 eric users -"
    
    # Sonarr (TV Series)
    "d /opt/sonarr 0755 eric users -"
    "d /opt/sonarr/config 0755 eric users -"
    "d /opt/sonarr/custom-services.d 0755 eric users -"
    "d /opt/sonarr/custom-cont-init.d 0755 eric users -"
    
    # Legacy download application directories (from backup configs)
    "d /opt/downloads 0755 eric users -"
    "d /opt/downloads/qbittorrent 0755 eric users -"
    "d /opt/downloads/sonarr 0755 eric users -"
    "d /opt/downloads/radarr 0755 eric users -"
    "d /opt/downloads/lidarr 0755 eric users -"
    "d /opt/downloads/prowlarr 0755 eric users -"
    "d /opt/downloads/navidrome 0755 eric users -"
    "d /opt/downloads/immich 0755 eric users -"
    
    ####################################################################
    # SURVEILLANCE SERVICES
    ####################################################################
    # Main surveillance directory
    "d /opt/surveillance 0755 eric users -"
    
    # Frigate (AI-powered surveillance)
    "d /opt/surveillance/frigate 0755 eric users -"
    "d /opt/surveillance/frigate/config 0755 eric users -"
    "d /opt/surveillance/frigate/media 0755 eric users -"
    
    # Home Assistant (Smart home automation)
    "d /opt/surveillance/home-assistant 0755 eric users -"
    "d /opt/surveillance/home-assistant/config 0755 eric users -"
  ];
  
  ####################################################################
  # SERVICE DIRECTORIES DOCUMENTATION
  ####################################################################
  environment.etc."service-directories-help.md".text = ''
    # Service Configuration Directory Structure Guide
    
    ## *ARR Application Suite (/opt/{arr}/)
    
    The *ARR applications manage automated media acquisition and organization:
    
    ### 📀 Lidarr (/opt/lidarr/)
    - **Purpose**: Music collection management
    - **config/**: Application settings, quality profiles, indexers
    - **custom-services.d/**: Custom startup services
    - **custom-cont-init.d/**: Container initialization scripts
    
    ### 🎬 Radarr (/opt/radarr/)
    - **Purpose**: Movie collection management
    - **config/**: Application settings, quality profiles, indexers
    - **custom-services.d/**: Custom startup services
    - **custom-cont-init.d/**: Container initialization scripts
    
    ### 📺 Sonarr (/opt/sonarr/)
    - **Purpose**: TV series collection management
    - **config/**: Application settings, quality profiles, indexers
    - **custom-services.d/**: Custom startup services
    - **custom-cont-init.d/**: Container initialization scripts
    
    ## Download Management (/opt/downloads/)
    
    Legacy configuration directories for download clients:
    
    ### Download Clients
    - **qbittorrent/**: Torrent client configuration
    - **prowlarr/**: Indexer management
    
    ### Media Applications
    - **navidrome/**: Music streaming server
    - **immich/**: Photo management and sharing
    
    ### *ARR Integration
    - **sonarr/**, **radarr/**, **lidarr/**: Legacy config locations
    
    ## Surveillance System (/opt/surveillance/)
    
    ### 🔍 Frigate (/opt/surveillance/frigate/)
    - **Purpose**: AI-powered video surveillance
    - **config/**: Camera configurations, AI detection settings
    - **media/**: Local media storage (typically linked to hot storage)
    
    ### 🏠 Home Assistant (/opt/surveillance/home-assistant/)
    - **Purpose**: Smart home automation and integration
    - **config/**: Automation rules, device configurations, dashboards
    
    ## Configuration Management Best Practices
    
    ### Directory Structure Patterns
    ```
    /opt/{service}/
    ├── config/                    # Main configuration files
    ├── custom-services.d/         # Custom systemd services
    └── custom-cont-init.d/        # Container initialization scripts
    ```
    
    ### Ownership and Permissions
    - **Owner**: `eric users` (user-managed services)
    - **Permissions**: `0755` (read/write for user, read for others)
    - **Purpose**: Allows application containers to access configs
    
    ### Integration Points
    
    #### Storage Integration
    - Config directories: `/opt/{service}/config/`
    - Working directories: `/mnt/hot/processing/{service}-temp/`
    - Final storage: `/mnt/media/{type}/`
    
    #### Network Integration
    - All services accessible via Caddy reverse proxy
    - Tailscale integration for secure remote access
    - Internal service discovery via Docker networking
    
    #### Security Integration
    - SOPS-encrypted secrets for API keys and passwords
    - Service-specific user permissions where needed
    - Network isolation via container networking
    
    ## Service Lifecycle Management
    
    ### Configuration Backup
    - Regular automated backups of /opt/ directories
    - Version control for configuration changes
    - Migration scripts for service updates
    
    ### Container Management
    - Podman/Docker integration for service deployment
    - Custom initialization scripts for complex setups
    - Health monitoring and automatic restarts
    
    ### Monitoring and Maintenance
    - Log aggregation from all services
    - Disk usage monitoring for config directories
    - Performance metrics collection
  '';
}