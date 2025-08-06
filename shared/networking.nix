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
    # Note: Tailscale DNS (100.100.100.100) is managed automatically via services.tailscale.acceptDNS
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
      dns = "none";  # Prevent NetworkManager from overriding DNS settings
    };
  };
  
  ####################################################################
  # NETWORK ROBUSTNESS
  ####################################################################
  # Predictable network interface names for stability
  networking.usePredictableInterfaceNames = true;
  
  # Network time synchronization
  # Enhanced DNS resolution with systemd-resolved for public Wi-Fi compatibility
  services.resolved = {
    enable = true;
    # Fallback DNS servers for when primary servers are unreachable
    fallbackDns = [ 
      "1.1.1.1"       # Cloudflare
      "8.8.8.8"       # Google
      "9.9.9.9"       # Quad9
    ];
    # Enable DNS-over-TLS for enhanced privacy/security
    dnssec = "allow-downgrade";
  };

  services.timesyncd.enable = true;
  
  ####################################################################
  # SHARED VPN AND SSH SERVICES
  ####################################################################
  # Tailscale VPN mesh networking
  services.tailscale = {
    enable = true;
    # Use extraUpFlags to accept DNS settings from Tailscale for MagicDNS
    extraUpFlags = [
      "--accept-dns=true"
    ];
  };
  
  # SSH configuration - shared settings
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}