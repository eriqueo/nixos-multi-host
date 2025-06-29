# modules/users/eric.nix - Consolidated User Configuration
# This module contains all user-related configuration for Eric across all hosts
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # MAIN USER DEFINITION
  ####################################################################
  users.users.eric = {
    isNormalUser = true;
    home = "/home/eric";
    description = "Eric - Heartwood Craft";
    shell = pkgs.zsh;
    
    # System groups and permissions
    extraGroups = [ 
      "wheel"          # sudo access
      "networkmanager" # network configuration
      "video"          # graphics access  
      "audio"          # sound access
      "docker"         # container management
      "podman"         # alternative container runtime
    ];
    
    # SSH authentication
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQFHXbcZCYrqyJoRPJddpEpnEquRJUxtopQkZsZdGhl hwc@laptop"
    ];
    
    # Initial password - TODO: Consider moving to SOPS secrets
    initialPassword = "il0wwlm?";
  };

  ####################################################################
  # FILE SYSTEM PERMISSIONS & USER DIRECTORY STRUCTURE
  ####################################################################

  ####################################################################
  # ZSH SYSTEM CONFIGURATION
  ####################################################################
  # Enable ZSH system-wide
  programs.zsh.enable = true;

  ####################################################################
  # USER-SPECIFIC SYSTEM PACKAGES & HELPER SCRIPTS
  ####################################################################
  # Core packages and user-specific helper scripts
  environment.systemPackages = with pkgs; [
    # Core development tools
    git
    micro
    neovim
    
    # System monitoring and utilities
    htop
    btop
    tree
    neofetch
    
    # Network tools
    wget
    curl
    
    # File management
    unzip
    zip
    p7zip
    rsync
    
    # Enhanced CLI tools
    bat          # better cat
    eza          # better ls
    fzf          # fuzzy finder
    ripgrep      # better grep
    
    # Development languages
    python3
    python3Packages.pip
    nodejs
    
    # Security and secrets management
    sops
    age
    ssh-to-age
    
    # Terminal multiplexer
    tmux
    
    # JSON/YAML processing
    jq
    yq
    
    # System information
    usbutils
    pciutils
    dmidecode
    
    # Version control
    gh           # GitHub CLI
  ] ++ [
    # User-specific helper scripts
    (writeScriptBin "user-info" ''
      #!/bin/bash
      echo "👤 User Configuration Information"
      echo "================================"
      echo "User: eric"
      echo "Home: /home/eric"
      echo "Shell: ${pkgs.zsh}/bin/zsh"
      echo "Groups: $(groups eric)"
      echo ""
      echo "🏠 Directory Structure:"
      ls -la /home/eric/ | grep "^d"
      echo ""
      echo "🔧 Configuration Files:"
      echo "  SSH Config: ~/.ssh/config"
      echo "  Git Config: ~/.gitconfig"
      echo "  ZSH Config: ~/.zshrc (managed by Home Manager)"
      echo ""
      echo "🔐 Security:"
      echo "  SSH Keys: $(ls -la /home/eric/.ssh/ 2>/dev/null | grep -E '\.(pub|key)$' || echo 'None found')"
      echo "  Sudo Access: $(sudo -l -U eric 2>/dev/null | grep -q NOPASSWD && echo 'Enabled' || echo 'Standard')"
    '')

    (writeScriptBin "user-maintenance" ''
      #!/bin/bash
      echo "🔧 User Maintenance Tasks"
      echo "========================"
      echo ""
      echo "Cleaning up temporary files..."
      rm -rf /home/eric/99-temp/*
      
      echo "Updating user directory permissions..."
      chown -R eric:users /home/eric/
      chmod 755 /home/eric/
      chmod 700 /home/eric/.ssh/
      
      echo "Checking disk usage..."
      du -sh /home/eric/
      
      echo "✅ User maintenance completed"
    '')
  ];

  ####################################################################
  # BUSINESS-SPECIFIC CONFIGURATION
  ####################################################################
  # Environment variables for business intelligence systems
  environment.sessionVariables = {
    # Business API endpoints (server-specific, but defined here for consistency)
    BUSINESS_API_URL = "http://localhost:8000";
    DASHBOARD_URL = "http://localhost:8501";
    
    # Development environment
    EDITOR = "micro";
    BROWSER = "firefox";
  };

  ####################################################################
  # SSH CLIENT CONFIGURATION
  ####################################################################
  # SSH client configuration via environment file
  environment.etc."ssh/ssh_config".text = ''
    # Heartwood Craft server connection
    Host homeserver
      HostName heartwood.ocelot-wahoo.ts.net
      User eric
      IdentityFile ~/.ssh/id_ed25519
      ForwardX11 yes
      ForwardX11Trusted yes
    
    # Local server connection
    Host local-server
      HostName 192.168.1.100
      User eric
      IdentityFile ~/.ssh/id_ed25519
  '';

  ####################################################################
  # GIT GLOBAL CONFIGURATION
  ####################################################################
  # System-wide git configuration for the user
  environment.etc."gitconfig".text = ''
    [user]
      name = eric
      email = eriqueo@proton.me
    
    [init]
      defaultBranch = main
    
    [pull]
      rebase = false
    
    [core]
      editor = micro
    
    [alias]
      st = status
      co = checkout
      br = branch
      ci = commit
      ca = commit -a
      cm = commit -m
      cam = commit -am
      unstage = reset HEAD --
      last = log -1 HEAD
      visual = !gitk
      tree = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
  '';

  # File permissions and directory structure now handled by modules/filesystem

  ####################################################################
  # SECURITY CONFIGURATION
  ####################################################################
  # Additional security settings for the user
  security.sudo.extraRules = [
    {
      users = [ "eric" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ]; # For development convenience - consider removing in production
        }
      ];
    }
  ];

  ####################################################################
  # USER-SPECIFIC SERVICES
  ####################################################################
  # Services that should run for this user specifically
  systemd.user.services = {
    # User environment setup service
    user-environment-setup = {
      description = "Setup user environment for Eric";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "user-setup" ''
          # Ensure proper permissions on user directories
          chmod 700 /home/eric/.ssh
          
          # Create any missing standard files
          touch /home/eric/.zsh_history
          chmod 600 /home/eric/.zsh_history
          
          # Set up git configuration if not exists
          if [ ! -f /home/eric/.gitconfig ]; then
            ln -sf /etc/gitconfig /home/eric/.gitconfig
          fi
        '';
      };
    };
  };

  ####################################################################
  # BACKUP AND MAINTENANCE
  ####################################################################
  # User-specific backup configuration
  systemd.services.user-backup = {
    description = "Backup user data for Eric";
    serviceConfig = {
      Type = "oneshot";
      User = "eric";
      ExecStart = pkgs.writeShellScript "user-backup" ''
        BACKUP_DIR="/opt/business/backups/user"
        DATE=$(date +%Y%m%d_%H%M%S)
        
        mkdir -p "$BACKUP_DIR"
        
        # Backup important user directories
        tar -czf "$BACKUP_DIR/eric_home_$DATE.tar.gz" \
          --exclude='.cache' \
          --exclude='.local/share/Trash' \
          --exclude='99-temp' \
          /home/eric/
        
        # Keep only last 30 days of backups
        find "$BACKUP_DIR" -name "eric_home_*.tar.gz" -mtime +30 -delete
        
        echo "User backup completed: $BACKUP_DIR/eric_home_$DATE.tar.gz"
      '';
    };
  };

  # Schedule weekly user backups
  systemd.timers.user-backup = {
    description = "Weekly user backup for Eric";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  ####################################################################
  # DOCUMENTATION AND HELPERS
  ####################################################################
  # Helper scripts are now included in the main systemPackages above
}