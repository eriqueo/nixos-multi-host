# home.nix - Heartwood Craft User Configuration
let
  # Nordic Color Palette
  nordic-blue = {
    # Base colors
    bg = "#2e3440";           # Dark blue-grey background
    bg-alt = "#3b4252";       # Slightly lighter background
    bg-darker = "#1a1d23";    # Darker variant
    
    # Foreground colors  
    fg = "#eceff4";           # Light foreground
    fg-alt = "#d8dee9";       # Slightly dimmer foreground
    fg-dim = "#4c566a";       # Dimmed text
    
    # Accent colors (blue variant)
    accent = "#5e81ac";       # Nordic blue
    accent-bright = "#81a1c1"; # Brighter blue
    accent-dim = "#4c7398";   # Dimmer blue
    
    # Status colors
    red = "#bf616a";          # Nordic red
    orange = "#d08770";       # Nordic orange  
    yellow = "#ebcb8b";       # Nordic yellow
    green = "#a3be8c";        # Nordic green
    purple = "#b48ead";       # Nordic purple
    
    # UI colors
    border = "#434c5e";       # Border color
    selection = "#4c566a";    # Selection background
    urgent = "#bf616a";       # Urgent/warning color
  };
  
  # Theme selection - change this to switch themes later
  theme = nordic-blue;
  
  # Font configuration
  fonts = {
    mono = "CaskaydiaCove Nerd Font";
    sans = "Inter";
    size = {
      normal = "13";
      large = "15";
    };
  };

in 
{ config, pkgs, lib, osConfig, ... }:

{
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";

  # ✅ UNIVERSAL PACKAGES
  home.packages = with pkgs; [
    # Modern CLI replacements
    bat eza fzf ripgrep htop btop tree tmux neofetch
    
    # Development tools
    python3 nodejs gh speedtest-cli nmap wireguard-tools
    
    # Data processing utilities
    jq yq pandoc zip unzip p7zip
    
    # Network and file management
    curl wget rsync sshfs rclone
    
    # System utilities
    xclip
    
    # Universal productivity
    obsidian espanso
  ] 
  
  # 🔄 CONDITIONAL PACKAGES
  
  # Server-only packages
  ++ lib.optionals (osConfig.server or false) [
    # OCR and document processing
    tesseract imagemagick poppler_utils
    
    # Container management
    podman-compose
    
    # System monitoring
    iotop lsof
  ]
  
  # Desktop packages (laptop)
  ++ lib.optionals (osConfig.desktop or false) [
    # GUI applications
    firefox discord telegram-desktop spotify
    libreoffice gimp vscode
    wev              # Event viewer
    wl-clipboard     # Clipboard utilities (wl-copy, wl-paste)

    #Nordic themes
	nerd-fonts.caskaydia-cove
    inter
    nordic  # The Nordic GTK theme
    
    # Media clients
    vlc mpv
    
    # Hyprland-specific utilities
    hyprpicker       # Color picker
    hyprcursor       # Cursor management
    hyprpaper        # Wallpaper daemon
    hypridle         # Idle management
    hyprlock         # Screen locker
    hyprshot        # Enhanced screenshot tool
    # Notifications and launchers
    
    swaynotificationcenter           # SwayNC notification center
    libnotify        # For notify-send command
    wofi             # Application launcher
    # NOTE: waybar removed - provided by programs.waybar
    
    # System management
    brightnessctl    # Brightness control
    playerctl        # Media player control
    pamixer          # Audio control
    blueman          # Bluetooth
    pavucontrol
    
    # File management
    ranger           # Terminal file manager
    xdg-utils        # Open files with default apps
    
    # Network/system info
    networkmanagerapplet  # Network management
  ];

  # ✅ UNIVERSAL ENVIRONMENT VARIABLES
  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    PROJECTS = "$HOME/workspace/projects";
    SCRIPTS = "$HOME/workspace/scripts";
    DOTFILES = "$HOME/workspace/dotfiles";
  }
  
  # 🔄 CONDITIONAL ENVIRONMENT VARIABLES
  
  # Server environment (local services)
  // lib.optionalAttrs (osConfig.server or false) {
    DATABASE_URL = "postgresql://business_user:yJQlVUd934UhmC+gA2or9yZrhWJz5cgniuYA+ePAcaU=@localhost:5432/heartwood_business";
    BUSINESS_API_URL = "http://localhost:8000";
    OLLAMA_API_URL = "http://localhost:11434";
    JELLYFIN_URL = "http://localhost:8096";
    FRIGATE_URL = "http://localhost:5000";
  }
  
  # Client environment (remote services via Tailscale)
  // lib.optionalAttrs (osConfig.laptop or false) {
    DATABASE_URL = "postgresql://business_user:yJQlVUd934UhmC+gA2or9yZrhWJz5cgniuYA+ePAcaU=@100.110.68.48:5432/heartwood_business";
    BUSINESS_API_URL = "http://100.110.68.48:8000";
    OLLAMA_API_URL = "http://100.110.68.48:11434";
    JELLYFIN_URL = "http://100.110.68.48:8096";
    FRIGATE_URL = "http://100.110.68.48:5000";
  };

  # Workspace directory structure
  home.file = {
      "workspace/projects/.keep".text = "";
      "workspace/scripts/.keep".text = "";
      "workspace/dotfiles/.keep".text = "";
      "coding/projects/.keep".text = "";
      "Pictures/screenshots/.keep".text = "";  # Add this line
      
      # Add the new config files here (inside the same block)
      ".config/hypr/hypridle.conf".text = ''
        general {
          lock_cmd = pidof hyprlock || hyprlock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
        }
    
        listener {
          timeout = 150
          on-timeout = brightnessctl -s set 10
          on-resume = brightnessctl -r
        }
    
        listener {
          timeout = 300
          on-timeout = loginctl lock-session
        }
    
        listener {
          timeout = 330
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
        }
    
        listener {
          timeout = 1800
          on-timeout = systemctl suspend
        }
      '';
    
      ".config/hypr/hyprlock.conf".text = ''
        background {
          monitor =
          path = ~/Pictures/wallpaper.jpg
          blur_passes = 3
          blur_size = 8
        }
    
        input-field {
          monitor =
          size = 200, 50
          position = 0, -80
          dots_center = true
          fade_on_empty = false
          font_color = rgb(202, 211, 245)
          inner_color = rgb(91, 96, 120)
          outer_color = rgb(24, 25, 38)
          outline_thickness = 5
          placeholder_text = <b>Password...</b>
          shadow_passes = 2
        }
    
        label {
          monitor =
          text = Hi $USER
          color = rgba(200, 200, 200, 1.0)
          font_size = 25
          font_family = JetBrains Mono
          position = 0, 80
          halign = center
          valign = center
        }
      '';
    
      ".config/swaync/config.json".text = ''
        {
          "positionX": "right",
          "positionY": "top",
          "timeout": 10,
          "notification-icon-size": 64,
          "control-center-width": 500,
          "control-center-height": 600
        }
      '';
  };

  # ✅ UNIVERSAL GIT CONFIGURATION
  programs.git = {
    enable = true;
    userName = "eric";
    userEmail = "eriqueo@proton.me";
    
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "micro";
      pull.rebase = false;
      push.default = "simple";
      color.ui = true;
    };
    
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --oneline --graph --decorate --all";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
    };
  };

  # SSH configuration
  programs.ssh = {
    enable = true;
    extraConfig = ''
      AddKeysToAgent yes
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes
    '';
  };
  
  services.ssh-agent.enable = true;

  # ✅ ZSH CONFIGURATION WITH CONDITIONAL ALIASES
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };
    
    defaultKeymap = "emacs";
    
    # 🔄 CONDITIONAL ALIASES
    shellAliases = {
      # Universal file management
      ls = "eza";
      ll = "eza -l --git --icons";
      la = "eza -la --git --icons";
      lt = "eza --tree --level=2";
      
      # Universal navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      
      # Universal system utilities
      df = "df -h";
      du = "du -h";
      free = "free -h";
      htop = "htop --tree";
      grep = "rg";
      open = "xdg-open";
      
      # Universal git shortcuts
      gs = "git status -sb";
      ga = "git add .";
      gc = "git commit -m";
      gp = "git push";
      gl = "git log --oneline --graph --decorate --all";
      gpl = "git pull";
      
      # Universal development
      speedtest = "speedtest-cli";
      myip = "curl -s ifconfig.me";
      reload = "source ~/.zshrc";
    } 
    
    # 🔄 SERVER ALIASES (homeserver)
    // lib.optionalAttrs (osConfig.server or false) {
      # NixOS system management with enhanced grebuild function
      nixconfig = "sudo micro /etc/nixos/configuration.nix";
      nixflake = "sudo micro /etc/nixos/flake.nix";
      nixmodules = "sudo micro /etc/nixos/modules.nix";
      nixhome = "sudo micro /etc/nixos/home.nix";
      nixrebuild = "sudo nixos-rebuild switch --flake /etc/nixos#homeserver";
      nixtest = "sudo nixos-rebuild test --flake /etc/nixos#homeserver";
      nixsearch = "nix search nixpkgs";
      nixclean = "nix-collect-garbage -d";
      nixgen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      
      # AI and business services
      ai-chat = "ollama run llama3.2:3b";
      ai-embed = "ollama run nomic-embed-text";
      ai-status = "systemctl status ollama && ollama list";
      
      # Business development environment
      business-dev = "cd /opt/business";
      business-api = "cd /opt/business/api";
      business-db = "psql \"$DATABASE_URL\"";
      
      # Receipt processing and document management (when implemented)
      receipt-process = "cd /opt/business/receipts";
      receipt-upload = "cd /opt/business/uploads";
      
      # Business intelligence and analytics (when implemented)
      cost-dashboard = "echo 'Dashboard will be at: http://localhost:8501'";
      jobtread-sync = "echo 'JobTread sync not yet implemented'";
      business-stats = "echo 'Business analytics not yet implemented'";
      
      # ADHD productivity and focus management
      focus-mode = "echo 'Focus monitoring not yet implemented'";
      focus-off = "echo 'Focus monitoring not yet implemented'";
      context-snap = "python3 /etc/adhd-tools/context-snapshot.py";
      context-list = "python3 /etc/adhd-tools/context-snapshot.py --list";
      energy-log = "python3 /etc/adhd-tools/energy-tracker.py";
      energy-stats = "python3 /etc/adhd-tools/energy-tracker.py --stats";
      work-stats = "echo 'Productivity analysis not yet implemented'";
      
      # Surveillance and home monitoring (server local)
      cameras = "echo 'Frigate UI: http://localhost:5000'";
      home-assistant = "echo 'Home Assistant: http://localhost:8123'";
      frigate-logs = "sudo podman logs -f frigate";
      ha-logs = "sudo podman logs -f home-assistant";
      surveillance-status = "systemctl status mosquitto && sudo podman ps | grep -E '(frigate|home-assistant)'";
      
      # Media server management (server local)
      jellyfin = "echo 'Jellyfin: http://localhost:8096'";
      sonarr = "echo 'Sonarr: http://localhost:8989'";
      radarr = "echo 'Radarr: http://localhost:7878'";
      lidarr = "echo 'Lidarr: http://localhost:8686'";
      prowlarr = "echo 'Prowlarr: http://localhost:9696'";
      qbittorrent = "echo 'qBittorrent: http://localhost:8080'";
      navidrome = "echo 'Navidrome: http://localhost:4533'";
      immich = "echo 'Immich: http://localhost:2283'";
      
      # Media directories
      media = "cd /mnt/media";
      tv = "cd /mnt/media/tv";
      movies = "cd /mnt/media/movies";
      music = "cd /mnt/media/music";
      
      # Container management
      containers = "sudo podman ps";
      container-logs = "sudo podman logs";
      container-restart = "sudo systemctl restart podman-";
    }
    
    # 🔄 LAPTOP ALIASES (remote access)
    // lib.optionalAttrs (osConfig.laptop or false) {
      # NixOS system management
      nixconfig = "sudo micro /etc/nixos/configuration.nix";
      nixflake = "sudo micro /etc/nixos/flake.nix";
      nixmodules = "sudo micro /etc/nixos/modules.nix";
      nixhome = "sudo micro /etc/nixos/home.nix";
      nixrebuild = "sudo nixos-rebuild switch --flake /etc/nixos#laptop";
      nixtest = "sudo nixos-rebuild test --flake /etc/nixos#laptop";
      nixsearch = "nix search nixpkgs";
      nixclean = "nix-collect-garbage -d";
      nixgen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      
      # Remote services via Tailscale
      cameras = "firefox http://100.110.68.48:5000";
      home-assistant = "firefox http://100.110.68.48:8123";
      jellyfin = "firefox http://100.110.68.48:8096";
      sonarr = "firefox http://100.110.68.48:8989";
      radarr = "firefox http://100.110.68.48:7878";
      lidarr = "firefox http://100.110.68.48:8686";
      prowlarr = "firefox http://100.110.68.48:9696";
      qbittorrent = "firefox http://100.110.68.48:8080";
      navidrome = "firefox http://100.110.68.48:4533";
      immich = "firefox http://100.110.68.48:2283";
      
      # Business services (remote)
      business-dashboard = "firefox http://100.110.68.48:8501";
      business-api = "curl http://100.110.68.48:8000/health";
      business-db = "psql \"$DATABASE_URL\"";
      
      # AI services (remote)
      ai-status = "curl http://100.110.68.48:11434/api/tags";
      
      # Laptop-specific
      battery = "acpi -b";
      brightness = "brightnessctl";
      bluetooth = "bluetoothctl";
      wifi-scan = "nmcli dev wifi list";
      laptop-info = "acpi -b && iwconfig 2>/dev/null | grep -E 'ESSID|Quality'";
      
      # Mount server shares
      mount-media = "sudo mkdir -p /mnt/server-media && sudo mount -t cifs //100.110.68.48/media /mnt/server-media -o username=eric,uid=1000,gid=1000";
      umount-media = "sudo umount /mnt/server-media";
    };
    
    # Advanced shell functions for business workflow integration
    initContent = lib.mkOrder 550 ''
      ${lib.optionalString (osConfig.server or false) ''
        # Enhanced grebuild function for server
        grebuild() {
          if [ -z "$1" ]; then
            echo "Usage: grebuild \"commit message\""
            return 1
          fi
          
          echo "🔄 Starting NixOS configuration update..."
          cd /etc/nixos || { echo "❌ Failed to navigate to /etc/nixos"; return 1; }
          
          # Git operations
          echo "📝 Adding files to git..."
          sudo git add . || { echo "❌ Git add failed"; return 1; }
          
          echo "💾 Committing changes..."
          sudo git commit -m "$1" || { echo "❌ Git commit failed"; return 1; }
          
          echo "☁️  Pushing to remote..."
          sudo -E git push || { echo "❌ Git push failed"; return 1; }
          
          # NixOS rebuild
          echo "🧪 Testing configuration..."
          sudo nixos-rebuild test --flake .#homeserver || { 
            echo "❌ Configuration test failed! Not applying changes."
            return 1
          }
          
          echo "✅ Test successful! Applying configuration..."
          sudo nixos-rebuild switch --flake .#homeserver || {
            echo "❌ Configuration switch failed!"
            return 1
          }
          
          echo "🎉 NixOS configuration updated successfully!"
        }
        
        # Quick test function
        gtest() {
          if [ -z "$1" ]; then
            echo "Usage: gtest \"commit message\""
            return 1
          fi
          
          echo "🧪 Testing NixOS configuration..."
          cd /etc/nixos || { echo "❌ Failed to navigate to /etc/nixos"; return 1; }
          
          sudo git add .
          sudo git commit -m "TEST: $1"
          sudo nixos-rebuild test --flake .#homeserver
        }
        
        # Business project context management
        project() {
          if [ -z "$1" ]; then
            echo "📁 Available projects:"
            ls -la ~/workspace/projects/ 2>/dev/null || echo "No projects directory found"
          else
            if [ -d "~/workspace/projects/$1" ]; then
              cd ~/workspace/projects/$1
              echo "🎯 Switched to project: $1"
              if [ -f ".project-env" ]; then
                source .project-env
                echo "✅ Project environment loaded"
              fi
            else
              echo "❌ Project '$1' not found"
              echo "Available projects:"
              ls ~/workspace/projects/ 2>/dev/null | head -5
            fi
          fi
        }
        
        # Quick receipt processing workflow (when implemented)
        receipt() {
          if [ -z "$1" ]; then
            echo "Usage: receipt <image_file> [project_name]"
            return 1
          fi
          
          if [ ! -f "$1" ]; then
            echo "File not found: $1"
            return 1
          fi
          
          echo "📄 Receipt processing not yet implemented"
          echo "Would process: $1 for project: ''${2:-default}"
        }
        
        # Energy level quick logging with context
        energy() {
          if [ -z "$1" ]; then
            python3 /etc/adhd-tools/energy-tracker.py --stats
          else
            python3 /etc/adhd-tools/energy-tracker.py "$1" "$2"
          fi
        }
        
        # Quick system status check
        status() {
          echo "🖥️  System Status Overview"
          echo "=========================="
          echo "💾 Memory: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')"
          echo "💽 Disk: $(df -h / | awk 'NR==2{print $5}')"
          echo "🔥 Load: $(uptime | awk -F'load average:' '{print $2}')"
          echo ""
          echo "🤖 AI Services:"
          systemctl is-active ollama >/dev/null && echo "  ✅ Ollama AI" || echo "  ❌ Ollama AI"
          echo ""
          echo "💼 Business Services:"
          systemctl is-active postgresql >/dev/null && echo "  ✅ PostgreSQL" || echo "  ❌ PostgreSQL"
          systemctl is-active redis-business >/dev/null && echo "  ✅ Redis" || echo "  ❌ Redis"
          echo ""
          echo "📹 Surveillance:"
          sudo podman ps --format "table {{.Names}}\\t{{.Status}}" | grep -E "(frigate|home-assistant)" | sed 's/^/  /' || echo "  No surveillance containers running"
          echo ""
          echo "📺 Media Services:"
          sudo podman ps --format "table {{.Names}}\\t{{.Status}}" | grep -E "(jellyfin|sonarr|radarr)" | sed 's/^/  /' || echo "  No media containers running"
        }
      ''}
      
      ${lib.optionalString (osConfig.laptop or false) ''
        # Enhanced grebuild function for laptop
        grebuild() {
          if [ -z "$1" ]; then
            echo "Usage: grebuild \"commit message\""
            return 1
          fi
          
          echo "🔄 Starting NixOS configuration update..."
          cd /etc/nixos || { echo "❌ Failed to navigate to /etc/nixos"; return 1; }
          
          # Git operations
          echo "📝 Adding files to git..."
          sudo git add . || { echo "❌ Git add failed"; return 1; }
          
          echo "💾 Committing changes..."
          sudo git commit -m "$1" || { echo "❌ Git commit failed"; return 1; }
          
          echo "☁️  Pushing to remote..."
          sudo -E git push || { echo "❌ Git push failed"; return 1; }
          
          # NixOS rebuild
          echo "🧪 Testing configuration..."
          sudo nixos-rebuild test --flake .#laptop || { 
            echo "❌ Configuration test failed! Not applying changes."
            return 1
          }
          
          echo "✅ Test successful! Applying configuration..."
          sudo nixos-rebuild switch --flake .#laptop || {
            echo "❌ Configuration switch failed!"
            return 1
          }
          
          echo "🎉 NixOS configuration updated successfully!"
        }
        
        # Quick test function
        gtest() {
          if [ -z "$1" ]; then
            echo "Usage: gtest \"commit message\""
            return 1
          fi
          
          echo "🧪 Testing NixOS configuration..."
          cd /etc/nixos || { echo "❌ Failed to navigate to /etc/nixos"; return 1; }
          
          sudo git add .
          sudo git commit -m "TEST: $1"
          sudo nixos-rebuild test --flake .#laptop
        }
        
        # Laptop-specific functions
        laptop-status() {
          echo "=== Laptop Status ==="
          acpi -b 2>/dev/null || echo "No battery info"
          iwconfig 2>/dev/null | grep -E "ESSID|Quality" || echo "No WiFi info"
          echo "=== Remote Services ==="
          curl -s -I http://100.110.68.48:5000 >/dev/null && echo "✅ Frigate" || echo "❌ Frigate"
          curl -s -I http://100.110.68.48:8096 >/dev/null && echo "✅ Jellyfin" || echo "❌ Jellyfin"
          curl -s -I http://100.110.68.48:8000 >/dev/null && echo "✅ Business API" || echo "❌ Business API"
        }
        
        # Connect to server for development
        dev-server() {
          ssh eric@100.110.68.48
        }
        
        # Sync local development with server
        sync-to-server() {
          rsync -avz ~/workspace/ eric@100.110.68.48:~/workspace/
        }
        
        sync-from-server() {
          rsync -avz eric@100.110.68.48:~/workspace/ ~/workspace/
        }
        
        # Override status for laptop
        status() {
          echo "💻 Laptop Status Overview"
          echo "========================="
          echo "🔋 Battery: $(acpi -b 2>/dev/null | cut -d',' -f2 | tr -d ' ' || echo 'Unknown')"
          echo "📶 WiFi: $(iwconfig 2>/dev/null | grep -o 'ESSID:"[^"]*"' | cut -d'"' -f2 || echo 'Not connected')"
          echo "💾 Memory: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')"
          echo "💽 Disk: $(df -h / | awk 'NR==2{print $5}')"
          echo ""
          echo "🌐 Remote Services (via Tailscale):"
          curl -s -I http://100.110.68.48:5000 >/dev/null && echo "  ✅ Frigate" || echo "  ❌ Frigate"
          curl -s -I http://100.110.68.48:8096 >/dev/null && echo "  ✅ Jellyfin" || echo "  ❌ Jellyfin"
          curl -s -I http://100.110.68.48:11434 >/dev/null && echo "  ✅ AI Services" || echo "  ❌ AI Services"
        }
      ''}
    '';
  };

  # FZF integration for enhanced fuzzy finding
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "find . -type f";
    defaultOptions = [ 
      "--height 40%" 
      "--reverse" 
      "--border"
      "--preview 'head -100 {}'"
    ];
    fileWidgetOptions = [
      "--preview 'head -100 {}'"
    ];
  };

  # Readline configuration for better input handling
  programs.readline = {
    enable = true;
    extraConfig = ''
      "\e[A": history-search-backward
      "\e[B": history-search-forward
      set show-all-if-ambiguous on
      set completion-ignore-case on
      set bell-style visible
      "\t": menu-complete
    '';
  };

  # Starship prompt (universal)
  # Replace your existing "programs.starship.enable = true;" with this full configuration
  
  programs.starship = {
    enable = true;
    settings = {
      # Main prompt format
      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_status"
        "$nodejs"
        "$python"
        "$rust"
        "$nix_shell"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];
      
      # Nordic color palette for starship
      palette = "nordic";
      palettes.nordic = {
        # Use our theme colors
        accent = theme.accent;
        accent-bright = theme.accent-bright;
        red = theme.red;
        green = theme.green;
        yellow = theme.yellow;
        blue = theme.accent;
        purple = theme.purple;
        orange = theme.orange;
      };
      
      # Character (prompt symbol)
      character = {
        success_symbol = "[❯](accent)";
        error_symbol = "[❯](red)";
      };
      
      # Directory styling
      directory = {
        style = "bold accent";
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      
      # Git branch
      git_branch = {
        style = "accent-bright";
        format = "[$symbol$branch]($style) ";
        symbol = " ";
      };
      
      # Git status
      git_status = {
        style = "red";
      };
      
      # Command duration
      cmd_duration = {
        style = "yellow";
        format = "[$duration]($style) ";
        min_time = 2000;
      };
      
      # Programming languages
      nodejs = {
        style = "green";
        format = "[$symbol($version)]($style) ";
        symbol = "⬢ ";
      };
      
      python = {
        style = "blue";
        format = "[$symbol($version)]($style) ";
        symbol = "🐍 ";
      };
      
      rust = {
        style = "orange";
        format = "[$symbol($version)]($style) ";
        symbol = "🦀 ";
      };
      
      # Nix shell indicator
      nix_shell = {
        style = "purple";
        format = "[$symbol$state]($style) ";
        symbol = "❄️ ";
      };
      
      # Disable package for cleaner look
      package = {
        disabled = true;
      };
    };
  };

  # 🔄 HYPRLAND CONFIGURATION (laptop only)
  wayland.windowManager.hyprland = lib.mkIf (osConfig.desktop or false) {
    enable = true;
    settings = {
      exec-once = [
      	"waybar"
      	"swaync"                    # Notification daemon
      	"hypridle"                  # Idle management
      	"hyprpaper"                 # Wallpaper (if you want wallpapers)
      ];
      "$mod" = "SUPER";
      
      bindm = [
        # Mouse bindings for moving/resizing
        "$mod, mouse:272, movewindow"           # Drag windows with Super + left click
        "$mod, mouse:273, resizewindow"         # Resize windows with Super + right click
      ];
      
      bind = [
        # Terminal
        "$mod, Return, exec, konsole"
        # Screen locking
        "$mod SHIFT, L, exec, hyprlock"
        
        # Quick notifications test
        "$mod, N, exec, notify-send 'Test' 'Notification system working'"
        
        # SwayNC control
        "$mod, grave, exec, swaync-client -t -sw"  # Toggle notification center
        # Monitor layout switching
        "$mod SHIFT, bracketleft, exec, hyprctl keyword monitor 'eDP-1,2560x1600@165,0x0,1.60' && hyprctl keyword monitor 'DP-2,1920x1080@60,2560x0,1'"    # Laptop LEFT, external RIGHT
        "$mod SHIFT, bracketright, exec, hyprctl keyword monitor 'DP-2,1920x1080@60,0x0,1' && hyprctl keyword monitor 'eDP-1,2560x1600@165,1920x0,1.60'"   # External LEFT, laptop RIGHT
        
        # ===== FOCUS SWITCHING (just mod + arrows) =====
        "$mod, left, movefocus, l"              # Focus left window
        "$mod, right, movefocus, r"             # Focus right window  
        "$mod, up, movefocus, u"                # Focus up window
        "$mod, down, movefocus, d"              # Focus down window
        
        # ===== WINDOW MANAGEMENT (just mod) =====
        "$mod, F, fullscreen"                   # Fullscreen
        "$mod, Q, killactive"                   # Close window
        "$mod, V, togglefloating"               # Toggle floating
        
        # ===== SEND WINDOW TO WORKSPACE (ctrl + mod + key) =====
        "CTRL $mod, 1, movetoworkspace, 1"      # Send window to workspace 1
        "CTRL $mod, 2, movetoworkspace, 2"      # Send window to workspace 2
        "CTRL $mod, 3, movetoworkspace, 3"      # Send window to workspace 3
        "CTRL $mod, 4, movetoworkspace, 4"      # Send window to workspace 4
        "CTRL $mod, 5, movetoworkspace, 5"      # Send window to workspace 5
        "CTRL $mod, left, movetoworkspace, -1"  # Send window to previous workspace
        "CTRL $mod, right, movetoworkspace, +1" # Send window to next workspace
        
        # ===== WORKSPACE SWITCHING (ctrl + mod + alt + key) =====
        "CTRL $mod ALT, 1, workspace, 1"        # Switch view to workspace 1
        "CTRL $mod ALT, 2, workspace, 2"        # Switch view to workspace 2
        "CTRL $mod ALT, 3, workspace, 3"        # Switch view to workspace 3
        "CTRL $mod ALT, 4, workspace, 4"        # Switch view to workspace 4
        "CTRL $mod ALT, 5, workspace, 5"        # Switch view to workspace 5
        "CTRL $mod ALT, left, workspace, -1"    # Switch view to previous workspace
        "CTRL $mod ALT, right, workspace, +1"   # Switch view to next workspace
        
        # Alternative focus with arrows  
        "$mod SHIFT, left, movefocus, l"
        "$mod SHIFT, right, movefocus, r"
        "$mod SHIFT, up, movefocus, u"
        "$mod SHIFT, down, movefocus, d"
        
        # ===== WINDOW ARRANGEMENT (mod + alt + arrows) =====
        "$mod ALT, left, movewindow, l"         # Move window to the left position
        "$mod ALT, right, movewindow, r"        # Move window to the right position  
        "$mod ALT, up, movewindow, u"           # Move window to the top position
        "$mod ALT, down, movewindow, d"         # Move window to the bottom position
        
        # Familiar cycling
        "ALT, Tab, cyclenext"
        "ALT SHIFT, Tab, cyclenext, prev"
        
        # Screenshots
        ", Print, exec, hyprshot -m region -o ~/Pictures/screenshots/"          # Area screenshot
        #"SHIFT, Print, exec, hyprshot -m window -o ~/Pictures/screenshots/"     # window selection  
        "CTRL, Print, exec, hyprshot -m output -o ~/Pictures/screenshots/"      # Full screen/monitor
        # Optional: If you want clipboard + save (most useful):
        # ", Print, exec, hyprshot -m window -o ~/Pictures/screenshots/ --clipboard-only"     # Window to clipboard
         "SHIFT, Print, exec, hyprshot -m region -o ~/Pictures/screenshots/ --clipboard-only" # Area to clipboard
        # "CTRL, Print, exec, hyprshot -m output -o ~/Pictures/screenshots/ --clipboard-only"  # Screen to clipboard
        # Application launcher
                
        # App launcher with Space (like macOS Spotlight)
        "$mod, Space, exec, wofi --show drun"  # Change from R to Space
        
        # File manager with E
        "$mod, E, exec, dolphin"  # Or nautilus if you prefer
        "$mod, B, exec, brave"
        # Function keys
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ -5%"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];
      
      # Input configuration - Focus-based scrolling
      input = {
        follow_mouse = 0;
        kb_layout = "us";
        
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
        };
      };
      
      # Visual configuration
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee)";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };
      
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };
    };
  };

  # Waybar configuration (desktop only)
  programs.waybar = lib.mkIf (osConfig.desktop or false) {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
    systemd.enable = false;
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 4;
        
        modules-left = [ "hyprland/workspaces"  ];
        modules-center = [ "clock" "hyprland/window" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];
        
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            urgent = "";
            focused = "";
            default = "";
          };
          persistent-workspaces = {
            "*" = 5; # Show 5 workspaces on all monitors
          };
        };
        
        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };
        
        clock = {
          timezone = "America/Denver";
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        
        cpu = {
          format = "{usage}% ";
          tooltip = false;
          interval = 1;
        };
        
        memory = {
          format = "{}% ";
          interval = 1;
        };
        
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          on-click = "nm-connection-editor";
          tooltip-format = "{ifname} via {gwaddr}";
        };
        
        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };
        
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };
        
        tray = {
          spacing = 10;
        };
      };
    };
    
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "${fonts.mono}", monospace;
        font-size: ${fonts.size.normal}px;
        min-height: 0;
      }
      
      window#waybar {
        background-color: ${theme.bg};
        border-bottom: 2px solid ${theme.accent};
        color: ${theme.fg};
        opacity: 0.95;
      }
      
      window#waybar.hidden {
        opacity: 0.2;
      }
      
      #workspaces {
        margin: 0 4px;
      }
      
      #workspaces button {
        padding: 0 8px;
        background-color: transparent;
        color: ${theme.fg-alt};
        border-bottom: 3px solid transparent;
        border-radius: 0;
      }
      
      #workspaces button:hover {
        background: ${theme.bg-alt};
        color: ${theme.fg};
      }
      
     #workspaces button.active {
        background-color: ${theme.accent};
        color: ${theme.bg};
        border-bottom: 2px solid ${theme.accent-bright};
      }
      
     #workspaces button.urgent {
         background-color: ${theme.urgent};
         color: ${theme.fg};
       }
      
      #window,
      #clock,
      #battery,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
       padding: 0 10px;
       color: ${theme.fg};
       background: ${theme.bg-alt};
       margin: 2px;
       border-radius: 4px;
      }
      
      #window {
        background: transparent;
        margin: 0 4px;
        color: ${theme.accent};
        font-weight: bold;
      }
      
      #clock {
        background: ${theme.accent};
        color: ${theme.bg};
        font-weight: bold;
      }
          
      #battery {
        background: ${theme.green};
        color: ${theme.bg};
      }
          
      #battery.charging, #battery.plugged {
        background: ${theme.accent-bright};
        color: ${theme.bg};
      }
      
      @keyframes blink {
        to {
          background-color: ${theme.urgent};
          color: #000000;
        }
      }
      
      #battery.warning:not(.charging) {
         background: ${theme.yellow};
         color: ${theme.bg};
      }
          
      #battery.critical:not(.charging) {
         background: ${theme.red};
         color: ${theme.fg};
         animation: blink 0.5s linear infinite alternate;
      }
      
     #cpu {
         background: ${theme.accent-dim};
         color: ${theme.fg};
      }
          
      #memory {
         background: ${theme.purple};
         color: ${theme.fg};
      }
          
      #network {
         background: ${theme.accent-bright};
         color: ${theme.bg};
      }
          
      #network.disconnected {
         background: ${theme.red};
         color: ${theme.fg};
      }
      
      #pulseaudio {
         background: ${theme.yellow};
         color: ${theme.bg};
      }
    
      #pulseaudio.muted {
         background: ${theme.fg-dim};
         color: ${theme.fg};
      }
    
      #tray {
         background: ${theme.bg-alt};
      }
      
      #tray > .passive {
        -gtk-icon-effect: dim;
      }
      
      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: ${theme.red};
      }
    '';
  };

  # Add this new programs.kitty section to your home.nix
  # (This creates a Nordic terminal theme with transparency)
  
  # Add this new programs.kitty section to your home.nix
  # (This creates a Nordic terminal theme with transparency)
  
  programs.kitty = lib.mkIf (osConfig.desktop or false) {
    enable = true;
    font = {
      name = fonts.mono;
      size = 13;
    };
    settings = {
      # Nordic color scheme for terminal
      background = theme.bg;
      foreground = theme.fg;
      
      # Cursor colors
      cursor = theme.fg;
      cursor_text_color = theme.bg;
      
      # Selection colors
      selection_background = theme.selection;
      selection_foreground = theme.fg;
      
      # URL colors
      url_color = theme.accent-bright;
      
      # Terminal colors (ANSI)
      # Black
      color0 = theme.bg-darker;
      color8 = theme.fg-dim;
      
      # Red  
      color1 = theme.red;
      color9 = theme.red;
      
      # Green
      color2 = theme.green;
      color10 = theme.green;
      
      # Yellow
      color3 = theme.yellow;
      color11 = theme.yellow;
      
      # Blue
      color4 = theme.accent;
      color12 = theme.accent-bright;
      
      # Magenta
      color5 = theme.purple;
      color13 = theme.purple;
      
      # Cyan
      color6 = theme.accent-bright;
      color14 = theme.accent-bright;
      
      # White
      color7 = theme.fg;
      color15 = theme.fg;
      
      # Visual settings (like the video)
      background_opacity = "0.9";           # Transparency to see wallpaper
      background_blur = 32;                 # Blur effect
      
      # Window settings
      window_padding_width = 12;            # Nice padding
      hide_window_decorations = true;       # Clean look
      confirm_os_window_close = 0;          # No annoying popups
      
      # Tab bar (Nordic themed)
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      
      # Tab colors
      active_tab_background = theme.accent;
      active_tab_foreground = theme.bg;
      inactive_tab_background = theme.bg-alt;
      inactive_tab_foreground = theme.fg-alt;
      tab_bar_background = theme.bg;
      
      # Bell settings
      enable_audio_bell = false;
      visual_bell_duration = "0.0";
      
      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;
      
      # Scrolling
      scrollback_lines = 10000;
      wheel_scroll_multiplier = "5.0";
      
      # Mouse
      copy_on_select = true;
      strip_trailing_spaces = "smart";
      
      # Keyboard shortcuts (Nordic-friendly) - move to extraConfig instead
    };
    
    # Additional kitty configuration
    extraConfig = ''
      # Nordic-specific terminal enhancements
      modify_font cell_height 110%
      modify_font baseline 2
      
      # Cursor customization
      cursor_shape block
      cursor_blink_interval 0
      
      # Selection customization
      rectangle_select_modifiers ctrl+alt
      
      # Performance tweaks
      wayland_titlebar_color background
      
      # Keyboard shortcuts (fixed - can't use multiple 'map' in settings)
      map ctrl+shift+c copy_to_clipboard
      map ctrl+shift+v paste_from_clipboard
      map ctrl+shift+equal change_font_size all +2.0
      map ctrl+shift+minus change_font_size all -2.0
      map ctrl+shift+backspace change_font_size all 0
    '';
  };

  # Enable Home Manager self-management
  programs.home-manager.enable = true;
}
