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
    ../../modules/filesystem         # Consolidated filesystem structure
    ../../modules/vault-sync-system.nix  # NixOS vault sync system
    
    # Shared configuration
    ../../shared/secrets.nix         # Shared secrets management
    # REMOVED: UI modules are now in Home Manager
  ];

  ####################################################################
  # 2. HOST IDENTITY
  ####################################################################
  networking.hostName = "hwc-laptop";
  # File ownership rules now handled in modules/users/eric.nix

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
  # 4.1. SOPS SECRETS CONFIGURATION
  ####################################################################
  sops.age.keyFile = "/etc/sops/age/keys.txt";

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
  # ZSH system enablement now handled in modules/users/eric.nix

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
  # 13. POWER MANAGEMENT (laptop-specific)
  ####################################################################
  services.thermald.enable = true;
  services.tlp.enable = true;
  powerManagement.enable = true;
  
  ####################################################################
  # 14. LAPTOP-SPECIFIC SYSTEM PACKAGES
  ####################################################################
  # Core packages now provided by modules/users/eric.nix
  # Only laptop-specific packages are included here
  environment.systemPackages = with pkgs; [
    # Login Manager
    greetd.tuigreet

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
  ];

  ####################################################################
  # 15. SYSTEM STATE VERSION
  ####################################################################
  system.stateVersion = "23.05";
}
