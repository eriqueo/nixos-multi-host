# shared/networking.nix - Common networking configuration for all hosts
{ lib, config, pkgs, ... }:

{
  ####################################################################
  # SHARED DNS CONFIGURATION
  ####################################################################
  # DNS nameservers - shared across all hosts for reliability
  networking.nameservers = [ 
    "1.1.1.1"         # Cloudflare DNS (primary)
    "8.8.8.8"         # Google DNS (secondary)  
    "100.100.100.100" # Tailscale Magic DNS (*.ts.net domains)
  ];
  
  ####################################################################
  # NETWORKMANAGER SHARED CONFIGURATION
  ####################################################################
  # Enable NetworkManager on all hosts
  networking.networkmanager.enable = true;
  
  # Critical settings to preserve hostname and prevent grebuild issues
  networking.networkmanager.settings = {
    main = {
      plugins = "keyfile";
      "hostname-mode" = "none";  # Prevents NetworkManager from changing hostname
    };
  };
  
  ####################################################################
  # NETWORK ROBUSTNESS
  ####################################################################
  # Predictable network interface names for stability
  networking.usePredictableInterfaceNames = true;
  
  # Network time synchronization
  services.timesyncd.enable = true;
  
  ####################################################################
  # SHARED VPN AND SSH SERVICES
  ####################################################################
  # Tailscale VPN mesh networking
  services.tailscale.enable = true;
  
  # SSH configuration - shared settings
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}