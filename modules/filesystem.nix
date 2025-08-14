# modules/filesystem.nix
# Charter-compliant filesystem structure with enable toggles
# Clean numbered PARA/GTD structure with selective recursion
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hwc.filesystem;
in
{
  ####################################################################
  # IMPORTS - Required modules for path configuration
  ####################################################################
  imports = [
    ./paths  # Centralized path configuration system
  ];

  ####################################################################
  # OPTIONS - Enable toggles for different directory sets
  ####################################################################
  options.hwc.filesystem = {

    userDirectories = {
      enable = mkEnableOption "PARA user directories, XDG config, and compatibility symlinks";
      description = "Creates clean numbered PARA directory structure with selective recursion";
    };

    serverStorage = {
      enable = mkEnableOption "hot/cold storage directories for media server";
      description = "Creates two-tier storage system with /mnt/hot (SSD) and /mnt/media (HDD)";
    };

    businessDirectories = {
      enable = mkEnableOption "business intelligence and AI application directories";
      description = "Creates /opt/business, /opt/ai, and /opt/adhd-tools directory structures";
    };

    serviceDirectories = {
      enable = mkEnableOption "*ARR service configuration directories";
      description = "Creates configuration directories for media management services";
    };

    securityDirectories = {
      enable = mkEnableOption "security and secrets directories";
      description = "Creates /etc/secrets and certificate management directories";
    };
  };

  ####################################################################
  # CONFIGURATION - Conditional directory creation based on toggles
  ####################################################################
  config = mkMerge [

    ####################################################################
    # USER DIRECTORIES - Clean Numbered PARA Structure
    ####################################################################
    (mkIf cfg.userDirectories.enable {

      systemd.tmpfiles.rules = [
        # NixOS configuration access permissions
        "Z /etc/nixos - eric users - -"

        # Main user directory
        "d /home/eric 0755 eric users -"

        ####################################################################
        # GLOBAL INBOX - Central sorting area
        ####################################################################
        "d /home/eric/00-inbox 0755 eric users -"                    # Global inbox
        "d /home/eric/00-inbox/downloads 0755 eric users -"          # Browser downloads
        "d /home/eric/00-inbox/general 0755 eric users -"            # General unsorted items

        ####################################################################
        # WORK AREA - Recursive PARA structure
        ####################################################################
        "d /home/eric/01-hwc 0755 eric users -"                      # Heartwood Craft work
        "d /home/eric/01-hwc/00-inbox 0755 eric users -"             # Work inbox
        "d /home/eric/01-hwc/01-active 0755 eric users -"            # Current projects
        "d /home/eric/01-hwc/02-reference 0755 eric users -"         # Work documentation
        "d /home/eric/01-hwc/03-archive 0755 eric users -"           # Completed work

        # Active work project structure
        "d /home/eric/01-hwc/01-active/clients 0755 eric users -"    # Client projects
        "d /home/eric/01-hwc/01-active/internal 0755 eric users -"   # Internal projects
        "d /home/eric/01-hwc/01-active/proposals 0755 eric users -"  # Active proposals

        # Work reference materials
        "d /home/eric/01-hwc/02-reference/processes 0755 eric users -"    # Business processes
        "d /home/eric/01-hwc/02-reference/templates 0755 eric users -"    # Work templates
        "d /home/eric/01-hwc/02-reference/resources 0755 eric users -"    # Work resources

        ####################################################################
        # PERSONAL AREA - Recursive PARA structure
        ####################################################################
        "d /home/eric/02-personal 0755 eric users -"                 # Personal life management
        "d /home/eric/02-personal/00-inbox 0755 eric users -"        # Personal inbox
        "d /home/eric/02-personal/01-active 0755 eric users -"       # Current personal projects
        "d /home/eric/02-personal/02-reference 0755 eric users -"    # Personal documentation
        "d /home/eric/02-personal/03-archive 0755 eric users -"      # Personal archive

        # Active personal project areas
        "d /home/eric/02-personal/01-active/health 0755 eric users -"     # Health & fitness
        "d /home/eric/02-personal/01-active/finance 0755 eric users -"    # Financial projects
        "d /home/eric/02-personal/01-active/home 0755 eric users -"       # Home improvement
        "d /home/eric/02-personal/01-active/learning 0755 eric users -"   # Personal learning

        # Personal reference materials
        "d /home/eric/02-personal/02-reference/documents 0755 eric users -"   # Important docs
        "d /home/eric/02-personal/02-reference/manuals 0755 eric users -"     # Personal manuals
        "d /home/eric/02-personal/02-reference/contacts 0755 eric users -"    # Contact info

        ####################################################################
        # TECHNOLOGY AREA - Recursive PARA structure
        ####################################################################
        "d /home/eric/03-tech 0755 eric users -"                     # Technology & development
        "d /home/eric/03-tech/00-inbox 0755 eric users -"            # Tech inbox
        "d /home/eric/03-tech/01-active 0755 eric users -"           # Current tech projects
        "d /home/eric/03-tech/02-reference 0755 eric users -"        # Tech documentation
        "d /home/eric/03-tech/03-archive 0755 eric users -"          # Old tech projects

        # Active tech project areas
        "d /home/eric/03-tech/01-active/nixos 0755 eric users -"          # NixOS projects
        "d /home/eric/03-tech/01-active/development 0755 eric users -"     # Code projects
        "d /home/eric/03-tech/01-active/experiments 0755 eric users -"     # Tech experiments
        "d /home/eric/03-tech/01-active/learning 0755 eric users -"        # Tech courses

        # Tech reference materials
        "d /home/eric/03-tech/02-reference/manuals 0755 eric users -"      # Software manuals
        "d /home/eric/03-tech/02-reference/configs 0755 eric users -"      # Configuration files
        "d /home/eric/03-tech/02-reference/tools 0755 eric users -"        # Development tools

        ####################################################################
        # REFERENCE AREA - Simple structure
        ####################################################################
        "d /home/eric/04-ref 0755 eric users -"                      # Reference materials
        "d /home/eric/04-ref/templates 0755 eric users -"            # Document templates
        "d /home/eric/04-ref/manuals 0755 eric users -"              # General manuals
        "d /home/eric/04-ref/research 0755 eric users -"             # Research materials
        "d /home/eric/04-ref/forms 0755 eric users -"                # Forms and paperwork

        ####################################################################
        # MEDIA AREA - Simple structure
        ####################################################################
        "d /home/eric/05-media 0755 eric users -"                    # Media & entertainment
        "d /home/eric/05-media/pictures 0755 eric users -"           # Photos and images
        "d /home/eric/05-media/music 0755 eric users -"              # Music collection
        "d /home/eric/05-media/videos 0755 eric users -"             # Video files
        "d /home/eric/05-media/documents 0755 eric users -"          # Media-related documents

        # Media subdirectories
        "d /home/eric/05-media/pictures/screenshots 0755 eric users -"    # Screenshots
        "d /home/eric/05-media/pictures/camera 0755 eric users -"         # Camera imports
        "d /home/eric/05-media/pictures/projects 0755 eric users -"       # Project photos
        "d /home/eric/05-media/pictures/wallpapers 0755 eric users -"     # Desktop wallpapers

        ####################################################################
        # VAULTS AREA - Knowledge management and cloud storage
        ####################################################################
        "d /home/eric/99-vaults 0755 eric users -"               # Knowledge management

        # Cloud storage drives
        "d /home/eric/99-vaults/drives 0755 eric users -"        # Cloud storage area
        "d /home/eric/99-vaults/drives/proton 0755 eric users -" # Proton Drive
        "d /home/eric/99-vaults/drives/google 0755 eric users -" # Google Drive

        # Obsidian vault directories (preserving existing structure)
        # Note: Existing vaults will need to be moved manually from 01-documents/01-vaults/
        # Current vaults: .claude, 00_tech, 01_hwc, 02_personal, 03_nixos, 04-transcripts, backups

        ####################################################################
        # STANDARD USER CONFIGURATION DIRECTORIES
        ####################################################################
        "d /home/eric/.config 0755 eric users -"
        "d /home/eric/.local 0755 eric users -"
        "d /home/eric/.local/bin 0755 eric users -"
        "d /home/eric/.ssh 0700 eric users -"              # SSH keys (secure permissions)

        ####################################################################
        # TRADITIONAL DIRECTORY SYMLINKS - Application Compatibility
        ####################################################################
        "L /home/eric/Desktop - - - - /home/eric/00-inbox/general"           # Desktop → general inbox
        "L /home/eric/Downloads - - - - /home/eric/00-inbox/downloads"       # Downloads → inbox/downloads
        "L /home/eric/Documents - - - - /home/eric/04-ref"                   # Documents → reference
        "L /home/eric/Pictures - - - - /home/eric/05-media/pictures"         # Pictures → media/pictures
        "L /home/eric/Music - - - - /home/eric/05-media/music"               # Music → media/music
        "L /home/eric/Videos - - - - /home/eric/05-media/videos"             # Videos → media/videos
        "L /home/eric/Templates - - - - /home/eric/04-ref/templates"         # Templates → ref/templates
        "L /home/eric/Public - - - - /home/eric/00-inbox/general"            # Public → general inbox

        # Cloud service integration (routed to vaults/drives)
        "L /home/eric/Proton Drive - - - - /home/eric/99-vaults/drives/proton"  # Proton → vaults/drives/proton
        "L /home/eric/Google Drive - - - - /home/eric/99-vaults/drives/google"  # Google → vaults/drives/google

        # Development directory expectations (pointed to tech active area)
        "L /home/eric/Code - - - - /home/eric/03-tech/01-active/development"    # Code → tech/active/development
        "L /home/eric/Development - - - - /home/eric/03-tech/01-active"         # Development → tech/active
        "L /home/eric/Projects - - - - /home/eric/03-tech/01-active"            # Projects → tech/active
        "L /home/eric/Workspace - - - - /home/eric/03-tech/01-active"           # Workspace → tech/active

        # Media application shortcuts
        "L /home/eric/Screenshots - - - - /home/eric/05-media/pictures/screenshots"  # Screenshots
        "L /home/eric/Camera - - - - /home/eric/05-media/pictures/camera"           # Camera imports

        # Create marker files to indicate PARA management is active
        "f /home/eric/.para-managed 0644 eric users - Clean numbered PARA structure managed by NixOS"
        "f /home/eric/00-inbox/.para-managed 0644 eric users - Global inbox managed by PARA system"
      ];

      ####################################################################
      # XDG USER DIRECTORIES CONFIGURATION
      ####################################################################
      environment.etc."skel/.config/user-dirs.dirs".text = ''
        # XDG User Directories - Clean PARA Method Integration
        XDG_DESKTOP_DIR="$HOME/00-inbox/general"         # Desktop files → general inbox
        XDG_DOWNLOAD_DIR="$HOME/00-inbox/downloads"      # Downloads → inbox/downloads
        XDG_TEMPLATES_DIR="$HOME/04-ref/templates"       # Templates → ref/templates
        XDG_PUBLICSHARE_DIR="$HOME/00-inbox/general"     # Public share → general inbox
        XDG_DOCUMENTS_DIR="$HOME/04-ref"                 # Documents → reference
        XDG_MUSIC_DIR="$HOME/05-media/music"             # Music → media/music
        XDG_PICTURES_DIR="$HOME/05-media/pictures"       # Pictures → media/pictures
        XDG_VIDEOS_DIR="$HOME/05-media/videos"           # Videos → media/videos
      '';

      ####################################################################
      # HOME MANAGER INTEGRATION
      ####################################################################
      home-manager.users.eric = {
        xdg.userDirs = {
          enable = true;
          createDirectories = true;

          # Map XDG directories to clean PARA structure
          desktop = "$HOME/00-inbox/general";              # Desktop → general inbox
          download = "$HOME/00-inbox/downloads";           # Downloads → inbox/downloads
          templates = "$HOME/04-ref/templates";            # Templates → ref/templates
          publicShare = "$HOME/00-inbox/general";          # Public → general inbox
          documents = "$HOME/04-ref";                      # Documents → reference
          music = "$HOME/05-media/music";                  # Music → media/music
          pictures = "$HOME/05-media/pictures";            # Pictures → media/pictures
          videos = "$HOME/05-media/videos";                # Videos → media/videos
        };

        # Shell Aliases for Easy Navigation
        programs.zsh.shellAliases = {
          # Traditional navigation (compatibility)
          desktop = "cd ~/00-inbox/general";
          downloads = "cd ~/00-inbox/downloads";
          documents = "cd ~/04-ref";
          pictures = "cd ~/05-media/pictures";
          music = "cd ~/05-media/music";
          videos = "cd ~/05-media/videos";

          # PARA structure navigation (main areas)
          inbox = "cd ~/00-inbox";
          hwc = "cd ~/01-hwc";
          personal = "cd ~/02-personal";
          tech = "cd ~/03-tech";
          ref = "cd ~/04-ref";
          vaults = "cd ~/99-vaults";

          # Work area shortcuts
          work = "cd ~/01-hwc";
          active-work = "cd ~/01-hwc/01-active";
          clients = "cd ~/01-hwc/01-active/clients";

          # Personal area shortcuts
          active-personal = "cd ~/02-personal/01-active";
          health = "cd ~/02-personal/01-active/health";
          finance = "cd ~/02-personal/01-active/finance";

          # Tech area shortcuts
          active-tech = "cd ~/03-tech/01-active";
          nixos = "cd ~/03-tech/01-active/nixos";
          dev = "cd ~/03-tech/01-active/development";

          # Common shortcuts
          templates = "cd ~/04-ref/templates";
          screenshots = "cd ~/05-media/pictures/screenshots";
          camera = "cd ~/05-media/pictures/camera";
          drives = "cd ~/99-vaults/drives";
        };

        # File Manager Bookmarks for Easy Access
        gtk.gtk3.bookmarks = [
          "file:///home/eric/00-inbox Inbox"
          "file:///home/eric/00-inbox/downloads Downloads"
          "file:///home/eric/01-hwc HWC-Work"
          "file:///home/eric/01-hwc/01-active Active-Work"
          "file:///home/eric/02-personal Personal"
          "file:///home/eric/02-personal/01-active Active-Personal"
          "file:///home/eric/03-tech Technology"
          "file:///home/eric/03-tech/01-active Active-Tech"
          "file:///home/eric/04-ref Reference"
          "file:///home/eric/05-media Media"
          "file:///home/eric/05-media/pictures Pictures"
          "file:///home/eric/99-vaults Vaults"
          "file:///home/eric/99-vaults/drives Drives"
        ];
      };

      ####################################################################
      # ENVIRONMENT VARIABLES - Application Compatibility
      ####################################################################
      environment.sessionVariables = {
        # XDG Base Directory specification overrides
        XDG_DESKTOP_DIR = "$HOME/00-inbox/general";
        XDG_DOWNLOAD_DIR = "$HOME/00-inbox/downloads";
        XDG_TEMPLATES_DIR = "$HOME/04-ref/templates";
        XDG_PUBLICSHARE_DIR = "$HOME/00-inbox/general";
        XDG_DOCUMENTS_DIR = "$HOME/04-ref";
        XDG_MUSIC_DIR = "$HOME/05-media/music";
        XDG_PICTURES_DIR = "$HOME/05-media/pictures";
        XDG_VIDEOS_DIR = "$HOME/05-media/videos";

        # Common application environment variables
        PHOTOS_DIR = "$HOME/05-media/pictures";
        PICTURES_DIR = "$HOME/05-media/pictures";
        MUSIC_DIR = "$HOME/05-media/music";
        VIDEOS_DIR = "$HOME/05-media/videos";
        DOCUMENTS_DIR = "$HOME/04-ref";
        DOWNLOADS_DIR = "$HOME/00-inbox/downloads";
        DESKTOP_DIR = "$HOME/00-inbox/general";
        TEMPLATES_DIR = "$HOME/04-ref/templates";

        # PARA structure environment variables
        INBOX_DIR = "$HOME/00-inbox";
        WORK_DIR = "$HOME/01-hwc";
        PERSONAL_DIR = "$HOME/02-personal";
        TECH_DIR = "$HOME/03-tech";
        REFERENCE_DIR = "$HOME/04-ref";
        MEDIA_DIR = "$HOME/05-media";
        VAULTS_DIR = "$HOME/99-vaults";

        # Development environment paths (updated to tech active)
        PROJECTS_DIR = "$HOME/03-tech/01-active";
        CODE_DIR = "$HOME/03-tech/01-active/development";
        DEV_DIR = "$HOME/03-tech/01-active";
        SRC_DIR = "$HOME/03-tech/01-active/development";
        WORKSPACE_DIR = "$HOME/03-tech/01-active";

        # Work-specific paths
        HWC_DIR = "$HOME/01-hwc";
        BUSINESS_DIR = "$HOME/01-hwc";
        CLIENTS_DIR = "$HOME/01-hwc/01-active/clients";

        # Screenshots and specialized media directories
        SCREENSHOT_DIR = "$HOME/05-media/pictures/screenshots";
        CAMERA_DIR = "$HOME/05-media/pictures/camera";

        # Cloud storage paths (updated to vaults/drives structure)
        PROTON_DRIVE_DIR = "$HOME/99-vaults/drives/proton";
        GOOGLE_DRIVE_DIR = "$HOME/99-vaults/drives/google";
        DRIVES_DIR = "$HOME/99-vaults/drives";

        # Temporary and processing directories
        TEMP_DIR = "$HOME/00-inbox/general";
        TMP_DIR = "$HOME/00-inbox/general";
        PROCESSING_DIR = "$HOME/00-inbox/general";
      };
    })

    ####################################################################
    # SERVER STORAGE DIRECTORIES - Hot/Cold Storage Architecture
    ####################################################################
    (mkIf cfg.serverStorage.enable {
      systemd.tmpfiles.rules = [
        # COLD STORAGE - HDD for long-term media library storage
        "d /mnt/media 0755 eric users -"                       # Main cold storage mount point
        "d /mnt/media/tv 0755 eric users -"                    # TV series collection
        "d /mnt/media/movies 0755 eric users -"                # Movie collection
        "d /mnt/media/music 0755 eric users -"                 # Music library
        "d /mnt/media/pictures 0755 eric users -"              # Photo collection
        "d /mnt/media/downloads 0755 eric users -"             # Long-term download storage
        "d /mnt/media/surveillance 0755 eric users -"          # Archived surveillance footage
        "d /mnt/media/surveillance/frigate 0755 eric users -"
        "d /mnt/media/surveillance/frigate/media 0755 eric users -"

        # HOT STORAGE - SSD for active processing and caching
        "d /mnt/hot 0755 eric users -"                         # Main hot storage mount point

        # Download staging area (active downloads before processing)
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

        # Processing zones for quality control and manual intervention
        "d /mnt/hot/manual 0755 eric users -"                  # Manual processing area
        "d /mnt/hot/manual/music 0755 eric users -"
        "d /mnt/hot/manual/movies 0755 eric users -"
        "d /mnt/hot/manual/tv 0755 eric users -"
        "d /mnt/hot/quarantine 0755 eric users -"              # Quarantine for suspicious files
        "d /mnt/hot/quarantine/music 0755 eric users -"
        "d /mnt/hot/quarantine/movies 0755 eric users -"
        "d /mnt/hot/quarantine/tv 0755 eric users -"

        # *ARR application working directories (temporary processing)
        "d /mnt/hot/processing 0755 eric users -"
        "d /mnt/hot/processing/lidarr-temp 0755 eric users -"  # Lidarr temporary processing
        "d /mnt/hot/processing/sonarr-temp 0755 eric users -"  # Sonarr temporary processing
        "d /mnt/hot/processing/radarr-temp 0755 eric users -"  # Radarr temporary processing

        # Media cache directories for fast access to frequently used content
        "d /mnt/hot/cache 0755 eric users -"
        "d /mnt/hot/cache/frigate 0755 eric users -"           # Frigate surveillance cache
        "d /mnt/hot/cache/jellyfin 0755 eric users -"          # Jellyfin transcoding cache
        "d /mnt/hot/cache/immich 0755 eric users -"            # Immich photo processing cache

        # Surveillance buffer for immediate recordings
        "d /mnt/hot/surveillance 0755 eric users -"
        "d /mnt/hot/surveillance/buffer 0755 eric users -"     # Live recording buffer

        # Database storage on hot SSD for performance
        "d /mnt/hot/databases 0755 eric users -"
        "d /mnt/hot/databases/postgresql 0755 eric users -"    # PostgreSQL data
        "d /mnt/hot/databases/redis 0755 eric users -"         # Redis cache data

        # AI model storage on hot storage for fast loading
        "d /mnt/hot/ai 0755 eric users -"                      # AI models and cache
        "d /mnt/hot/ai/ollama 0755 eric users -"               # Ollama model storage

        # GPU cache directories for NVIDIA Quadro P1000
        "d /mnt/hot/cache/gpu 0755 eric users -"               # GPU-specific cache
        "d /mnt/hot/cache/tensorrt 0755 eric users -"          # TensorRT model cache
      ];
    })

    ####################################################################
    # BUSINESS & AI DIRECTORIES - Application Storage
    ####################################################################
    (mkIf cfg.businessDirectories.enable {
      systemd.tmpfiles.rules = [
        # Main business application directory
        "d /opt/business 0755 eric users -"
        "d /opt/business/api 0755 eric users -"                # Business API structure
        "d /opt/business/api/app 0755 eric users -"
        "d /opt/business/api/models 0755 eric users -"
        "d /opt/business/api/routes 0755 eric users -"
        "d /opt/business/api/services 0755 eric users -"
        "d /opt/business/dashboard 0755 eric users -"          # Business dashboard
        "d /opt/business/config 0755 eric users -"             # Business config
        "d /opt/business/uploads 0755 eric users -"            # Document uploads
        "d /opt/business/receipts 0755 eric users -"           # Receipt processing
        "d /opt/business/processed 0755 eric users -"          # Processed documents
        "d /opt/business/backups 0755 eric users -"            # Business data backups
        "d /opt/business/backups/secrets 0755 eric users -"    # Encrypted secret backups

        # AI/ML business intelligence directories
        "d /opt/ai 0755 eric users -"
        "d /opt/ai/models 0755 eric users -"                   # AI model files
        "d /opt/ai/context-snapshots 0755 eric users -"        # Context state backups
        "d /opt/ai/document-embeddings 0755 eric users -"      # Vector embeddings
        "d /opt/ai/business-rag 0755 eric users -"             # RAG system data

        # ADHD productivity tools directories
        "d /opt/adhd-tools 0755 eric users -"
        "d /opt/adhd-tools/context-snapshots 0755 eric users -"  # Work context saves
        "d /opt/adhd-tools/focus-logs 0755 eric users -"         # Focus session data
        "d /opt/adhd-tools/energy-tracking 0755 eric users -"    # Energy level logs
        "d /opt/adhd-tools/scripts 0755 eric users -"            # Automation scripts
      ];
    })

    ####################################################################
    # SERVICE CONFIGURATION DIRECTORIES - *ARR Apps & Services
    ####################################################################
    (mkIf cfg.serviceDirectories.enable {
      systemd.tmpfiles.rules = [
        # *ARR applications (media management)
        "d /opt/lidarr 0755 eric users -"                      # Music management
        "d /opt/lidarr/config 0755 eric users -"
        "d /opt/lidarr/custom-services.d 0755 eric users -"
        "d /opt/lidarr/custom-cont-init.d 0755 eric users -"
        "d /opt/radarr 0755 eric users -"                      # Movie management
        "d /opt/radarr/config 0755 eric users -"
        "d /opt/radarr/custom-services.d 0755 eric users -"
        "d /opt/radarr/custom-cont-init.d 0755 eric users -"
        "d /opt/sonarr 0755 eric users -"                      # TV series management
        "d /opt/sonarr/config 0755 eric users -"
        "d /opt/sonarr/custom-services.d 0755 eric users -"
        "d /opt/sonarr/custom-cont-init.d 0755 eric users -"

        # Legacy download application directories (compatibility)
        "d /opt/downloads 0755 eric users -"
        "d /opt/downloads/qbittorrent 0755 eric users -"
        "d /opt/downloads/sonarr 0755 eric users -"
        "d /opt/downloads/radarr 0755 eric users -"
        "d /opt/downloads/lidarr 0755 eric users -"
        "d /opt/downloads/prowlarr 0755 eric users -"
        "d /opt/downloads/navidrome 0755 eric users -"
        "d /opt/downloads/immich 0755 eric users -"
        "d /opt/downloads/sabnzbd 0755 eric users -"
        "d /opt/downloads/slskd 0755 eric users -"
        "d /opt/downloads/soularr 0755 eric users -"
        "d /opt/downloads/gluetun 0755 root root -"            # VPN container (root owned)

        # Surveillance services
        "d /opt/surveillance 0755 eric users -"
        "d /opt/surveillance/frigate 0755 eric users -"        # AI-powered surveillance
        "d /opt/surveillance/frigate/config 0755 eric users -"
        "d /opt/surveillance/frigate/media 0755 eric users -"
        "d /opt/surveillance/home-assistant 0755 eric users -" # Smart home automation
        "d /opt/surveillance/home-assistant/config 0755 eric users -"
      ];
    })

    ####################################################################
    # SECURITY DIRECTORIES - Secrets and Certificates
    ####################################################################
    (mkIf cfg.securityDirectories.enable {
      systemd.tmpfiles.rules = [
        # Main secrets directory (SOPS integration)
        "d /etc/secrets 0750 root root -"                      # Root-owned secrets
        "d /etc/secrets/age 0750 root root -"                  # Age encryption keys
        "d /etc/secrets/sops 0750 root root -"                 # SOPS encrypted files

        # Tailscale certificate management
        "d /var/lib/tailscale 0750 root root -"                # Tailscale state
        "d /var/lib/tailscale/certs 0750 caddy caddy -"        # Certificates (caddy access)
      ];
    })

  ];  # End mkMerge
}
