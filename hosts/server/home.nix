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
  #now in shared/zsh-config.nix

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
