{ config, pkgs, lib, ... }:

{
  ####################################################################
  # 1. IMPORTS
  #
  # – ../../configuration.nix: timeZone, default users, any global pkgs
  # – ./hardware-configuration.nix: this laptop’s disks & bootloader
  # – ../../modules/services.nix: Podman containers & back-end daemons
  # – ../../modules/scripts.nix: hypr-startup & hypr-bindings
  # – ../../modules/secrets.nix: /etc/secrets/*
  # – ../../modules/ui/…: Hyprland, Waybar, Stylix modules
  ####################################################################
  imports = [
    ../../configuration.nix
    ./hardware-configuration.nix
   # ../../modules/services.nix
    ../../modules/scripts/scripts.nix
    ../../modules/secrets/secrets.nix
    ../../modules/ui/hyprland.nix
    ../../modules/ui/stylix.nix
  ];

  ####################################################################
  # 2. HOST IDENTITY
  ####################################################################
  networking.hostName = "heartwood-laptop";

  ####################################################################
  # 3. GLOBAL → configuration.nix
  #
  # Move these truly-shared settings into ../../configuration.nix:
  #   time.timeZone
  #   users.users.eric
  #   any global environment.systemPackages
  ####################################################################

  ####################################################################
  # 4. DISPLAY & LOGIN (HYPRLAND SESSION)
  ####################################################################
  services.greetd = {
  	enable = true;
  	settings = {
  		default_session = {
  			user    = "greeter";
  			command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
  		};
  		initial_session = {
  			user    = "eric";
  	        command = "Hyprland";
  		};
  	  };	
  	};
  	 
 
  services.xserver.enable = true;
  services.xserver.displayManager = { };
  # Hyprland itself is enabled/configured in modules/ui/hyprland.nix

  ####################################################################
  # 5. AUDIO STACK
  ####################################################################
  security.rtkit.enable = true;
  services.pipewire = {
    enable       = true;
    alsa.enable  = true;
    pulse.enable = true;
  };

  ####################################################################
  # 6. GRAPHICS & PORTALS
  ####################################################################
  hardware.graphics.enable = true;
  xdg.portal.enable     = true;
  xdg.portal.wlr.enable = true;

  ####################################################################
  # 7. NETWORKING & BLUETOOTH
  ####################################################################
  networking.networkmanager.enable = true;
  hardware.bluetooth = {
    enable      = true;
    powerOnBoot = true;
    settings = {
      General = {
        DiscoverableTimeout = 0;
        AutoEnable         = true;
      };
    };
  };

  services.printing = {
  	enable = true;
	drivers = with pkgs;[
		gutenprint 
		hplip
		brlaser
		brgenml1lpr
		cnijfilter2
	 ];
	};
  services.avahi = {
  	enable = true;
  	nssmdns4 = true;
  	openFirewall = true;
  	};
     
    
  ####################################################################
  # 8. SYSTEM PACKAGES (LAPTOP-ONLY)
  ####################################################################
  environment.systemPackages = with pkgs; [
    # Greetd UI
    greetd.tuigreet

    # Fonts
    nerd-fonts.caskaydia-cove

    # File manager & thumbnails
    xfce.thunar
    gvfs
    xfce.tumbler

    # Email
    electron-mail
    # protonmail-desktop
    # protonmail-bridge

    # Waybar dependencies
    pavucontrol
    brightnessctl
    networkmanager
    wirelesstools

    # Notifications & clipboard
    swaynotificationcenter
    cliphist
    wl-clipboard

    # Hardware utils
    system-config-printer
    cups
    acpi
    lm_sensors
  ];
}
