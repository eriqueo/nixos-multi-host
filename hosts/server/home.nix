# -----------------------------------------------------------------------------
# SERVER HOME MANAGER CONFIGURATION - Heartwood Craft Homeserver
# User-level configuration for business intelligence and server management
# Focused on CLI productivity, ADHD tools, and business automation
# -----------------------------------------------------------------------------
{ config, pkgs, ... }:

{
  ####################################################################
  # 1. HOME MANAGER IDENTITY
  ####################################################################
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "25.11";

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  ####################################################################
  # 2. CORE CLI PACKAGES
  ####################################################################
  home.packages = with pkgs; [
    # Enhanced CLI replacements
    bat           # Better cat with syntax highlighting
    eza           # Modern ls replacement with git integration
    fzf           # Fuzzy finder for files and commands
    ripgrep       # Fast grep replacement
    btop          # Modern system monitor (replaces htop)
    tree          # Directory tree visualization
    tmux          # Terminal multiplexer for session management
    neofetch      # System information display
    micro         # Modern terminal text editor

    # Development tools
    python3
    python3Packages.pip
    python3Packages.virtualenv
    nodejs

    # Network and file management
    curl
    wget
    rsync
    rclone        # Cloud storage sync
    gh            # GitHub CLI
    speedtest-cli
    nmap          # Network scanning
    wireguard-tools

    # Text and data processing
    jq            # JSON processor
    yq            # YAML processor  
    pandoc        # Document converter

    # Archive tools
    zip
    unzip
    p7zip

    # System utilities
    xclip         # Clipboard utility for X11 forwarding

    # Business applications
    obsidian      # Note-taking for business documentation

    # Productivity tools
    espanso       # Text expansion for ADHD-friendly workflows
  ];

  ####################################################################
  # 3. ENVIRONMENT VARIABLES
  ####################################################################
  home.sessionVariables = {
    # Default editors
    EDITOR = "micro";
    VISUAL = "micro";

    # Workspace organization
    PROJECTS = "$HOME/workspace/projects";
    SCRIPTS = "$HOME/workspace/scripts";
    DOTFILES = "$HOME/workspace/dotfiles";

    # Business intelligence URLs
    BUSINESS_API_URL = "http://localhost:8000";
    OLLAMA_API_URL = "http://localhost:11434";
    DATABASE_URL = "postgresql://business_user:secure_password_change_me@localhost:5432/heartwood_business";
  };

  ####################################################################
  # 4. WORKSPACE DIRECTORY STRUCTURE
  ####################################################################
  home.file = {
    "workspace/projects/.keep".text = "Business and development projects directory";
    "workspace/scripts/.keep".text = "Custom automation scripts directory";
    "workspace/dotfiles/.keep".text = "Configuration backups and dotfiles directory";
  };

  ####################################################################
  # 5. ZSH CONFIGURATION
  ####################################################################
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # History configuration
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    ####################################################################
    # 6. SHELL ALIASES
    ####################################################################
    shellAliases = {
      # File management with modern tools
      "ls" = "eza";
      "ll" = "eza -l --git --icons";
      "la" = "eza -la --git --icons";
      "lt" = "eza --tree --level=2";

      # Navigation shortcuts
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # System utilities
      "df" = "df -h";
      "du" = "du -h";
      "free" = "free -h";
      # Note: grep = rg commented out to avoid conflicts

      # Git shortcuts for configuration management
      "gs" = "sudo git status -sb";
      "ga" = "sudo git add .";
      "gc" = "sudo git commit -m";
      "gp" = "sudo git push";
      "gl" = "sudo git log --oneline --graph --decorate --all";
      "gpl" = "sudo git pull";

      # NixOS system management
      "nixconfig" = "sudo micro /etc/nixos/configuration.nix";
      "nixhome" = "sudo micro /etc/nixos/home.nix";
      "nixrebuild" = "sudo nixos-rebuild switch --flake /etc/nixos";
      "nixtest" = "sudo nixos-rebuild test --flake /etc/nixos";
      "nixsearch" = "nix search nixpkgs";
      "nixclean" = "nix-collect-garbage -d";
      "nixcameras" = "sudo micro /etc/nixos/modules/surveillance.nix";

      # Media server navigation
      "media" = "cd /mnt/media";
      "tv" = "cd /mnt/media/tv";
      "movies" = "cd /mnt/media/movies";

      # Development and testing
      "speedtest" = "speedtest-cli";

      # AI and business intelligence
      "ai-chat" = "ollama run llama3.2:3b";
      "business-dev" = "cd /opt/business && source /etc/business/setup-dev-env.sh";
      "context-snap" = "python3 /opt/adhd-tools/scripts/context-snapshot.py";
      "energy-log" = "python3 /etc/adhd-tools/energy-tracker.py";

      # Business workflow automation
      "receipt-process" = "cd /opt/business/receipts && python3 ../api/services/ocr_processor.py";
      "cost-dashboard" = "cd /opt/business/dashboard && streamlit run dashboard.py";
      "jobtread-sync" = "cd /opt/business/api && python3 services/jobtread_sync.py";
      "business-db" = "psql \"$DATABASE_URL\"";

      # ADHD productivity tools
      "focus-mode" = "systemctl --user start context-monitor";
      "focus-off" = "systemctl --user stop context-monitor";
      "work-stats" = "python3 /opt/adhd-tools/scripts/productivity-analysis.py";

      # Surveillance system shortcuts
      "cameras" = "echo 'Frigate: http://100.110.68.48:5000'";
      "home-assistant" = "echo 'Home Assistant: http://100.110.68.48:8123'";
      "frigate-logs" = "sudo podman logs -f frigate";
      "ha-logs" = "sudo podman logs -f home-assistant";
    };

    ####################################################################
    # 7. CUSTOM ZSH FUNCTIONS
    ####################################################################
    initContent = ''
      # Enhanced NixOS git rebuild function with safety checks
      grebuild() {
        if [[ -z "$1" ]]; then
          echo "Usage: grebuild <commit message>"
          echo "       grebuild --test <commit message>  (test only, no switch)"
          echo "Example: grebuild added Jellyfin port to firewall"
          return 1
        fi
        
        # Check for test mode
        local test_mode=false
        if [[ "$1" == "--test" ]]; then
          test_mode=true
          shift
          if [[ -z "$1" ]]; then
            echo "❌ Commit message required even in test mode"
            return 1
          fi
        fi
        
        # Save current directory
        local original_dir="$PWD"
        
        # Change to NixOS config directory
        cd /etc/nixos || {
          echo "❌ Could not access /etc/nixos directory"
          return 1
        }
        
        echo "📁 Working in: /etc/nixos"
        
        # Git operations must all succeed for flakes to work
        echo "📝 Adding changes..."
        if ! sudo git add .; then
          echo "❌ Git add failed - cannot proceed with flake rebuild"
          cd "$original_dir"
          return 1
        fi
        
        echo "💾 Committing: $*"
        if ! sudo git commit -m "$*"; then
          echo "❌ Git commit failed - cannot proceed with flake rebuild"
          cd "$original_dir"
          return 1
        fi
        
        echo "☁️  Pushing to remote..."
        if ! sudo -E git push; then
          echo "❌ Git push failed - flake rebuild requires synced git state"
          echo "🚫 Aborting rebuild - fix git issues first"
          cd "$original_dir"
          return 1
        fi
        
        # Test build first
        echo "🧪 Testing NixOS configuration..."
        local hostname=$(hostname)
        if [[ -f flake.nix ]]; then
          if ! sudo nixos-rebuild test --flake .#"$hostname"; then
            echo "❌ NixOS test build failed - configuration has errors!"
            cd "$original_dir"
            return 1
          fi
        else
          if ! sudo nixos-rebuild test; then
            echo "❌ NixOS test build failed - configuration has errors!"
            cd "$original_dir"
            return 1
          fi
        fi
        
        if [[ "$test_mode" == true ]]; then
          echo "✅ Test mode complete! Configuration is valid."
          cd "$original_dir"
          return 0
        fi
        
        # Switch to new configuration
        echo "🔄 Test passed! Switching to new configuration..."
        if [[ -f flake.nix ]]; then
          if ! sudo nixos-rebuild switch --flake .#"$hostname"; then
            echo "❌ NixOS switch failed"
            cd "$original_dir"
            return 1
          fi
        else
          if ! sudo nixos-rebuild switch; then
            echo "❌ NixOS switch failed"
            cd "$original_dir"
            return 1
          fi
        fi
        
        echo "✅ Complete! System rebuilt and switched with: $*"
        cd "$original_dir"
      }
      
      # Quick test-only function
      gtest() {
        grebuild --test "$@"
      }
      
      # ADHD-friendly productivity functions
      mkcd() { 
        mkdir -p "$1" && cd "$1" 
      }
      
      # Universal archive extraction
      extract() {
        if [[ -f "$1" ]]; then
          case "$1" in
            *.tar.gz)  tar -xzf "$1" ;;
            *.tar.xz)  tar -xJf "$1" ;;
            *.tar.bz2) tar -xjf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.rar)     unrar x "$1" ;;
            *)         echo "'$1' cannot be extracted" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
      
      # Quick search and replace in files
      sr() {
        (( $# != 3 )) && { echo "Usage: sr <search> <replace> <file>"; return 1; }
        sed -i "s/$1/$2/g" "$3"
      }
      
      # Fuzzy directory navigation
      fd() {
        local dir
        dir=$(find . -type d 2>/dev/null | fzf) && cd "$dir"
      }
      
      # Business project context switching
      project() {
        if [ -z "$1" ]; then
          echo "Available projects:"
          ls -la ~/workspace/projects/
        else
          cd ~/workspace/projects/$1 2>/dev/null || echo "Project $1 not found"
        fi
      }
    '';
  };

  ####################################################################
  # 8. GIT CONFIGURATION
  ####################################################################
  programs.git = {
    enable = true;
    userName = "eric";
    userEmail = "eriqueo@proton.me";

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "micro";
      pull.rebase = false;
      push.default = "simple";
    };

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --oneline --graph --decorate --all";
    };
  };

  ####################################################################
  # 9. FZF FUZZY FINDER CONFIGURATION
  ####################################################################
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "find . -type f";
    defaultOptions = [ "--height 40%" "--reverse" ];
  };
}