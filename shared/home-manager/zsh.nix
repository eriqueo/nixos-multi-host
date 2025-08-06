# shared/home-manager/zsh.nix - Shared ZSH configuration for Home Manager
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
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
      
      # Universal git = sudo git (consistent everywhere)
      "git" = "sudo git";
      
      # Git workflow shortcuts (all use sudo for consistency)
      "gs" = "sudo git status -sb";
      "ga" = "sudo git add .";
      "gc" = "sudo git commit -m";
      "gp" = "sudo git push";
      "gl" = "sudo git log --oneline --graph --decorate --all";
      "gpl" = "sudo git pull";
      
      # NixOS-specific git sync aliases
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
      "cameras" = "echo 'Frigate: http://100.115.126.41:5000'";
      "home-assistant" = "echo 'Home Assistant: http://100.115.126.41:8123'";
      "frigate-logs" = "sudo podman logs -f frigate";
      "ha-logs" = "sudo podman logs -f home-assistant";
      
      # SSH shortcuts
      "homeserver" = "ssh eric@100.115.126.41";
      "server" = "ssh eric@100.115.126.41";
    };
    
    # Environment variables
    sessionVariables = {
      LIBVIRT_DEFAULT_URI = "qemu:///system";
    };
    
    # Universal shell functions with enhanced grebuild  
    initContent = ''
      # Enhanced grebuild function with improved safety and multi-host sync
      grebuild() {
        if [[ -z "$1" ]]; then
          echo "Usage: grebuild <commit message>"
          echo "       grebuild --test <commit message>  (test only, no switch)"
          echo "       grebuild --sync  (sync only, no rebuild)"
          echo "Example: grebuild 'added Jellyfin port to firewall'"
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
        
        # Check for test mode
        local test_mode=false
        if [[ "$1" == "--test" ]]; then
          test_mode=true
          shift
          if [[ -z "$1" ]]; then
            echo "❌ Commit message required even in test mode"
            cd "$original_dir"
            return 1
          fi
        fi
        
        # Handle sync-only mode
        if [[ "$1" == "--sync" ]]; then
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
          echo "✅ Git sync complete!"
          cd "$original_dir"
          return 0
        fi
        
        # Check if tree is dirty
        if ! sudo git diff-index --quiet HEAD 2>/dev/null; then
          echo "📋 Detected local changes to commit"
          local has_changes=true
        else
          echo "✅ Working tree is clean"
          local has_changes=false
        fi
        
        # ENHANCED SYNC - Handle multi-host scenarios safely
        echo "🔄 Syncing with remote (safe multi-host sync)..."
        
        # Stash local changes if any exist
        local stash_created=false
        if [[ "$has_changes" == true ]]; then
          echo "💾 Stashing local changes for safe sync..."
          if sudo git stash push -m "grebuild-temp-$(date +%s)"; then
            stash_created=true
            echo "✅ Local changes stashed"
          else
            echo "❌ Failed to stash local changes"
            cd "$original_dir"
            return 1
          fi
        fi
        
        # Fetch and pull latest changes
        if ! sudo -E git fetch origin; then
          echo "❌ Git fetch failed"
          if [[ "$stash_created" == true ]]; then
            echo "🔄 Restoring stashed changes..."
            sudo git stash pop
          fi
          cd "$original_dir"
          return 1
        fi
        
        if ! sudo -E git pull origin master; then
          echo "❌ Git pull failed - resolve conflicts manually"
          if [[ "$stash_created" == true ]]; then
            echo "🔄 Restoring stashed changes..."
            sudo git stash pop
          fi
          cd "$original_dir"
          return 1
        fi
        
        # Restore local changes on top of pulled changes
        if [[ "$stash_created" == true ]]; then
          echo "🔄 Applying local changes on top of remote changes..."
          if ! sudo git stash pop; then
            echo "❌ Merge conflict applying local changes!"
            echo "💡 Resolve conflicts manually and run 'git stash drop' when done"
            cd "$original_dir"
            return 1
          fi
          echo "✅ Local changes applied successfully"
        fi
        
        # Add all changes (including any merged ones)
        echo "📝 Adding all changes..."
        if ! sudo git add .; then
          echo "❌ Git add failed"
          cd "$original_dir"
          return 1
        fi
        
        # IMPROVED FLOW: Test BEFORE committing
        echo "🧪 Testing configuration before committing..."
        local hostname=$(hostname)
        local test_success=false
        
        if [[ -f flake.nix ]]; then
          if sudo nixos-rebuild test --flake .#"$hostname"; then
            test_success=true
          fi
        else
          if sudo nixos-rebuild test; then
            test_success=true
          fi
        fi
        
        if [[ "$test_success" != true ]]; then
          echo "❌ NixOS test failed! No changes committed."
          echo "💡 Fix configuration issues and try again"
          cd "$original_dir"
          return 1
        fi
        
        echo "✅ Test passed! Configuration is valid."
        
        if [[ "$test_mode" == true ]]; then
          echo "✅ Test mode complete! Configuration is valid but not committed."
          cd "$original_dir"
          return 0
        fi
        
        # Only commit if test passed
        echo "💾 Committing tested changes: $*"
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
        
        # Switch to new configuration (already tested)
        echo "🔄 Switching to new configuration..."
        if [[ -f flake.nix ]]; then
          if ! sudo nixos-rebuild switch --flake .#"$flake_name"; then
            echo "❌ NixOS switch failed (but changes are committed)"
            cd "$original_dir"
            return 1
          fi
        else
          if ! sudo nixos-rebuild switch; then
            echo "❌ NixOS switch failed (but changes are committed)"
            cd "$original_dir"
            return 1
          fi
        fi
        
        echo "✅ Complete! System rebuilt and switched with: $*"
        cd "$original_dir"
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