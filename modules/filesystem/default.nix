# modules/filesystem/default.nix
# Main filesystem module that imports all consolidated directory structures
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # CONSOLIDATED FILESYSTEM MODULES
  ####################################################################
  imports = [
    ./user-directories.nix        # User home directory structure and ADHD organization
    ./business-directories.nix    # Business applications, AI, and productivity tools
    ./media-directories.nix       # Media storage with hot/cold storage tiers
    ./service-directories.nix     # Service configuration directories (*ARR, surveillance)
    ./security-directories.nix    # Secrets, certificates, and security infrastructure
    ./system-directories.nix      # System caching, logging, and database storage
  ];
  
  ####################################################################
  # FILESYSTEM MODULE DOCUMENTATION
  ####################################################################
  environment.etc."filesystem-modules-overview.md".text = ''
    # Heartwood Craft NixOS Filesystem Structure
    
    This document provides an overview of the consolidated filesystem module structure
    for the Heartwood Craft NixOS configuration.
    
    ## Module Organization
    
    The filesystem is organized into six logical modules:
    
    ### 👤 User Directories (`user-directories.nix`)
    - **Path**: `/home/eric/`
    - **Purpose**: Personal workspace with ADHD-friendly organization
    - **Features**: PARA method adaptation, development workspace, secure SSH
    - **Documentation**: `/etc/user-directories-help.md`
    
    ### 💼 Business Directories (`business-directories.nix`)
    - **Paths**: `/opt/business/`, `/opt/ai/`, `/opt/adhd-tools/`
    - **Purpose**: Business intelligence, AI services, productivity tools
    - **Features**: API structure, document processing, AI model management
    - **Documentation**: `/etc/business-directories-help.md`
    
    ### 📺 Media Directories (`media-directories.nix`)
    - **Paths**: `/mnt/media/` (cold), `/mnt/hot/` (hot)
    - **Purpose**: Two-tier media storage and processing pipeline
    - **Features**: Hot/cold storage, automated processing, surveillance
    - **Documentation**: `/etc/media-directories-help.md`
    
    ### ⚙️ Service Directories (`service-directories.nix`)
    - **Paths**: `/opt/{service}/`
    - **Purpose**: Service configuration and container management
    - **Features**: *ARR applications, surveillance system, download management
    - **Documentation**: `/etc/service-directories-help.md`
    
    ### 🔐 Security Directories (`security-directories.nix`)
    - **Paths**: `/etc/secrets/`, `/var/lib/tailscale/`
    - **Purpose**: Secrets management and certificate infrastructure
    - **Features**: SOPS integration, Tailscale certificates, API key storage
    - **Documentation**: `/etc/security-directories-help.md`
    
    ### 🖥️ System Directories (`system-directories.nix`)
    - **Paths**: `/tmp/`, `/var/log/`, `/mnt/hot/databases/`, `/mnt/hot/ai/`
    - **Purpose**: System caching, logging, and high-performance storage
    - **Features**: GPU cache, database storage, AI models, health monitoring
    - **Documentation**: `/etc/system-directories-help.md`
    
    ## Design Principles
    
    ### 🎯 DRY (Don't Repeat Yourself)
    - Single source of truth for directory creation
    - Consistent permissions and ownership patterns
    - Centralized documentation and maintenance
    
    ### 🏗️ Modular Organization
    - Logical separation by function and purpose
    - Easy to maintain and extend individual modules
    - Clear dependencies and relationships
    
    ### 🔒 Security First
    - Principle of least privilege for file permissions
    - Secure defaults for sensitive directories
    - Integration with SOPS for encrypted secrets
    
    ### ⚡ Performance Optimization
    - Hot/cold storage tier separation
    - Strategic SSD placement for high-performance needs
    - Efficient cache management
    
    ### 🧠 ADHD-Friendly Design
    - Clear, numbered organization systems
    - Comprehensive documentation and help files
    - Automation to reduce cognitive load
    
    ## Storage Architecture
    
    ### 🔥 Hot Storage (NVMe SSD)
    ```
    /mnt/hot/
    ├── downloads/        # Active download processing
    ├── processing/       # *ARR temporary processing
    ├── cache/           # Application caches
    ├── databases/       # High-performance databases
    ├── ai/             # AI models and cache
    └── surveillance/    # Live recording buffer
    ```
    
    ### ❄️ Cold Storage (HDD)
    ```
    /mnt/media/
    ├── tv/             # TV series library
    ├── movies/         # Movie collection
    ├── music/          # Music library
    ├── pictures/       # Photo collection
    └── surveillance/   # Archived recordings
    ```
    
    ### 💼 Application Storage
    ```
    /opt/
    ├── business/       # Business intelligence platform
    ├── ai/            # AI and ML services
    ├── adhd-tools/    # Productivity and focus tools
    ├── surveillance/   # Security and monitoring
    └── {service}/     # Individual service configs
    ```
    
    ## Permission Structure
    
    ### User-Managed Directories
    - **Owner**: `eric users`
    - **Permissions**: `0755` (standard) or `0700` (secure)
    - **Usage**: Application data, personal files, service configs
    
    ### System-Managed Directories  
    - **Owner**: `root root`
    - **Permissions**: `0750` (secrets) or `0755` (standard)
    - **Usage**: System secrets, certificates, system logs
    
    ### Service-Specific Permissions
    - **Caddy Certificates**: `root caddy` with appropriate read permissions
    - **Database Storage**: `eric users` for application access
    - **Cache Directories**: `eric users` for service management
    
    ## Maintenance and Monitoring
    
    ### Automated Cleanup
    - Cache directories cleaned based on age and size
    - Temporary files cleaned on system restart
    - Log rotation for system and application logs
    
    ### Health Monitoring
    - SSD health monitoring for early failure detection
    - Disk usage monitoring with alerts
    - Performance metrics for storage tiers
    
    ### Backup Strategy
    - Critical data backed up to multiple locations
    - Encrypted backups for sensitive information
    - Recovery procedures documented and tested
    
    ## Integration Points
    
    ### NixOS Integration
    - systemd.tmpfiles.rules for directory creation
    - Service dependencies on directory availability
    - Automatic permissions and ownership management
    
    ### Application Integration
    - Container volume mounts to appropriate directories
    - Service configuration paths standardized
    - Environment variables for path references
    
    ### Security Integration
    - SOPS secrets deployed to secure directories
    - Certificate management for TLS services
    - Access control via file permissions
    
    ## Usage Examples
    
    ### Adding a New Service
    1. Add directory structure to appropriate module
    2. Document the service integration
    3. Update service configuration to use paths
    4. Test directory creation and permissions
    
    ### Extending Storage
    1. Identify storage tier requirements (hot vs cold)
    2. Add directory structure to media-directories.nix
    3. Update processing pipelines
    4. Configure monitoring and cleanup
    
    ### Security Updates
    1. Add new secret types to security-directories.nix
    2. Configure SOPS encryption rules
    3. Update service configurations
    4. Test secret deployment and access
    
    For detailed information about each module, refer to the individual help files
    listed above, or examine the module source files in `/etc/nixos/modules/filesystem/`.
  '';
  
  ####################################################################
  # FILESYSTEM MANAGEMENT TOOLS
  ####################################################################
  environment.systemPackages = with pkgs; [
    (writeScriptBin "filesystem-info" ''
      #!/bin/bash
      echo "📁 Heartwood Craft Filesystem Structure"
      echo "======================================="
      echo ""
      echo "📋 Available Documentation:"
      echo "  • Overview: /etc/filesystem-modules-overview.md"
      echo "  • User Directories: /etc/user-directories-help.md"
      echo "  • Business Directories: /etc/business-directories-help.md"
      echo "  • Media Directories: /etc/media-directories-help.md"
      echo "  • Service Directories: /etc/service-directories-help.md"
      echo "  • Security Directories: /etc/security-directories-help.md"
      echo "  • System Directories: /etc/system-directories-help.md"
      echo ""
      echo "💾 Storage Usage:"
      echo "Hot Storage (SSD):"
      df -h /mnt/hot 2>/dev/null || echo "  Not mounted"
      echo "Cold Storage (HDD):"
      df -h /mnt/media 2>/dev/null || echo "  Not mounted"
      echo ""
      echo "🔍 Quick Directory Check:"
      echo "User directories: $(test -d /home/eric && echo "✅" || echo "❌")"
      echo "Business directories: $(test -d /opt/business && echo "✅" || echo "❌")"
      echo "Security directories: $(test -d /etc/secrets && echo "✅" || echo "❌")"
      echo "Hot storage: $(test -d /mnt/hot && echo "✅" || echo "❌")"
      echo "Cold storage: $(test -d /mnt/media && echo "✅" || echo "❌")"
    '')
    
    (writeScriptBin "filesystem-check" ''
      #!/bin/bash
      echo "🔍 Filesystem Structure Verification"
      echo "===================================="
      echo ""
      
      # Check critical directories exist
      CRITICAL_DIRS=(
        "/home/eric"
        "/opt/business"
        "/etc/secrets"
        "/mnt/hot"
        "/mnt/media"
      )
      
      echo "📁 Critical Directories:"
      for dir in "''${CRITICAL_DIRS[@]}"; do
        if [ -d "$dir" ]; then
          echo "  ✅ $dir"
        else
          echo "  ❌ $dir (missing)"
        fi
      done
      
      echo ""
      echo "🔐 Permission Check:"
      echo "  /etc/secrets: $(ls -ld /etc/secrets 2>/dev/null | awk '{print $1, $3, $4}' || echo 'missing')"
      echo "  /home/eric/.ssh: $(ls -ld /home/eric/.ssh 2>/dev/null | awk '{print $1, $3, $4}' || echo 'missing')"
      
      echo ""
      echo "💾 Storage Health:"
      if command -v smartctl >/dev/null 2>&1; then
        echo "  SSD Health: $(sudo smartctl -H /dev/nvme0n1 2>/dev/null | grep overall || echo 'check manually')"
      else
        echo "  SSD Health: smartctl not available"
      fi
      
      echo ""
      echo "📊 Disk Usage Summary:"
      du -sh /opt/* /home/eric/* /mnt/hot/* /mnt/media/* 2>/dev/null | sort -hr | head -10
    '')
  ];
}