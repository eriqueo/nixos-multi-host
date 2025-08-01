# modules/filesystem/media-directories.nix
# Consolidated media storage directory structure with hot/cold storage tiers
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # COLD STORAGE MEDIA DIRECTORIES (HDD - Long-term storage)
  ####################################################################
  systemd.tmpfiles.rules = [
    # Main media directory (cold storage)
    "d /mnt/media 0755 eric users -"
    
    # Media type organization
    "d /mnt/media/tv 0755 eric users -"                 # TV series collection
    "d /mnt/media/movies 0755 eric users -"             # Movie collection
    "d /mnt/media/music 0755 eric users -"              # Music library
    "d /mnt/media/pictures 0755 eric users -"           # Photo collection
    "d /mnt/media/downloads 0755 eric users -"          # Long-term download storage
    
    # Surveillance storage (cold archive)
    "d /mnt/media/surveillance 0755 eric users -"
    "d /mnt/media/surveillance/frigate 0755 eric users -"
    "d /mnt/media/surveillance/frigate/media 0755 eric users -"
    
    ####################################################################
    # HOT STORAGE MEDIA DIRECTORIES (SSD - Active processing)
    ####################################################################
    # Root hot storage directory
    "d /mnt/hot 0755 eric users -"
    
    # DOWNLOAD STAGING AREA (active downloads and processing)
    "d /mnt/hot/downloads 0755 eric users -"
    
    # Torrent downloads by category
    "d /mnt/hot/downloads/torrents 0755 eric users -"
    "d /mnt/hot/downloads/torrents/music 0755 eric users -"
    "d /mnt/hot/downloads/torrents/movies 0755 eric users -"
    "d /mnt/hot/downloads/torrents/tv 0755 eric users -"
    
    # Usenet downloads by category
    "d /mnt/hot/downloads/usenet 0755 eric users -"
    "d /mnt/hot/downloads/usenet/music 0755 eric users -"
    "d /mnt/hot/downloads/usenet/movies 0755 eric users -"
    "d /mnt/hot/downloads/usenet/tv 0755 eric users -"
    "d /mnt/hot/downloads/usenet/software 0755 eric users -"
    
    # Soulseek downloads
    "d /mnt/hot/downloads/soulseek 0755 eric users -"
    
    # SAFE PROCESSING ZONES (quality control and manual intervention)
    "d /mnt/hot/manual 0755 eric users -"               # Manual processing area
    "d /mnt/hot/manual/music 0755 eric users -"
    "d /mnt/hot/manual/movies 0755 eric users -"
    "d /mnt/hot/manual/tv 0755 eric users -"
    
    "d /mnt/hot/quarantine 0755 eric users -"           # Quarantine for suspicious files
    "d /mnt/hot/quarantine/music 0755 eric users -"
    "d /mnt/hot/quarantine/movies 0755 eric users -"
    "d /mnt/hot/quarantine/tv 0755 eric users -"
    
    # *ARR APPLICATION WORKING DIRECTORIES (temporary processing)
    "d /mnt/hot/processing 0755 eric users -"
    "d /mnt/hot/processing/lidarr-temp 0755 eric users -"   # Lidarr temporary processing
    "d /mnt/hot/processing/sonarr-temp 0755 eric users -"   # Sonarr temporary processing
    "d /mnt/hot/processing/radarr-temp 0755 eric users -"   # Radarr temporary processing
    
    # MEDIA CACHE DIRECTORIES (fast access to frequently used content)
    "d /mnt/hot/cache 0755 eric users -"
    "d /mnt/hot/cache/frigate 0755 eric users -"            # Frigate surveillance cache
    "d /mnt/hot/cache/jellyfin 0755 eric users -"           # Jellyfin transcoding cache
    "d /mnt/hot/cache/immich 0755 eric users -"             # Immich photo processing cache
    
    # SURVEILLANCE BUFFER (immediate recordings before cold storage)
    "d /mnt/hot/surveillance 0755 eric users -"
    "d /mnt/hot/surveillance/buffer 0755 eric users -"      # Live recording buffer
  ];
  
  ####################################################################
  # MEDIA DIRECTORIES DOCUMENTATION
  ####################################################################
  environment.etc."media-directories-help.md".text = ''
    # Media Directory Structure Guide
    
    ## Two-Tier Storage Architecture
    
    This system uses a hot/cold storage architecture for optimal performance and cost:
    
    ### 🔥 Hot Storage (SSD - /mnt/hot/)
    - **Purpose**: Active processing, temporary files, frequent access
    - **Performance**: High-speed SSD for fast I/O operations
    - **Usage**: Downloads, processing, caching, live recordings
    
    ### ❄️ Cold Storage (HDD - /mnt/media/)
    - **Purpose**: Long-term storage, archived content
    - **Performance**: Large capacity HDD for bulk storage
    - **Usage**: Final media library, archived surveillance footage
    
    ## Download and Processing Pipeline
    
    ### 1. Active Downloads (/mnt/hot/downloads/)
    ```
    Torrents → /mnt/hot/downloads/torrents/{type}/
    Usenet   → /mnt/hot/downloads/usenet/{type}/
    Soulseek → /mnt/hot/downloads/soulseek/
    ```
    
    ### 2. Quality Control (/mnt/hot/manual/ and /mnt/hot/quarantine/)
    - **manual/**: Files requiring human review before library addition
    - **quarantine/**: Suspicious files isolated for security scanning
    
    ### 3. *ARR Processing (/mnt/hot/processing/)
    - **lidarr-temp/**: Music processing and metadata enrichment
    - **sonarr-temp/**: TV series processing and organization
    - **radarr-temp/**: Movie processing and quality upgrades
    
    ### 4. Final Storage (/mnt/media/)
    ```
    Processed files → /mnt/media/{type}/
    ```
    
    ## Cache Management (/mnt/hot/cache/)
    
    ### Application Caches
    - **frigate/**: Surveillance AI processing cache
    - **jellyfin/**: Media server transcoding cache
    - **immich/**: Photo management and ML processing cache
    
    ## Surveillance Workflow
    
    ### Live Recording Pipeline
    ```
    Camera → /mnt/hot/surveillance/buffer/ → /mnt/media/surveillance/
    ```
    
    ### Storage Lifecycle
    1. **Buffer**: Recent recordings on fast SSD (24-48 hours)
    2. **Archive**: Older recordings moved to HDD for long-term storage
    3. **Cache**: Frequently accessed clips cached on SSD
    
    ## Automation and Lifecycle Management
    
    ### Automated Processes
    - Downloads automatically moved from hot to cold storage when complete
    - Cache directories cleaned based on age and disk usage
    - Surveillance buffer rotated to prevent SSD fill-up
    - Failed downloads quarantined for manual review
    
    ### Monitoring Points
    - SSD usage monitoring to prevent overflow
    - Failed processing alerts for manual intervention
    - Storage tier balancing for optimal performance
    
    ## Security and Safety Features
    
    ### Quarantine System
    - Suspicious downloads isolated automatically
    - Manual review required before library integration
    - Virus scanning integration points
    
    ### Backup Considerations
    - Hot storage: Temporary, can be recreated
    - Cold storage: Critical, requires backup strategy
    - Configuration: Stored separately in /opt/ directories
  '';
}