# shared/home-manager/development.nix  
# Development tools, programming languages, and version control
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Programming languages
    python3              # Python interpreter
    python3Packages.pip  # Python package manager
    python3Packages.virtualenv # Python virtual environments
    nodejs               # Node.js runtime
    
    # Development tools
    gh                   # GitHub CLI
    wireguard-tools      # VPN configuration tools
    
    # Version control (additional tools)
    git-lfs             # Git Large File Storage
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "eric";
    userEmail = "eriqueo@proton.me";

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "micro";
      pull.rebase = false;
      push.default = "simple";
      
      # Better diffs and merging
      diff.tool = "meld";
      merge.tool = "meld";
      
      # Performance improvements
      core.preloadindex = true;
      core.fscache = true;
      gc.auto = 256;
      
      # Security
      transfer.fsckobjects = true;
      fetch.fsckobjects = true;
      receive.fsckObjects = true;
    };

    aliases = {
      # Basic shortcuts
      st = "status -sb";
      co = "checkout";
      br = "branch";
      ci = "commit";
      
      # Enhanced log views
      lg = "log --oneline --graph --decorate --all";
      ll = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      
      # Workflow shortcuts  
      aa = "add .";
      cm = "commit -m";
      pu = "push";
      pl = "pull";
      
      # Advanced operations
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
      
      # Cleanup operations
      cleanup = "!git branch --merged | grep -v '\\*\\|master\\|main' | xargs -n 1 git branch -d";
      prune-branches = "remote prune origin";
    };
    
    # Git ignore patterns
    ignores = [
      # OS generated files
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"
      
      # Editor files
      "*~"
      "*.swp"
      "*.swo"
      ".vscode/"
      ".idea/"
      
      # Build artifacts
      "node_modules/"
      "dist/"
      "build/"
      "*.log"
      ".env"
      ".env.local"
      
      # Python
      "__pycache__/"
      "*.pyc"
      "*.pyo"
      "*.pyd"
      ".Python"
      "env/"
      "venv/"
      ".venv/"
      
      # NixOS
      "result"
      "result-*"
    ];
  };

  # Environment variables for development
  home.sessionVariables = {
    # Default editors
    EDITOR = "micro";
    VISUAL = "micro";
    
    # Development directories
    PROJECTS = "$HOME/workspace/projects";
    SCRIPTS = "$HOME/workspace/scripts";
    DOTFILES = "$HOME/workspace/dotfiles";
    
    # Python development
    PYTHONDONTWRITEBYTECODE = "1";
    PYTHONUNBUFFERED = "1";
    PIP_USER = "1";
    
    # Node.js development  
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    
    # Add user package directories to PATH
    PATH = "$HOME/.local/bin:$HOME/.npm-global/bin:$PATH";
  };

  # Create development directory structure
  home.file = {
    "workspace/projects/.keep".text = "Development projects directory";
    "workspace/scripts/.keep".text = "Custom automation scripts directory";  
    "workspace/dotfiles/.keep".text = "Configuration backups and dotfiles directory";
    ".local/bin/.keep".text = "User-local executables directory";
  };
}