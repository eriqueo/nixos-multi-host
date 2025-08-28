# nixos-hwc/modules/services/network/vpn.nix
#
# PROTONVPN SERVICE - ProtonVPN with WireGuard and CLI support
# Provides ProtonVPN connectivity via WireGuard (preferred) or CLI fallback
# with different server types (regular, P2P) and management functions
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
#   hwc.services.network.vpn.connectionMethod = "wireguard"; # or "cli"

{ config, lib, pkgs, ... }:

let
  cfg = config.hwc.services.network.vpn;
  
  # VPN management scripts following Charter V4 principles
  vpnStartScript = pkgs.writeScriptBin "vpnstart" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Starting ProtonVPN..."
    
    # Check connection method preference
    case "${cfg.connectionMethod}" in
      "wireguard")
        # Check if WireGuard is already connected
        if wg show protonvpn-us 2>/dev/null | grep -q "interface"; then
          echo "Already connected via WireGuard"
          wg show protonvpn-us
          exit 0
        fi
        
        # Start WireGuard connection
        echo "Connecting via WireGuard..."
        wg-quick up protonvpn-us
        echo "WireGuard VPN connection established!"
        wg show protonvpn-us
        ;;
      "cli"|*)
        # Check if already connected via CLI
        if protonvpn-cli status 2>/dev/null | grep -q "Connected"; then
          echo "Already connected to VPN"
          protonvpn-cli status
          exit 0
        fi
        
        echo "CLI authentication required. Please run: protonvpn-cli login"
        echo "Then try connecting again."
        exit 1
        ;;
    esac
  '';
  
  vpnStopScript = pkgs.writeScriptBin "vpnstop" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Stopping ProtonVPN..."
    
    # Stop WireGuard if running
    if wg show protonvpn-us 2>/dev/null | grep -q "interface"; then
      echo "Disconnecting WireGuard..."
      wg-quick down protonvpn-us
      echo "WireGuard VPN disconnected!"
      exit 0
    fi
    
    # Stop CLI connection if running
    if protonvpn-cli status 2>/dev/null | grep -q "Connected"; then
      protonvpn-cli disconnect
      echo "CLI VPN disconnected!"
      exit 0
    fi
    
    echo "No VPN connection found"
  '';
  
  vpnStatusScript = pkgs.writeScriptBin "vpnstatus" ''
    #!/usr/bin/env bash
    
    echo "=== VPN Connection Status ==="
    
    # Check WireGuard status
    if wg show protonvpn-us 2>/dev/null | grep -q "interface"; then
      echo "WireGuard: Connected"
      wg show protonvpn-us
    else
      echo "WireGuard: Disconnected"
    fi
    
    echo ""
    
    # Check CLI status  
    if protonvpn-cli status 2>/dev/null | grep -q "Connected"; then
      echo "ProtonVPN CLI: Connected"
      protonvpn-cli status
    else
      echo "ProtonVPN CLI: Disconnected"
    fi
  '';
  
  # WireGuard-specific scripts
  vpnWireguardScript = pkgs.writeScriptBin "vpnwg" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Connecting via WireGuard..."
    
    if wg show protonvpn-us 2>/dev/null | grep -q "interface"; then
      echo "Already connected via WireGuard"
      wg show protonvpn-us
      exit 0
    fi
    
    wg-quick up protonvpn-us
    echo "WireGuard connection established!"
    wg show protonvpn-us
  '';
  
  vpnP2PScript = pkgs.writeScriptBin "vpnp2p" ''
    #!/usr/bin/env bash
    echo "P2P servers via WireGuard: Use vpnwg command"
    echo "Note: Your WireGuard config may already be P2P-optimized"
    echo "Check your ProtonVPN account for P2P-specific configs"
  '';

in {
  #============================================================================
  # OPTIONS - What can be configured
  #============================================================================
  options.hwc.services.network.vpn = {
    enable = lib.mkEnableOption "ProtonVPN service with WireGuard and CLI support";
    
    connectionMethod = lib.mkOption {
      type = lib.types.enum [ "wireguard" "cli" ];
      default = "wireguard";
      description = "Preferred connection method (WireGuard is faster and more reliable)";
    };
    
    serverType = lib.mkOption {
      type = lib.types.enum [ "regular" "p2p" "country" ];
      default = "regular";  
      description = "Default server type for CLI connections";
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
      {
        assertion = cfg.connectionMethod == "wireguard" -> builtins.pathExists /etc/wireguard/protonvpn-us.conf;
        message = "WireGuard config file /etc/wireguard/protonvpn-us.conf must exist when using WireGuard method";
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
      vpnWireguardScript
      vpnP2PScript
    ];
    
    # NetworkManager integration for ProtonVPN
    networking.networkmanager.enable = lib.mkDefault true;
    
    # WireGuard kernel module
    networking.wireguard.enable = true;
    
    # Allow VPN connections through firewall
    networking.firewall = {
      # OpenVPN and WireGuard ports
      allowedUDPPorts = [ 1194 51820 ];
      allowedTCPPorts = [ 443 1723 ];
      
      # WireGuard port range for additional configs
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