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
    ../../modules/users/eric.nix     # Consolidated user configuration
    ../../modules/filesystem.nix     # Charter-compliant filesystem structure
    ../../modules/vault-sync-system.nix  # NixOS vault sync system

    # Shared configuration
    ../../shared/secrets.nix         # Shared secrets management
    ../../shared/networking.nix      # Shared networking configuration

    # Network services
    ../../modules/services/network/vpn.nix  # ProtonVPN service with management functions

    # YouTube transcript CLI tool
    ./modules/transcript-cli.nix     # YouTube transcript extraction CLI

    # REMOVED: UI modules are now in Home Manager
  ];

  ####################################################################
  # 2. FILESYSTEM CONFIGURATION - Enable user directories only
  ####################################################################
  hwc.filesystem.userDirectories.enable = true;  # PARA directories, XDG config, symlinks

  ####################################################################
  # 3. NETWORK SERVICES CONFIGURATION
  ####################################################################
  # ProtonVPN service - Simple on-demand toggle for coffee shop use
  hwc.services.network.vpn = {
    enable = true;  # Provides vpnon/vpnoff commands
  };

  ####################################################################
  # 16. HOST IDENTITY
  ####################################################################
  networking.hostName = "hwc-laptop";
  # File ownership rules now handled in modules/users/eric.nix

  ####################################################################
  # 16. BOOT & SYSTEM
  ####################################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  ####################################################################
  # 16. NIX CONFIGURATION
  ####################################################################
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  ####################################################################
  # 16.1. SOPS SECRETS CONFIGURATION
  ####################################################################
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  ####################################################################
  # 16. WINDOW MANAGER SYSTEM ENABLEMENT
  ####################################################################
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  ####################################################################
  # 16. ZSH CONFIGURATION - SYSTEM LEVEL
  ####################################################################
  # ZSH system enablement now handled in modules/users/eric.nix

  ####################################################################
  # 16. LOGIN MANAGER
  ####################################################################
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
      initial_session = {
        user = "eric";
        command = "Hyprland";
      };
    };
  };

  ####################################################################
  # 16. GRAPHICS & AUDIO (laptop-specific hardware)
  ####################################################################
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit apps
  };

  hardware.nvidia = {
    # Use open-source kernel modules (recommended for RTX 2000 Ada)
    open = true;

    # Modesetting is required
    modesetting.enable = true;

    # Power management (helps with stability)
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Enable nvidia-settings
    nvidiaSettings = true;

    # Use stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME configuration - OFFLOAD MODE (recommended)
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Enables nvidia-offload command
      };

      # Your specific bus IDs
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Specializations for different modes
  specialisation = {
    nvidia-sync.configuration = {
      hardware.nvidia.prime = {
        offload = {
          enable = lib.mkForce false;
          enableOffloadCmd = lib.mkForce false;
        };
        sync.enable = true;  # For gaming/high performance
      };
    };
  };

  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;

  # File manager support
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  ####################################################################
  # 16. NETWORKING & BLUETOOTH (laptop mobility features)
  ####################################################################
  # NetworkManager and DNS configuration now handled by shared/networking.nix
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      DiscoverableTimeout = 0;
      AutoEnable = true;
    };
  };

services.samba = {
  enable = true;
  openFirewall = true;
  settings = {
    global = {
      "workgroup" = "WORKGROUP";
      "server string" = "Samba on hwc-laptop";
      "security" = "user";
      "map to guest" = "Bad User";
      "guest account" = "nobody";
      # Modern SMB compatibility settings
      "server min protocol" = "SMB2_10";
      "client min protocol" = "SMB2_10";
      "server max protocol" = "SMB3";

      # SMB Signing and Encryption (CRITICAL for modern Windows)
      "server signing" = "auto";
      "server schannel" = "auto";
      "encrypt passwords" = "yes";

      # Disable problematic features for guest access
      "ntlm auth" = "yes";
      "lanman auth" = "no";
      "client lanman auth" = "no";
      "client ntlmv2 auth" = "yes";
                      # Other potentially helpful settings
      "dns proxy" = "no";
      "strict allocate" = "yes";
      "oplocks" = "yes";
      "level2 oplocks" = "yes";
      "wide links" = "yes";
      "unix extensions" = "no"; # Often helps with Windows compatibility
    };
    "skpshare" = {
      path = "/opt/sketchup/vm/shared";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "yes";
      "create mask" = "0777";
      "directory mask" = "0777";
      "force user" = "nobody";
      "force group" = "nogroup";
      "guest only" = "yes";
    };
  };
};


  ####################################################################
  # 16. PRINTING (laptop-specific)
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
  # 16. SSH & SECURITY
  ####################################################################
  # SSH and Tailscale base configuration from shared/networking.nix

  ####################################################################
  # 16. CONTAINERS & VIRTUALIZATION
  ####################################################################
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";

  # QEMU/KVM for SketchUp VMs
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      ovmf.enable = true;
      ovmf.packages = [ pkgs.OVMF.fd ];
      vhostUserPackages = with pkgs; [ virtiofsd ];
    };

  };
  virtualisation.spiceUSBRedirection.enable = true;

  # Add user to libvirtd group for VM management
  users.users.eric.extraGroups = [ "libvirtd" ];

  ####################################################################
  # 16. POWER MANAGEMENT (laptop-specific)
  ####################################################################
  services.thermald.enable = true;
  services.tlp.enable = true;
  powerManagement.enable = true;

  ####################################################################
  # 16. LAPTOP-SPECIFIC SYSTEM PACKAGES
  ####################################################################
  # Core packages now provided by modules/users/eric.nix
  # Only laptop-specific packages are included here
  environment.systemPackages = with pkgs; [
    # Login Manager
    tuigreet

    # Wayland Workspace Manager
    hyprsome

    # Printing Support
    cups
    system-config-printer

    # Claude Code CLI
    claude-code

    # Power & Sensor Tools (laptop-specific)
    acpi
    lm_sensors
    powertop

    # Fonts for UI
    nerd-fonts.caskaydia-cove

    # Laptop-specific networking
    speedtest-cli
    nmap
    wireguard-tools

    # GUI utilities
    xclip

    # Remote access tools
    sshfs
    rclone

    # Documentation and conversion
    pandoc

    # System utilities
    diffutils
    less
    which

    # Graphics testing tools
    glxinfo

    # VM/QEMU tools
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    virtiofsd
  ];

  ####################################################################
  # 16. SYSTEM STATE VERSION
  ####################################################################
  system.stateVersion = "23.05";
}
