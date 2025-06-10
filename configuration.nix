{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

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
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    time.timeZone = "America/Denver";
    i18n.defaultLocale = "en_US.UTF-8";

    environment.systemPackages = with pkgs; [
      vim micro wget curl git tree htop neofetch unzip zip
      python3 nodejs gh speedtest-cli nmap wireguard-tools
      jq yq pandoc p7zip rsync sshfs rclone xclip
      tmux bat eza fzf ripgrep btop
      usbutils pciutils dmidecode powertop lvm2 cryptsetup
      nfs-utils samba
      ntfs3g exfatprogs dosfstools
      diffutils less which
      python3Packages.pip 
     
    ]
    
    ++ lib.optionals config.server [
      podman-compose iotop lsof strace
      ffmpeg-full
    ];

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    services.tailscale.enable = true;

    users.users.eric = {
      isNormalUser = true;
      home = "/home/eric";
      description = "Eric - Heartwood Craft";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ]
        ++ lib.optionals config.laptop [ "networkmanager" "video" "audio" ]
        ++ lib.optionals config.server [ "docker" "podman" ];
      openssh.authorizedKeys.keys = lib.optionals config.server [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQFHXbcZCYrqyJoRPJddpEpnEquRJUxtopQkZsZdGhl hwc@laptop"
      ];
      initialPassword = lib.mkIf config.laptop "changeme123";
    };

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    nixpkgs.config.allowUnfree = true;

    networking.firewall = {
      enable = true;
      allowedTCPPorts = lib.mkIf config.server [
        22 2283 4533 5000 7878 8080 8096 8123 8686 8989 9696
      ];
      allowedUDPPorts = lib.mkIf config.server [
        7359 8555
      ];
      interfaces = lib.mkIf config.server {
        "tailscale0" = {
          allowedTCPPorts = [
            5432 6379 8000 8501 11434 1883
          ];
        };
      };
    };

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

    programs.hyprland = lib.mkIf config.desktop {
      enable = true;
      xwayland.enable = true;
      
    };


    programs.zsh.enable = true;

    security.rtkit.enable = lib.mkIf config.desktop true;
    services.pipewire = lib.mkIf config.desktop {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hardware.graphics = lib.mkIf config.desktop { enable = true; };
    services.gvfs.enable = true;     # For mounting, trash, network drives, etc.
  services.tumbler.enable = true;  # For thumbnail previews in Thunar
    services.libinput.enable = true;
    services.libinput.touchpad = {
      naturalScrolling = true;
      tapping = true;
      disableWhileTyping = true;
    };

    services.upower.enable = lib.mkIf config.laptop true;
    services.logind = lib.mkIf config.laptop {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "ignore";
    };

    xdg.portal = lib.mkIf config.desktop {
      enable = true;
      wlr.enable = true;
    };

    virtualisation = {
      podman = lib.mkIf config.server {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      docker.enable = lib.mkIf config.desktop true;
      oci-containers.backend = lib.mkIf config.server "podman";
    };

    services.flatpak.enable = lib.mkIf config.desktop true;

    system.stateVersion = "23.05";
  };
}
