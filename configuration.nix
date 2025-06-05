# configuration.nix - Heartwood Craft Universal Base Configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # 🎯 OPTION DEFINITIONS (moved from config block)
  options = {
    media.server = lib.mkEnableOption "media server services";
    media.client = lib.mkEnableOption "media client tools";
    surveillance.server = lib.mkEnableOption "surveillance server";
    surveillance.client = lib.mkEnableOption "surveillance client";
    business.server = lib.mkEnableOption "business server services";
    business.client = lib.mkEnableOption "business client tools";
    ai.server = lib.mkEnableOption "AI server services";
    ai.client = lib.mkEnableOption "AI client tools";
    server = lib.mkEnableOption "server mode";
    laptop = lib.mkEnableOption "laptop hardware";
    desktop = lib.mkEnableOption "desktop environment";
  };

  config = {
    # ✅ UNIVERSAL SYSTEM CONFIG
    
    # Boot configuration
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Timezone and locale
    time.timeZone = "America/Denver";
    i18n.defaultLocale = "en_US.UTF-8";

    # 📦 COMPLETE PACKAGE CONFIGURATION
    environment.systemPackages = with pkgs; [
      # ✅ UNIVERSAL CORE PACKAGES (all hosts need these)
      vim micro wget curl git tree htop neofetch unzip zip
      python3 nodejs gh speedtest-cli nmap wireguard-tools
      jq yq pandoc p7zip rsync sshfs rclone xclip
      tmux bat eza fzf ripgrep btop
      
      # Universal system tools
      usbutils pciutils dmidecode powertop lvm2 cryptsetup
      nfs-utils samba
      
      # Universal file systems
      ntfs3g exfatprogs dosfstools
      
      # Universal text processing
      diffutils less which
      
      # Python package manager
      python3Packages.pip
    ] 
    # 🖥️ DESKTOP PACKAGES (laptop only)
    ++ lib.optionals config.desktop [
      # Hyprland desktop environment essentials
      waybar wofi mako grim slurp wl-clipboard
      pavucontrol brightnessctl
      
      # KDE Applications (familiar tools)
      konsole dolphin kate yakuake gwenview kdeconnect ark okular
      
      # Browsers
      firefox brave
      
      # Development & Productivity
      vscode obsidian libreoffice
      
      # Proton Suite
      protonmail-bridge
      
      # Media & Communication
      vlc qbittorrent discord telegram-desktop thunderbird
      
      # Graphics & Creative
      gimp inkscape blender
      
      # System utilities
      blueman timeshift udiskie redshift
      
      # Audio/Video production
      ffmpeg-full
    ]
    # 🔧 SERVER PACKAGES (server only)
    ++ lib.optionals config.server [
      # Container and system management
      podman-compose iotop lsof strace
      
      # Media processing
      ffmpeg-full
    ];

    # SSH service
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    # Tailscale VPN
    services.tailscale.enable = true;

    # 👤 USERS CONFIGURATION
    users.users.eric = {
      isNormalUser = true;
      description = "Eric - Heartwood Craft";
      extraGroups = [ "wheel" ] 
        ++ lib.optionals config.laptop [ "networkmanager" "video" "audio" ]
        ++ lib.optionals config.server [ "docker" "podman" ];
      
      # SSH keys for server
      openssh.authorizedKeys.keys = lib.optionals config.server [
        # Replace with your actual SSH public key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQFHXbcZCYrqyJoRPJddpEpnEquRJUxtopQkZsZdGhl hwc@laptop"
      ];
      
      # Initial password only for laptop (will be prompted to change)
      initialPassword = lib.mkIf config.laptop "changeme123";
    };

    # Nix configuration
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    nixpkgs.config.allowUnfree = true;

    # 🔥 UNIFIED FIREWALL CONFIGURATION
    networking.firewall = {
      enable = true;
      
      # Server-specific ports (for local network access)
      allowedTCPPorts = lib.mkIf config.server [
        22      # SSH
        2283    # Immich
        4533    # Navidrome
        5000    # Frigate
        7878    # Radarr
        8080    # qBittorrent (via Gluetun)
        8096    # Jellyfin
        8123    # Home Assistant
        8686    # Lidarr
        8989    # Sonarr
        9696    # Prowlarr
      ];
      
      allowedUDPPorts = lib.mkIf config.server [
        7359    # Jellyfin discovery
        8555    # Frigate WebRTC
      ];
      
      # Tailscale interface rules (server only - for secure remote access)
      interfaces = lib.mkIf config.server {
        "tailscale0" = {
          allowedTCPPorts = [
            5432    # PostgreSQL
            6379    # Redis
            8000    # Business API
            8501    # Streamlit Dashboard
            11434   # Ollama AI
            1883    # MQTT
          ];
        };
      };
    };

    # 🔄 LAPTOP HARDWARE CONFIGURATION
    services.tlp = lib.mkIf config.laptop {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        START_CHARGE_THRESH_BAT0 = 20;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
    
    services.thermald.enable = lib.mkIf config.laptop true;
    networking.networkmanager.enable = lib.mkIf config.laptop true;
    hardware.bluetooth.enable = lib.mkIf config.laptop true;
    services.blueman.enable = lib.mkIf config.laptop true;

    # 🔄 DESKTOP ENVIRONMENT CONFIGURATION
    services.xserver.enable = lib.mkIf config.desktop true;
    programs.hyprland = lib.mkIf config.desktop {
      enable = true;
      xwayland.enable = true;
    };

    # Desktop audio (PipeWire)
    hardware.pulseaudio.enable = lib.mkIf config.desktop false;
    security.rtkit.enable = lib.mkIf config.desktop true;
    services.pipewire = lib.mkIf config.desktop {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Graphics (desktop)
    hardware.opengl = lib.mkIf config.desktop {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    # Touchpad (laptop)
    services.xserver.libinput = lib.mkIf config.laptop {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
      };
    };

    # Power services (laptop)
    services.upower.enable = lib.mkIf config.laptop true;
    services.logind = lib.mkIf config.laptop {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "ignore";
    };

    # XDG portal (desktop)
    xdg.portal = lib.mkIf config.desktop {
      enable = true;
      wlr.enable = true;
    };

    # 🔄 VIRTUALIZATION CONFIGURATION
    virtualisation = {
      # Podman for server containers
      podman = lib.mkIf config.server {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      
      # Docker for desktop development
      docker.enable = lib.mkIf config.desktop true;
      
      # OCI backend selection
      oci-containers.backend = lib.mkIf config.server "podman";
    };

    # Flatpak support (desktop)
    services.flatpak.enable = lib.mkIf config.desktop true;

    # System version
    system.stateVersion = "23.05";
  };
}
