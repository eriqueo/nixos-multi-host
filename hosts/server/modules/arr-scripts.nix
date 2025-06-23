# /etc/nixos/modules/arr-scripts.nix
{ config, pkgs, ... }:

{
  # Create necessary directories
  systemd.tmpfiles.rules = [
    # Lidarr directories
    "d /opt/lidarr 0755 eric users -"
    "d /opt/lidarr/config 0755 eric users -"
    "d /opt/lidarr/custom-services.d 0755 eric users -"
    "d /opt/lidarr/custom-cont-init.d 0755 eric users -"
    
    # Radarr directories
    "d /opt/radarr 0755 eric users -"
    "d /opt/radarr/config 0755 eric users -"
    "d /opt/radarr/custom-services.d 0755 eric users -"
    "d /opt/radarr/custom-cont-init.d 0755 eric users -"
    
    # Sonarr directories
    "d /opt/sonarr 0755 eric users -"
    "d /opt/sonarr/config 0755 eric users -"
    "d /opt/sonarr/custom-services.d 0755 eric users -"
    "d /opt/sonarr/custom-cont-init.d 0755 eric users -"
  ];

  # Service to download initialization script
  systemd.services.setup-arr-scripts = {
    description = "Setup RandomNinjaAtk arr-scripts";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "eric";
      Group = "users";
      RemainAfterExit = true;
    };
    
    script = ''
      # Download scripts_init.bash for each service
      
      # Lidarr
      ${pkgs.curl}/bin/curl -o /opt/lidarr/custom-cont-init.d/scripts_init.bash \
        https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/lidarr/scripts_init.bash
      chmod +x /opt/lidarr/custom-cont-init.d/scripts_init.bash
      
      # Only create extended.conf if it doesn't exist
      if [ ! -f /opt/lidarr/config/extended.conf ]; then
        ${pkgs.curl}/bin/curl -o /opt/lidarr/config/extended.conf \
          https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/lidarr/extended.conf.example
      fi
      
      # Radarr
      ${pkgs.curl}/bin/curl -o /opt/radarr/custom-cont-init.d/scripts_init.bash \
        https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/radarr/scripts_init.bash
      chmod +x /opt/radarr/custom-cont-init.d/scripts_init.bash
      
      if [ ! -f /opt/radarr/config/extended.conf ]; then
        ${pkgs.curl}/bin/curl -o /opt/radarr/config/extended.conf \
          https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/radarr/extended.conf.example
      fi
      
      # Sonarr
      ${pkgs.curl}/bin/curl -o /opt/sonarr/custom-cont-init.d/scripts_init.bash \
        https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/sonarr/scripts_init.bash
      chmod +x /opt/sonarr/custom-cont-init.d/scripts_init.bash
      
      if [ ! -f /opt/sonarr/config/extended.conf ]; then
        ${pkgs.curl}/bin/curl -o /opt/sonarr/config/extended.conf \
          https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/sonarr/extended.conf.example
      fi
      
      echo "RandomNinjaAtk arr-scripts setup complete"
    '';
  };
}
