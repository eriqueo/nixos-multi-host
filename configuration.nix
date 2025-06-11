{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

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
    ];
    users.users.eric = {
      isNormalUser = true;
      home = "/home/eric";
      description = "Eric - Heartwood Craft";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQFHXbcZCYrqyJoRPJddpEpnEquRJUxtopQkZsZdGhl hwc@laptop"
      ];
      initialPassword = "il0wwlm?";
    };  
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
    programs.zsh.enable = true;
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;               # Enables `docker` CLI compatibility
      defaultNetwork.settings.dns_enabled = true;
    };
   # virtualisation.docker.enable = true;  # Enable Docker service if needed
    virtualisation.oci-containers.backend = "podman";  # Use Podman as OCI backend


    system.stateVersion = "23.05";
  };
}
