# -----------------------------------------------------------------------------
# UPDATED: hosts/laptop/config.nix (SYSTEM LEVEL - CLEANED)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix  
    ../../modules/secrets/secrets.nix
    # REMOVED: UI modules are now in Home Manager
  ];

  networking.hostName = "heartwood-laptop";

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

  # ESSENTIAL SYSTEM PACKAGES (laptop-only)
  environment.systemPackages = with pkgs; [
    greetd.tuigreet
    jq                    # For monitor scripts
    system-config-printer
    cups
    acpi                  # Battery info
    lm_sensors           # Laptop sensors
    nerd-fonts.caskaydia-cove
    hyprsome
  ];
}