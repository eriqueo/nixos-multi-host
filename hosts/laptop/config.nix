# -----------------------------------------------------------------------------
# UPDATED: hosts/laptop/config.nix (SYSTEM LEVEL - CLEANED)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

{
  ####################################################################
  # 1. IMPORTS
  ####################################################################
  imports = [
    ./hardware-configuration.nix  
    ../../modules/secrets/secrets.nix
    # REMOVED: UI modules are now in Home Manager
  ];

  ####################################################################
  # 2. HOST IDENTITY
  ####################################################################
  networking.hostName = "heartwood-laptop";

  ####################################################################
  # 3. BOOT & SYSTEM
  ####################################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  ####################################################################
  # 4. NIX CONFIGURATION
  ####################################################################
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  ####################################################################
  # 5. WINDOW MANAGER SYSTEM ENABLEMENT
  ####################################################################
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  ####################################################################
  # 6. ZSH CONFIGURATION - SYSTEM LEVEL
  ####################################################################
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
    };
    
    # Universal shell functions
    interactiveShellInit = ''
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

  ####################################################################
  # 7. LOGIN MANAGER
  ####################################################################
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
      initial_session = {
        user = "eric";
        command = "Hyprland";
      };
    };
  };

  ####################################################################
  # 8. GRAPHICS & AUDIO (laptop-specific hardware)
  ####################################################################
  services.xserver.enable = true;
  hardware.graphics.enable = true;
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;
  
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  ####################################################################
  # 9. NETWORKING & BLUETOOTH (laptop mobility features)
  ####################################################################
  networking.networkmanager.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      DiscoverableTimeout = 0;
      AutoEnable = true;
    };
  };

  ####################################################################
  # 10. PRINTING (laptop-specific)
  ####################################################################
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint hplip brlaser brgenml1lpr cnijfilter2
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  ####################################################################
  # 11. SSH & SECURITY
  ####################################################################
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services.tailscale.enable = true;

  ####################################################################
  # 12. CONTAINERS
  ####################################################################
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";

  ####################################################################
  # 13. ESSENTIAL SYSTEM PACKAGES (laptop-only) - FIXED SYNTAX
  ####################################################################
  environment.systemPackages = with pkgs; [
    # Login Manager
    greetd.tuigreet

    # Wayland Workspace Manager
    hyprsome

    # Printing Support
    cups
    system-config-printer

    # Power & Sensor Tools
    acpi
    lm_sensors

    # Fonts
    nerd-fonts.caskaydia-cove

    # Editors
    neovim
    micro

    # Network Tools
    wget
    curl

    # File Tools
    unzip
    zip
    p7zip
    rsync

    # Navigation & Info
    tree
    btop
    neofetch

    # Terminal UX Enhancements
    bat
    eza
    fzf
    ripgrep
    tmux

    # GNU Utilities
    diffutils
    less
    which

    # Data Manipulation
    jq
    yq
    pandoc
    python3 
    nodejs 
    gh 
    speedtest-cli 
    nmap 
    wireguard-tools
    sshfs 
    rclone 
    xclip 
    usbutils 
    pciutils 
    dmidecode 
    powertop
    python3Packages.pip
  ];

  ####################################################################
  # 14. SYSTEM STATE VERSION
  ####################################################################
  system.stateVersion = "23.05";
}