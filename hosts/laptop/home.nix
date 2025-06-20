# -----------------------------------------------------------------------------
# FILE: hosts/laptop/home.nix (ORCHESTRATOR)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, osConfig, ... }:
{
  imports = [
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/waybar.nix
    ../../modules/home-manager/theming.nix
    ../../modules/home-manager/startup.nix
    ../../modules/home-manager/apps.nix
  ];

  # IDENTITY
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  # STANDARDIZED DIRECTORY STRUCTURE
  home.file = {
    # Documents structure
    "Documents/00-templates/.keep".text = "Templates and forms directory";
    "Documents/01-vaults/.keep".text = "Obsidian vaults directory";  
    "Documents/02-active/.keep".text = "Current projects directory";
    "Documents/03-business/.keep".text = "Admin and business docs directory";
    "Documents/04-reference/.keep".text = "Manuals and guides directory";
    "Documents/05-archive/.keep".text = "Completed projects directory";
    "Documents/99-inbox/.keep".text = "Unsorted documents to be processed";

    # Pictures structure  
    "Pictures/00-meta/.keep".text = "Icons, wallpapers, templates";
    "Pictures/01-screenshots/.keep".text = "Work captures and system docs";
    "Pictures/02-receipts/.keep".text = "Business receipts (syncs to server)";
    "Pictures/03-projects/.keep".text = "Jobsite photos and documentation";
    "Pictures/04-reference/.keep".text = "Documentation photos and examples";
    "Pictures/05-archive/.keep".text = "Family photos and old projects";
    "Pictures/99-inbox/.keep".text = "Unsorted photos to be processed";

    # Business directory (future server mount point)
    "Business/.keep".text = "Future mount point to server /opt/business/";

    # README for the directory philosophy
    "Documents/00-templates/README.md".text = ''
      # Directory Organization Philosophy
      
      ## Numbering System (00-05 + 99)
      - **00**: Templates, meta, overview materials
      - **01**: Primary category (vaults, screenshots, etc.)
      - **02**: Secondary category (active work, receipts, etc.) 
      - **03**: Tertiary category (business, projects, etc.)
      - **04**: Quaternary category (reference materials)
      - **05**: Archive (completed, historical)
      - **99**: Inbox (unsorted, to be processed)
      
      ## Rule of 7
      Maximum 7 folders per directory. If you need more:
      1. Combine similar items into subdirectories
      2. Rename categories to be more inclusive
      3. Archive old items to 05-archive
      
      ## Server Integration
      This structure mirrors future server organization for:
      - Database file references
      - Automated processing workflows  
      - Cross-device synchronization
    '';
  };

  # SHELL CONFIGURATION
  # In hosts/laptop/home.nix
programs.zsh = {
  enable = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  
  shellAliases = {
    # File management with modern tools
    "ls" = "eza --tree --level=1";
    "ll" = "eza -l --git --icons";
    "la" = "eza -la --git --icons";
    "lt" = "eza --tree --level=2";
    
    # Navigation shortcuts
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    
    # Quick directory navigation (laptop-specific)
    "cdactive" = "cd ~/Documents/02-active";
    "cdbusiness" = "cd ~/Documents/03-business";
    "cdinbox" = "cd ~/Documents/99-inbox";
    "cdvaults" = "cd ~/Documents/01-vaults";
    "screenshots" = "cd ~/Pictures/01-screenshots";
    "receipts" = "cd ~/Pictures/02-receipts";
    "projects" = "cd ~/Pictures/03-projects";
    
    # System utilities
    "df" = "df -h";
    "du" = "du -h";
    "free" = "free -h";
    "htop" = "btop --tree";
    "open" = "xdg-open";
    
    # Git workflow shortcuts
    "gs" = "git status -sb";
    "ga" = "git add .";
    "gc" = "git commit -m";
    "gp" = "git push";
    "gl" = "git log --oneline --graph --decorate --all";
    "gpl" = "git pull";
    
    # NixOS system management
    "nixflake" = "sudo micro /etc/nixos/flake.nix";
    "nixlaphome" = "sudo micro /etc/nixos/hosts/laptop/home.nix";
    "nixlapcon" = "sudo micro /etc/nixos/hosts/laptop/config.nix";
    "nixserverhome" = "sudo micro /etc/nixos/hosts/server/home.nix";
    "nixservercon" = "sudo micro /etc/nixos/hosts/server/config.nix";
    "nixsecrets" = "sudo micro /etc/nixos/modules/secrets/secrets.nix";
    "nixsearch" = "nix search nixpkgs";
    "nixclean" = "nix-collect-garbage -d";
    "nixgen" = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    
    # Development and productivity
    "speedtest" = "speedtest-cli";
    "myip" = "curl -s ifconfig.me";
    "reload" = "source ~/.zshrc";
    
    # Host-specific rebuild
    "rebuild" = "sudo nixos-rebuild switch --flake /etc/nixos#heartwood-laptop";
  };
  
  # Shell functions
  initExtra = ''
    # ADHD-friendly productivity functions
    mkcd() { mkdir -p "$1" && cd "$1" }
            
    # Quick search and replace
    sr() {
      (( $# != 3 )) && { echo "Usage: sr <search> <replace> <file>"; return 1; }
      sed -i "s/$1/$2/g" "$3"
    }
    
    # Fuzzy directory navigation
    fd() {
      local dir
      dir=$(find . -type d 2>/dev/null | fzf --preview 'ls -la {}') && cd "$dir"
    }
    
    # Git branch switching with fuzzy search
    fgb() {
      local branch
      branch=$(git branch -a | fzf --preview 'git log --oneline --graph --color=always {1}') && git checkout "''${branch##* }"
    }
    
    # Hostname-aware grebuild function
    grebuild() {
        local commit_msg="$1"
        [[ -z "$commit_msg" ]] && { echo "Usage: grebuild 'commit message'"; return 1; }
        
        cd /etc/nixos || return 1
        sudo git add .
        sudo git commit -m "$commit_msg"
        sudo git push
        
        case $(hostname) in
          "heartwood-laptop")
            sudo nixos-rebuild switch --flake .#heartwood-laptop
            ;;
          "homeserver")
            sudo nixos-rebuild switch --flake .#homeserver  
            ;;
          *)
            echo "Unknown hostname: $(hostname)"
            return 1
            ;;
        esac
      }
      
      # Test-only version
      gtest() {
        local commit_msg="$1"
        [[ -z "$commit_msg" ]] && { echo "Usage: gtest 'commit message'"; return 1; }
        
        cd /etc/nixos || return 1
        sudo git add .
        sudo git commit -m "$commit_msg"
        
        case $(hostname) in
          "heartwood-laptop")
            sudo nixos-rebuild test --flake .#heartwood-laptop
            ;;
          "homeserver")
            sudo nixos-rebuild test --flake .#homeserver
            ;;
        esac
      }
      
      # Quick system status check
      status() {
        echo "🖥️  System Status Overview"
        echo "=========================="
        echo "💾 Memory: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')"
        echo "💽 Disk: $(df -h / | awk 'NR==2{print $5}')"
        echo "🔥 Load: $(uptime | awk -F'load average:' '{print $2}')"
      }
    '';

    
  };
}