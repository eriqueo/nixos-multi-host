# shared/zsh-config.nix - Complete ZSH configuration for all hosts
# Contains both common and host-specific aliases/functions for simplicity
{ config, pkgs, lib, ... }:

{
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
      
      # System utilities
      "df" = "df -h";
      "du" = "du -h";
      "free" = "free -h";
      "htop" = "btop --tree";
      "grep" = "rg";
      "open" = "xdg-open";
      
      # Git workflow shortcuts
      "gs" = "git status -sb";
      "ga" = "git add .";
      "gc" = "git commit -m";
      "gp" = "git push";
      "gl" = "git log --oneline --graph --decorate --all";
      "gpl" = "git pull";
      
      # Git sync aliases
      "gresync" = "cd /etc/nixos && sudo git fetch origin && sudo git pull origin master && echo '✅ Git sync complete!'";
      "gstatus" = "cd /etc/nixos && sudo git status";
      "glog" = "cd /etc/nixos && sudo git log --oneline -10";
      
      # NixOS system management
      "nixcon" = "sudo micro /etc/nixos/configuration.nix";
      "nixflake" = "sudo micro /etc/nixos/flake.nix";
      "nixlaphome" = "sudo micro /etc/nixos/hosts/laptop/home.nix";
      "nixlapcon" = "sudo micro /etc/nixos/hosts/laptop/config.nix";
      "nixserverhome" = "sudo micro /etc/nixos/hosts/server/home.nix";
      "nixservercon" = "sudo micro /etc/nixos/hosts/server/config.nix";
      "nixsecrets" = "sudo micro /etc/nixos/shared/secrets.nix";
      "nixsearch" = "nix search nixpkgs";
      "nixclean" = "nix-collect-garbage -d";
      "nixgen" = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      "nixcameras" = "sudo micro /etc/nixos/hosts/server/modules/surveillance.nix";
      
      # Development and productivity
      "speedtest" = "speedtest-cli";
      "myip" = "curl -s ifconfig.me";
      "reload" = "source ~/.zshrc";
      
      # SERVER-SPECIFIC ALIASES (safe to have on laptop)
      # Media server navigation
      "media" = "cd /mnt/media";
      "tv" = "cd /mnt/media/tv";
      "movies" = "cd /mnt/media/movies";
      
      # AI and business intelligence
      "ai-chat" = "ollama run llama3.2:3b";
      "business-dev" = "cd /opt/business && source /etc/business/setup-dev-env.sh";
      "context-snap" = "python3 /opt/adhd-tools/scripts/context-snapshot.py";
      "energy-log" = "python3 /etc/adhd-tools/energy-tracker.py";
      
      # Business workflow automation
      "receipt-process" = "cd /opt/business/receipts && python3 ../api/services/ocr_processor.py";
      "cost-dashboard" = "cd /opt/business/dashboard && streamlit run dashboard.py";
      "jobtread-sync" = "cd /opt/business/api && python3 services/jobtread_sync.py";
      "business-db" = "psql postgresql://business_user:secure_password_change_me@localhost:5432/heartwood_business";
      
      # ADHD productivity tools
      "focus-mode" = "systemctl --user start context-monitor";
      "focus-off" = "systemctl --user stop context-monitor";
      "work-stats" = "python3 /opt/adhd-tools/scripts/productivity-analysis.py";
      
      # Surveillance system shortcuts
      "cameras" = "echo 'Frigate: http://100.110.68.48:5000'";
      "home-assistant" = "echo 'Home Assistant: http://100.110.68.48:8123'";
      "frigate-logs" = "sudo podman logs -f frigate";
      "ha-logs" = "sudo podman logs -f home-assistant";
      
      # SSH shortcuts
      "homeserver" = "ssh eric@100.110.68.48";
      "server" = "ssh eric@100.110.68.48";
    };
    
    # Universal shell functions with enhanced grebuild
    interactiveShellInit = ''
      # Enhanced grebuild function with git sync
      grebuild() {
        if [[ -z "$1" ]]; then
          echo "Usage: grebuild <commit message>"
          echo "       grebuild --test <commit message>  (test only, no switch)"
          echo "       grebuild --sync  (sync only, no rebuild)"
          echo "Example: grebuild added Jellyfin port to firewall"
          return 1
        fi
        
        # Save current directory
        local original_dir="$PWD"
        
        # Change to NixOS config directory
        cd /etc/nixos || {
          echo "❌ Could not access /etc/nixos directory"
          return 1
        }
        
        echo "📁 Working in: /etc/nixos"
        
        # SYNC FIRST - Pull latest changes
        echo "🔄 Syncing with remote..."
        if ! sudo -E git fetch origin; then
          echo "❌ Git fetch failed"
          cd "$original_dir"
          return 1
        fi
        
        if ! sudo -E git pull origin master; then
          echo "❌ Git pull failed - resolve conflicts manually"
          cd "$original_dir"
          return 1
        fi
        
        # Handle sync-only mode
        if [[ "$1" == "--sync" ]]; then
          echo "✅ Git sync complete!"
          cd "$original_dir"
          return 0
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
        
        # Git operations
        echo "📝 Adding changes..."
        if ! sudo git add .; then
          echo "❌ Git add failed"
          cd "$original_dir"
          return 1
        fi
        
        echo "💾 Committing: $*"
        if ! sudo git commit -m "$*"; then
          echo "❌ Git commit failed"
          cd "$original_dir"
          return 1
        fi
        
        echo "☁️  Pushing to remote..."
        if ! sudo -E git push; then
          echo "❌ Git push failed"
          cd "$original_dir"
          return 1
        fi
        
        # Test build first
        echo "🧪 Testing NixOS configuration..."
        local hostname=$(hostname)
        if [[ -f flake.nix ]]; then
          if ! sudo nixos-rebuild test --flake .#"$hostname"; then
            echo "❌ NixOS test build failed!"
            cd "$original_dir"
            return 1
          fi
        else
          if ! sudo nixos-rebuild test; then
            echo "❌ NixOS test build failed!"
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
      
      update-containers() {
        echo “🔄 Forcing container image updates…”
        Clear container image cache to force fresh pulls
        sudo podman image prune -a -f
        Save current directory
        local original_dir=”$PWD”
        Change to NixOS config directory
        cd /etc/nixos || {
        echo “❌ Could not access /etc/nixos directory”
        return 1
        }
        echo “🔄 Rebuilding system with fresh container images…”
        local hostname=$(hostname)
        if ! sudo nixos-rebuild switch –flake .#”$hostname”; then
        echo “❌ NixOS rebuild failed”
        cd “$original_dir”
        return 1
        fi
        echo “✅ Container update complete! Fresh images pulled and services restarted.”
        cd “$original_dir”
      }
          
      # Test-only version
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
        dir=$(find . -type d 2>/dev/null | fzf --preview 'ls -la {}') && cd "$dir"
      }
      
      # Git branch switching with fuzzy search
      fgb() {
        local branch
        branch=$(git branch -a | fzf --preview 'git log --oneline --graph --color=always {1}') && git checkout "''${branch##* }"
      }
      
      # Business project context switching (safe to have on laptop)
      project() {
        if [ -z "$1" ]; then
          echo "Available projects:"
          ls -la ~/workspace/projects/ 2>/dev/null || echo "No projects directory found"
        else
          cd ~/workspace/projects/$1 2>/dev/null || echo "Project $1 not found"
        fi
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
