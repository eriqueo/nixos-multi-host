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
    
    # Shared configuration
    ../../shared/secrets.nix         # Shared secrets management
    # REMOVED: UI modules are now in Home Manager
  ];

  ####################################################################
  # 2. HOST IDENTITY
  ####################################################################
  networking.hostName = "heartwood-laptop";
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
  hardware.graphics.enable = true;
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
  services.auto-cpufreq.enable = true;
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
  ];

  ####################################################################
  # 15. SYSTEM STATE VERSION
  ####################################################################
  system.stateVersion = "23.05";
}
