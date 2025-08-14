# modules/paths/default.nix
# Centralized path configuration for Heartwood Craft NixOS system
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.heartwood.paths;
in
{
  ####################################################################
  # PATH CONFIGURATION OPTIONS
  ####################################################################
  options.heartwood.paths = {
    # User directories
    userHome = mkOption {
      type = types.str;
      default = config.users.users.eric.home;
      description = "User home directory path";
      example = "/home/eric";
    };
    
    userTempDir = mkOption {
      type = types.str;
      default = "${cfg.userHome}/99-temp";
      description = "User temporary workspace directory";
    };
    
    userSshDir = mkOption {
      type = types.str;
      default = "${cfg.userHome}/.ssh";
      description = "User SSH configuration directory";
    };
    
    userDevDir = mkOption {
      type = types.str;
      default = "${cfg.userHome}/dev";
      description = "User development workspace";
    };

    # Storage directories
    hotStorage = mkOption {
      type = types.str;
      default = "/mnt/hot";
      description = "High-performance SSD storage mount point";
    };
    
    coldStorage = mkOption {
      type = types.str;
      default = "/mnt/media";
      description = "Large capacity HDD storage mount point";
    };
    
    # Application root directories
    businessRoot = mkOption {
      type = types.str;
      default = "/opt/business";
      description = "Business applications root directory";
    };
    
    surveillanceRoot = mkOption {
      type = types.str;
      default = "/opt/surveillance";
      description = "Surveillance applications root directory";
    };
    
    aiRoot = mkOption {
      type = types.str;
      default = "/opt/ai";
      description = "AI/ML applications root directory";
    };
    
    adhdToolsRoot = mkOption {
      type = types.str;
      default = "/opt/adhd-tools";
      description = "ADHD productivity tools root directory";
    };
    
    # Security directories
    secretsDir = mkOption {
      type = types.str;
      default = "/etc/secrets";
      description = "System secrets directory";
    };
    
    sopsAgeKeyFile = mkOption {
      type = types.str;
      default = "/etc/sops/age/keys.txt";
      description = "SOPS age private key file location";
    };
    
    # System directories
    nixosConfigDir = mkOption {
      type = types.str;
      default = "/etc/nixos";
      description = "NixOS configuration directory";
    };
    
    # Backup directories
    backupRoot = mkOption {
      type = types.str;
      default = "${cfg.businessRoot}/backups";
      description = "System backups root directory";
    };
    
    # Logging directories
    logDir = mkOption {
      type = types.str;
      default = "/var/log";
      description = "System log directory";
    };
    
    # Temporary directories
    tempDir = mkOption {
      type = types.str;
      default = "/tmp";
      description = "System temporary directory";
    };
  };

  ####################################################################
  # DERIVED PATH CONFIGURATIONS
  ####################################################################
  config = {
    # Export paths as environment variables for scripts
    environment.sessionVariables = {
      HEARTWOOD_USER_HOME = cfg.userHome;
      HEARTWOOD_USER_TEMP = cfg.userTempDir;
      HEARTWOOD_USER_SSH = cfg.userSshDir;
      HEARTWOOD_USER_DEV = cfg.userDevDir;
      HEARTWOOD_HOT_STORAGE = cfg.hotStorage;
      HEARTWOOD_COLD_STORAGE = cfg.coldStorage;
      HEARTWOOD_BUSINESS_ROOT = cfg.businessRoot;
      HEARTWOOD_SURVEILLANCE_ROOT = cfg.surveillanceRoot;
      HEARTWOOD_AI_ROOT = cfg.aiRoot;
      HEARTWOOD_ADHD_TOOLS_ROOT = cfg.adhdToolsRoot;
      HEARTWOOD_SECRETS_DIR = cfg.secretsDir;
      HEARTWOOD_SOPS_AGE_KEY = cfg.sopsAgeKeyFile;
      HEARTWOOD_NIXOS_CONFIG = cfg.nixosConfigDir;
      HEARTWOOD_BACKUP_ROOT = cfg.backupRoot;
      HEARTWOOD_LOG_DIR = cfg.logDir;
      HEARTWOOD_TEMP_DIR = cfg.tempDir;
    };
    
    # Create documentation about the path structure
    environment.etc."heartwood-paths.md".text = ''
      # Heartwood Craft Path Configuration
      
      This system uses centralized path management through the `heartwood.paths` configuration.
      All paths are configurable and can be overridden in host-specific configurations.
      
      ## User Directories
      - **Home**: `${cfg.userHome}`
      - **Temporary**: `${cfg.userTempDir}`
      - **SSH Config**: `${cfg.userSshDir}`
      - **Development**: `${cfg.userDevDir}`
      
      ## Storage Tiers
      - **Hot Storage (SSD)**: `${cfg.hotStorage}`
      - **Cold Storage (HDD)**: `${cfg.coldStorage}`
      
      ## Application Roots
      - **Business Intelligence**: `${cfg.businessRoot}`
      - **Surveillance System**: `${cfg.surveillanceRoot}`
      - **AI/ML Services**: `${cfg.aiRoot}`
      - **ADHD Tools**: `${cfg.adhdToolsRoot}`
      
      ## Security & Configuration
      - **Secrets**: `${cfg.secretsDir}`
      - **SOPS Age Key**: `${cfg.sopsAgeKeyFile}`
      - **NixOS Config**: `${cfg.nixosConfigDir}`
      
      ## System Directories
      - **Backups**: `${cfg.backupRoot}`
      - **Logs**: `${cfg.logDir}`
      - **Temporary**: `${cfg.tempDir}`
      
      ## Environment Variables
      
      All paths are also available as environment variables with the `HEARTWOOD_` prefix:
      - `HEARTWOOD_USER_HOME`
      - `HEARTWOOD_HOT_STORAGE`
      - `HEARTWOOD_BUSINESS_ROOT`
      - etc.
      
      ## Usage in Scripts
      
      Instead of hardcoding paths, use environment variables:
      ```bash
      # Bad
      cd /home/eric/99-temp
      
      # Good
      cd "$HEARTWOOD_USER_TEMP"
      ```
      
      ## Usage in Nix Expressions
      
      Access paths through the configuration:
      ```nix
      # Access in other modules
      config.heartwood.paths.userHome
      config.heartwood.paths.hotStorage
      
      # Override in host configuration
      heartwood.paths.hotStorage = "/custom/ssd/mount";
      ```
    '';
  };
}