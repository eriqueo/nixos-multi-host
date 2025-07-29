# NixOS Server Rescue ISO Configuration
# 
# This creates a bootable ISO with server configuration files included
# Usage: nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso-server-rescue.nix
#
{ config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  # Include server configuration files in the ISO
  environment.etc = {
    "nixos/hosts".source = ./hosts;
    "nixos/modules".source = ./modules;
    "nixos/lib".source = ./lib;
    "nixos/shared".source = ./shared;
    "nixos/scripts".source = ./scripts;
    "nixos/secrets".source = ./secrets;
    "nixos/flake.nix".source = ./flake.nix;
    "nixos/flake.lock".source = ./flake.lock;
  };

  # Add useful tools for rescue operations
  environment.systemPackages = with pkgs; [
    git
    vim
    nano
    htop
    tree
    rsync
    parted
    gptfdisk
    ntfs3g
    dosfstools
    e2fsprogs
    cryptsetup
    tmux
    wget
    curl
  ];

  # Enable SSH for remote rescue operations
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Root login enabled via SSH (password will be empty, set manually if needed)

  # Enable networking
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  # Helpful aliases for rescue operations
  environment.shellAliases = {
    ll = "ls -la";
    rebuild-server = "nixos-rebuild switch --flake /etc/nixos#server";
    mount-server = "mount /dev/disk/by-uuid/42d7ef27-5af7-4929-b0f4-f6247d4b1551 /mnt && mount /dev/disk/by-uuid/01C8-BA8F /mnt/boot";
  };

  # ISO label
  isoImage.isoName = "nixos-server-rescue.iso";
  isoImage.volumeID = "NIXOS_SERVER_RESCUE";
}