# modules/filesystem/system-directories.nix
# Consolidated system directory structure for caching, logging, and databases
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # SYSTEM DIRECTORIES
  ####################################################################
  systemd.tmpfiles.rules = [
    ####################################################################
    # TEMPORARY AND CACHE DIRECTORIES
    ####################################################################
    # GPU-related cache
    "d /tmp/cuda-cache 0755 eric users -"               # CUDA compilation cache
    "d /tmp/frigate-cache 0755 eric users -"            # Frigate AI processing cache
    
    ####################################################################
    # SYSTEM LOGGING DIRECTORIES
    ####################################################################
    # GPU monitoring and statistics
    "d /var/log/gpu-stats 0755 eric users -"            # GPU performance logs
    
    # Storage health monitoring
    "f /var/log/ssd-health.log 0644 root root -"        # SSD health monitoring log
    
    ####################################################################
    # DATABASE STORAGE (Hot Storage Tier)
    ####################################################################
    # High-performance database storage on SSD
    "d /mnt/hot/databases 0755 eric users -"
    "d /mnt/hot/databases/postgresql 0755 eric users -"     # PostgreSQL data directory
    "d /mnt/hot/databases/arr-databases 0755 eric users -"  # *ARR application databases
    
    ####################################################################
    # AI MODEL STORAGE (Hot Storage Tier)
    ####################################################################
    # AI model storage for fast loading
    "d /mnt/hot/ai 0755 eric users -"
    "d /mnt/hot/ai/models 0755 eric users -"            # AI model files
    "d /mnt/hot/ai/cache 0755 eric users -"             # AI processing cache
  ];
  
  ####################################################################
  # SYSTEM DIRECTORIES DOCUMENTATION
  ####################################################################
  environment.etc."system-directories-help.md".text = ''
    # System Directory Structure Guide
    
    ## Temporary and Cache Directories (/tmp/)
    
    ### 🖥️ GPU Cache (/tmp/cuda-cache/)
    - **Purpose**: CUDA kernel compilation cache
    - **Usage**: Speeds up GPU computation startup times
    - **Lifecycle**: Automatically cleaned on system restart
    - **Owner**: `eric users` (application-managed)
    
    ### 📹 Surveillance Cache (/tmp/frigate-cache/)
    - **Purpose**: Frigate AI processing temporary files
    - **Usage**: Object detection model cache, frame processing
    - **Lifecycle**: Automatically cleaned based on disk usage
    - **Owner**: `eric users` (service-managed)
    
    ## System Logging (/var/log/)
    
    ### 📊 GPU Statistics (/var/log/gpu-stats/)
    - **Purpose**: GPU utilization and performance monitoring
    - **Content**: Temperature, memory usage, compute utilization
    - **Rotation**: Automatic log rotation to prevent disk fill
    - **Monitoring**: Integrated with system monitoring tools
    
    ### 💾 Storage Health (/var/log/ssd-health.log)
    - **Purpose**: SSD health monitoring and SMART data
    - **Content**: Wear leveling, temperature, error rates
    - **Critical**: Early warning system for drive failures
    - **Alerts**: Integrated with monitoring for proactive replacement
    
    ## High-Performance Database Storage (/mnt/hot/databases/)
    
    ### 🗄️ PostgreSQL (/mnt/hot/databases/postgresql/)
    - **Purpose**: Business application database storage
    - **Performance**: SSD storage for fast queries and transactions
    - **Backup**: Regular automated backups to cold storage
    - **Security**: SOPS-encrypted connection credentials
    
    ### 📊 *ARR Databases (/mnt/hot/databases/arr-databases/)
    - **Purpose**: Media management application databases
    - **Content**: Metadata, indexer data, quality profiles
    - **Performance**: Fast SSD access for media library operations
    - **Integration**: Linked with media processing workflows
    
    ## AI Model Storage (/mnt/hot/ai/)
    
    ### 🤖 Model Files (/mnt/hot/ai/models/)
    - **Purpose**: AI model weights and configuration files
    - **Performance**: SSD storage for fast model loading
    - **Content**: Ollama models, business intelligence models
    - **Size**: Large files requiring high-speed access
    
    ### ⚡ AI Cache (/mnt/hot/ai/cache/)
    - **Purpose**: AI inference cache and temporary processing
    - **Usage**: Model compilation cache, inference results
    - **Performance**: Ultra-fast access for real-time AI responses
    - **Cleanup**: Automatic cache management based on usage patterns
    
    ## Performance Considerations
    
    ### 🚀 Hot Storage Optimization
    - **SSD Placement**: Critical performance directories on NVMe SSD
    - **Cache Strategy**: Intelligent caching based on access patterns
    - **Lifecycle Management**: Automatic cleanup to prevent SSD wear
    
    ### 📈 Monitoring Integration
    - **Disk Usage**: Real-time monitoring of cache directory sizes
    - **Performance Metrics**: I/O patterns and response times
    - **Health Monitoring**: SSD health and performance degradation
    
    ## Maintenance and Cleanup
    
    ### 🧹 Automated Cleanup
    ```bash
    # GPU cache cleanup (automatic on restart)
    # Frigate cache cleanup (based on disk usage)
    # AI cache cleanup (LRU eviction)
    ```
    
    ### 📋 Manual Maintenance
    ```bash
    # Check SSD health
    sudo smartctl -a /dev/nvme0n1
    
    # Monitor cache usage
    du -sh /tmp/*cache /mnt/hot/*/cache
    
    # Database maintenance
    sudo -u postgres vacuumdb --all --analyze
    ```
    
    ## Integration Points
    
    ### 🔗 Service Integration
    - **GPU Services**: CUDA cache for AI and video processing
    - **Database Services**: PostgreSQL and application databases
    - **AI Services**: Model storage for Ollama and business AI
    - **Monitoring**: System health and performance monitoring
    
    ### 📊 Monitoring Tools
    - **GPU Monitoring**: nvidia-smi, nvtop integration
    - **Storage Monitoring**: SMART data, disk usage alerts
    - **Database Monitoring**: PostgreSQL performance metrics
    - **AI Monitoring**: Model loading times, inference performance
    
    ## Security and Backup
    
    ### 🔒 Security Considerations
    - **Cache Directories**: User-owned for application access
    - **System Logs**: Root-owned for system security
    - **Database Storage**: User-owned with encrypted connections
    
    ### 💾 Backup Strategy
    - **Temporary Directories**: No backup needed (recreatable)
    - **System Logs**: Regular rotation and archival
    - **Database Storage**: Automated backups to cold storage
    - **AI Models**: Backup of custom-trained models only
  '';
}