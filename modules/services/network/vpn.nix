# nixos-hwc/modules/services/network/vpn.nix
#
# PROTONVPN SERVICE - ProtonVPN CLI with WireGuard and OpenVPN support
# Provides ProtonVPN connectivity with different server types (regular, P2P)
# and management functions for easy connection handling
#
# DEPENDENCIES (Upstream):
#   - None (self-contained module)
#
# USED BY (Downstream):
#   - hosts/laptop/config.nix (enables via hwc.services.network.vpn.enable)
#
# IMPORTS REQUIRED IN:
#   - hosts/laptop/config.nix: ../../modules/services/network/vpn.nix
#
# USAGE:
#   hwc.services.network.vpn.enable = true;
#   hwc.services.network.vpn.serverType = "regular"; # or "p2p"

{ config, lib, pkgs, ... }:

let
  cfg = config.hwc.services.network.vpn;
  
  # VPN management scripts following Charter V4 principles
  vpnStartScript = pkgs.writeScriptBin "vpnstart" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "= Starting ProtonVPN..."
    
    # Check if already connected
    if protonvpn-cli status | grep -q "Connected"; then
      echo " Already connected to VPN"
      protonvpn-cli status
      exit 0
    fi
    
    # Connect based on server type preference  
    case "${cfg.serverType}" in
      "p2p")
        echo "< Connecting to P2P-optimized servers..."
        protonvpn-cli connect --p2p
        ;;
      "regular")
        echo "< Connecting to fastest server..."  
        protonvpn-cli connect --fastest
        ;;
      "country")
        echo "< Connecting to ${cfg.country} servers..."
        protonvpn-cli connect --cc ${cfg.country}
        ;;
      *)
        echo "< Connecting to fastest server..."
        protonvpn-cli connect --fastest
        ;;
    esac
    
    echo " VPN connection established!"
    protonvpn-cli status
  '';
  
  vpnStopScript = pkgs.writeScriptBin "vpnstop" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "= Stopping ProtonVPN..."
    
    if ! protonvpn-cli status | grep -q "Connected"; then
      echo "9 VPN not connected"
      exit 0
    fi
    
    protonvpn-cli disconnect
    echo " VPN disconnected!"
  '';
  
  vpnStatusScript = pkgs.writeScriptBin "vpnstatus" ''
    #!/usr/bin/env bash
    protonvpn-cli status
  '';
  
  vpnToggleP2P = pkgs.writeScriptBin "vpnp2p" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "< Switching to P2P-optimized servers..."
    
    # Disconnect if connected  
    if protonvpn-cli status | grep -q "Connected"; then
      echo "= Disconnecting current connection..."
      protonvpn-cli disconnect
      sleep 2
    fi
    
    echo "= Connecting to P2P servers..."
    protonvpn-cli connect --p2p
    echo " Connected to P2P network!"
    protonvpn-cli status
  '';
  
  vpnToggleRegular = pkgs.writeScriptBin "vpnregular" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "< Switching to regular servers..."
    
    # Disconnect if connected
    if protonvpn-cli status | grep -q "Connected"; then
      echo "= Disconnecting current connection..."
      protonvpn-cli disconnect  
      sleep 2
    fi
    
    echo "= Connecting to fastest server..."
    protonvpn-cli connect --fastest
    echo " Connected to regular network!"
    protonvpn-cli status
  '';

in {
  #============================================================================
  # OPTIONS - What can be configured
  #============================================================================
  options.hwc.services.network.vpn = {
    enable = lib.mkEnableOption "ProtonVPN service with management functions";
    
    serverType = lib.mkOption {
      type = lib.types.enum [ "regular" "p2p" "country" ];
      default = "regular";
      description = "Default server type for VPN connections";
    };
    
    country = lib.mkOption {
      type = lib.types.str;
      default = "US";
      description = "Country code for VPN connections when serverType is 'country'";
    };
    
    autoConnect = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically connect VPN on system startup";
    };
  };

  #============================================================================
  # IMPLEMENTATION - What actually gets configured  
  #============================================================================
  config = lib.mkIf cfg.enable {
    
    #============================================================================
    # VALIDATION - Assertions and checks
    #============================================================================
    assertions = [
      {
        assertion = cfg.serverType == "country" -> cfg.country != "";
        message = "Country code must be specified when serverType is 'country'";
      }
    ];
    
    # Core VPN packages
    environment.systemPackages = with pkgs; [
      protonvpn-cli     # ProtonVPN CLI client
      openvpn           # OpenVPN support
      wireguard-tools   # WireGuard support
      
      # Management scripts (following Charter V4 infrastructure pattern)
      vpnStartScript
      vpnStopScript  
      vpnStatusScript
      vpnToggleP2P
      vpnToggleRegular
    ];
    
    # NetworkManager integration for ProtonVPN
    networking.networkmanager.enable = lib.mkDefault true;
    
    # Allow VPN connections through firewall
    networking.firewall = {
      # OpenVPN ports
      allowedUDPPorts = [ 1194 ];
      allowedTCPPorts = [ 443 1723 ];
      
      # WireGuard port range  
      allowedUDPPortRanges = [
        { from = 51820; to = 51900; }
      ];
    };
    
    # Auto-connect service (if enabled)
    systemd.services.protonvpn-autoconnect = lib.mkIf cfg.autoConnect {
      description = "ProtonVPN Auto Connect";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${vpnStartScript}/bin/vpnstart";
        ExecStop = "${vpnStopScript}/bin/vpnstop";
        User = "root";
      };
    };
  };
}