# -----------------------------------------------------------------------------
# UPDATED: hosts/laptop/config.nix (SYSTEM LEVEL - CLEANED)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

{
  imports = [
  
    ./hardware-configuration.nix  
    ../../modules/secrets/secrets.nix
    # REMOVED: UI modules are now in Home Manager
  ];

  networking.hostName = "heartwood-laptop";
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
  # Enable Hyprland at system level
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # LOGIN MANAGER
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

  # GRAPHICS & AUDIO (laptop-specific hardware)
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

  # NETWORKING & BLUETOOTH (laptop mobility features)
  networking.networkmanager.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      DiscoverableTimeout = 0;
      AutoEnable = true;
    };
  };

  # PRINTING (laptop-specific)
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
virtualisation.podman = {
  enable = true;
  dockerCompat = true;
  defaultNetwork.settings.dns_enabled = true;
};
virtualisation.oci-containers.backend = "podman";
  # ESSENTIAL SYSTEM PACKAGES (laptop-only)
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
    python3 nodejs gh speedtest-cli nmap wireguard-tools
  sshfs rclone xclip usbutils pciutils dmidecode powertop
  python3Packages.pip

  ];
}