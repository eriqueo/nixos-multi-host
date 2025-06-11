{ config, pkgs, lib, ... }:

{
  imports = [
   # ./hardware-configuration.nix
  ];

  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    time.timeZone = "America/Denver";
    i18n.defaultLocale = "en_US.UTF-8";

    environment.systemPackages = with pkgs; [
      vim micro wget curl git tree htop neofetch unzip zip
      python3 nodejs gh speedtest-cli nmap wireguard-tools
      jq yq pandoc p7zip rsync sshfs rclone xclip
      tmux bat eza fzf ripgrep btop
      usbutils pciutils dmidecode powertop lvm2 cryptsetup
      nfs-utils samba
      ntfs3g exfatprogs dosfstools
      diffutils less which
      python3Packages.pip   
    ];
    users.users.eric = {
      isNormalUser = true;
      home = "/home/eric";
      description = "Eric - Heartwood Craft";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQFHXbcZCYrqyJoRPJddpEpnEquRJUxtopQkZsZdGhl hwc@laptop"
      ];
      initialPassword = "il0wwlm?";
    };  
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
    programs.zsh = {
      enable = true;
      autosuggestions.enable = true; \ # This enables history-based suggestions
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
        "grep" = "rg";
        "open" = "xdg-open";
        
        # Git workflow shortcuts
        "gs" = "git status -sb";
        "ga" = "git add .";
        "gc" = "git commit -m";
        "gp" = "git push";
        "gl" = "git log --oneline --graph --decorate --all";
        "gpl" = "git pull";
        
        # NixOS system management
        "nixcon" = "sudo micro /etc/nixos/configuration.nix";
        "nixflake" = "sudo micro /etc/nixos/flake.nix";
        "nixlaphome" = "sudo micro /etc/nixos/hosts/laptop/home.nix";
        "nixlapcon" = "sudo micro /etc/nixos/hosts/laptop/default.nix";
        "nixserverhome" = "sudo micro /etc/nixos/hosts/server/home.nix";
        "nixservercon" = "sudo micro /etc/nixos/hosts/server/default.nix";
        "nixsearch" = "nix search nixpkgs";
        "nixclean" = "nix-collect-garbage -d";
        "nixgen" = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        
        # Development and productivity
        "speedtest" = "speedtest-cli";
        "myip" = "curl -s ifconfig.me";
        "reload" = "source ~/.zshrc";
      };
      
      # Universal shell functions
      interactiveShellInit = ''
        # ADHD-friendly productivity functions
        mkcd() { mkdir -p "$1" && cd "$1" }
        
        # Enhanced file extraction
        extract() {
          if [[ -f "$1" ]]; then
            case "$1" in
              *.tar.gz)  tar -xzf "$1" ;;
              *.tar.xz)  tar -xJf "$1" ;;
              *.tar.bz2) tar -xjf "$1" ;;
              *.zip)     unzip "$1" ;;
              *.rar)     unrar x "$1" ;;
              *.pdf)     echo "PDF file: $1 (use pdf processing tools)" ;;
              *)         echo "'$1' cannot be extracted" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        }
        
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
    
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;               # Enables `docker` CLI compatibility
      defaultNetwork.settings.dns_enabled = true;
    };
   # virtualisation.docker.enable = true;  # Enable Docker service if needed
    virtualisation.oci-containers.backend = "podman";  # Use Podman as OCI backend


    system.stateVersion = "23.05";
  };
}
