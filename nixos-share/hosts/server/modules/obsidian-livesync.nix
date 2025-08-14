{ config, lib, pkgs, ... }:
{
  # This module handles Obsidian LiveSync integration
  # CouchDB and Caddy configurations are handled by separate modules
  
  # Obsidian-specific systemd service (if needed for monitoring/maintenance)
  systemd.services.obsidian-livesync-monitor = {
    description = "Monitor Obsidian LiveSync CouchDB health";
    after = [ "couchdb.service" ];
    wants = [ "couchdb.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "obsidian-health-check" ''
        # Wait for CouchDB to be ready
        echo "Checking Obsidian LiveSync CouchDB health..."
        for i in {1..30}; do
          if ${pkgs.curl}/bin/curl -s http://127.0.0.1:5984/_up > /dev/null; then
            echo "CouchDB is healthy for Obsidian LiveSync"
            exit 0
          fi
          echo "Waiting for CouchDB... ($i/30)"
          sleep 2
        done
        echo "CouchDB failed to start properly"
        exit 1
      '';
    };
    # Don't auto-start this - it's just for manual health checks
    # wantedBy = [ "multi-user.target" ];
  };
  
  # Future: Add Obsidian-specific monitoring, backup tasks, etc.
}