{ config, pkgs, lib, ... }:

{
  imports = [
  
    ../../hardware-configuration.nix
    ../../modules/services.nix
  ];

  networking.hostName = "homeserver";
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    time.timeZone = "America/Denver";
    i18n.defaultLocale = "en_US.UTF-8";

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    nixpkgs.config.allowUnfree = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    services.tailscale.enable = true;
    system.stateVersion = "23.05";
    # Server-specific packages
  environment.systemPackages = with pkgs; [

  # Container Management
  podman-compose

  # Monitoring & Debugging
  iotop
  lsof
  strace
  btop   # or htop

  # Editors
  neovim
  micro

  # Networking & Dev Tools
  wget
  curl
  git
  neofetch

  # File Utilities
  unzip
  zip
  p7zip
  rsync
  tree
  diffutils
  less
  which

  # Terminal Productivity
  tmux
  bat
  eza
  fzf
  ripgrep

  # Data Parsing & Conversion
  jq
  yq
  pandoc

  # Multimedia
  ffmpeg-full
    lvm2 cryptsetup nfs-utils samba
  ntfs3g exfatprogs dosfstools

  ];

  virtualisation.podman = {
  enable = true;
  dockerCompat = true;
  defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";


  # Add user to server-specific groups
  users.users.eric.extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "podman" ];

  # Server firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22     # SSH
      2283   # Immich
      4533   # Navidrome
      5000   # Frigate
      7878   # Radarr
      8080   # qBittorrent
      8096   # Jellyfin
      8123   # Home Assistant
      8686   # Lidarr
      8989   # Sonarr
      9696   # Prowlarr
    ];
    allowedUDPPorts = [
      7359   # Frigate RTMP
      8555   # Frigate WebRTC
    ];
    interfaces = {
      "tailscale0" = {
        allowedTCPPorts = [
          5432   # PostgreSQL
          6379   # Redis
          8000   # Custom API
          8501   # Streamlit
          11434  # Ollama
          1883   # MQTT
        ];
      };
    };
  };

  # Enable server-specific services
  services.jellyfin.enable = true;
  
  # Hardware acceleration for media
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  programs.zsh = {
  enable = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  
  shellAliases = {
    # File management with modern tools
    "ls" = "eza --tree --level=2";
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
    "rebuild" = "sudo nixos-rebuild switch --flake /etc/nixos#homeserver";
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
