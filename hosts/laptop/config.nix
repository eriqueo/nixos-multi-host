# /etc/nixos/hosts/laptop/config.nix

{ config, pkgs, lib, ... }:

#==============================================================================
#  Host-specific NixOS configuration for “heartwood-laptop”
#==============================================================================

{
  #---------------------------------------------------------------------------
  #  1. IMPORTS: bring in shared globals, hardware, and feature modules
  #---------------------------------------------------------------------------
  imports = [
    # Global settings (users, networking, core packages, timeZone, etc.)
    ../../configuration.nix

    # Machine-specific hardware settings (bootloader, fileSystems, swap)
    ./hardware-configuration.nix

    # Core system services (Docker, SSH, Samba, etc.)
    ../../modules/services.nix

    # Wrap your shell scripts into the Nix store & expose them
    ../../modules/scripts.nix

    # Deploy your secret files under /etc/secrets
    ../../modules/secrets.nix

    # UI stack modules: Hyprland, Waybar, Stylix
    ../../modules/ui/hyprland.nix
    ../../modules/ui/waybar.nix
    ../../modules/ui/stylix.nix
  ];

  #---------------------------------------------------------------------------
  #  2. BASIC SYSTEM OPTIONS
  #---------------------------------------------------------------------------

  # Host name (used in /etc/hostname, networking)
  networking.hostName = "heartwood-laptop";

  # Time zone for the system clock & containers
  time.timeZone = "America/Denver";

  # Default shell for root (optional)
  users.users.root.shell = pkgs.zsh;

  #---------------------------------------------------------------------------
  #  3. XSERVER & DISPLAY SETTINGS
  #---------------------------------------------------------------------------

  # Enable X11/Wayland server (needed for Hyprland)
  services.xserver.enable = true;

  services.xserver.displayManager = {
    # No login manager; assume auto-login via getty or custom script
    # Uncomment and adjust if you prefer lightdm, gdm, etc.
    # displayManager.lightdm.enable = true;
    # displayManager.defaultSession = "hyprland";
  };

  #---------------------------------------------------------------------------
  #  4. SYSTEM PACKAGES
  #---------------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    vim         # Editor
    btop        # Process viewer
    ncdu        # Disk usage analyzer
    zoxide      # Smart directory jumper
    eza         # ls replacement
    # …add any host-specific packages here…
  ];

  #---------------------------------------------------------------------------
  #  5. OPTIONAL TWEAKS & HOST OVERRIDES
  #---------------------------------------------------------------------------

  # Example: custom keyboard layout
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "ctrl:nocaps";

  # Example: enable swap on a swapfile
  # swapDevices = [ { device = "/swapfile"; size = 4096; } ];

  # …any other per-host options…

}
