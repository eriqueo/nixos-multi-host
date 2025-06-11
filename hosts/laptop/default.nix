{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
  ];

  networking.hostName = "heartwood-laptop";

  # Desktop environment
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

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
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Laptop services
  services.tlp.enable = true;
  services.printing.enable = true;
  services.flatpak.enable = true;
  services.fwupd.enable = true;

  # User groups
  users.users.eric.extraGroups = [ "networkmanager" "video" "audio" ];
  #users.users.eric.initialPassword = "changeme123";

  # SINGLE environment.systemPackages block
  environment.systemPackages = with pkgs; [
    greetd.tuigreet
    nerd-fonts.caskaydia-cove
    kitty xfce.thunar gvfs xfce.tumbler firefox
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
      
      # Missing idle/lock/wallpaper
      hypridle              # Idle management
      hyprlock              # Screen locking
      hyprpaper             # Wallpaper
      
      # Missing for screenshots
      hyprshot              # Screenshots
      grim slurp            # Screenshot tools
      
      # Missing utilities
      acpi                  # Battery info
      lm_sensors           # Temperature sensors
  ];
}
