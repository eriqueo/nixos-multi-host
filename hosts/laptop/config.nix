{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
    ../../modules/scripts.nix     # exposes config.packages.hyprlandScripts.{startup,bindings}
    ../../modules/ui/hyprland.nix # or inline below
  ];

  networking.hostName = "heartwood-laptop";

  stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.caskaydia-cove;
          name = "CaskaydiaCove Nerd Font";
        };
        sizes = {
          terminal = 13;
        };
      };
    };
  # Desktop environment
  services.xserver = {
    enable     = true;
    windowManager.hyprland = {
      enable            = true;
      systemdIntegration = true;  # optional, for better session hooks

      # Autostart your startup.sh
      settings.execOnce = [
        config.packages.hyprlandScripts.startup
      ];


      
  services.upower.enable = true;  # Battery status for desktop environments
  services.logind = {
    lidSwitch = "suspend";        # Suspend on lid close
    lidSwitchExternalPower = "lock"; # Just lock when on AC power
  };
  # Login manager
  services.greetd = {
    enable = true;
    settings = {
    	default_session = {
      		command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
     		user = "greeter";
    	};
    	initial_session = {
    		command = "Hyprland";
    		user = "eric";
    	};
    };	
  };

  # Audio - USE PIPEWIRE (not PulseAudio for modern systems)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Graphics
  hardware.graphics.enable = true;
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;

  # Networking and hardware
  networking.networkmanager.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        AutoConnect = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
  services.blueman.enable = true;

  # Laptop services
  services.tlp.enable = true;
  services.printing.enable = true;
  services.flatpak.enable = true;
  services.fwupd.enable = true;

  # User groups
  users.users.eric.extraGroups = [ "networkmanager" "video" "audio" "wheel" "storage" ];
  #users.users.eric.initialPassword = "changeme123";

  # SINGLE environment.systemPackages block
  environment.systemPackages = with pkgs; [
    greetd.tuigreet
    nerd-fonts.caskaydia-cove
    xfce.thunar gvfs xfce.tumbler
    electron-mail
    # protonmail-desktop
    # protonmail-bridge
      
      # Missing Waybar dependencies
      pavucontrol        # For audio control
      brightnessctl      # For brightness control (laptop)
      networkmanager     # For network module
      wirelesstools      # For wifi info
      
      # Missing notification/clipboard
      swaynotificationcenter  # Notifications
      cliphist               # Clipboard manager
      wl-clipboard          # Wayland clipboard
           
      # Missing utilities
      acpi                  # Battery info
      lm_sensors           # Temperature sensors
  ];
}
