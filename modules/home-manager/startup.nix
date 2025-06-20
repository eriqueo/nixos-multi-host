#-----------------------------------------------------------------------------
# FILE : modules/home-manager/ui/startup.nix (SESSION STARTUP)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, ... }:

let
  hyprStartup = pkgs.writeScriptBin "hypr-startup" ''
    #!/usr/bin/env bash
    
    # Wait until Hyprland is ready
    until hyprctl monitors > /dev/null 2>&1; do
      sleep 0.2
    done
    
    # Background services
    sleep 2
    
    # Start waybar
    pkill waybar
    sleep 1
    waybar >/dev/null 2>&1 &
    sleep 2
    
    # Launch apps directly to specific workspaces (silent mode)
    hyprctl dispatch exec '[workspace 1 silent] librewolf' &
    sleep 1
    hyprctl dispatch exec '[workspace 2 silent] electron-mail' &
    sleep 1
    hyprctl dispatch exec '[workspace 3 silent] chromium --app=https://jobtread.com' &
    sleep 1
    hyprctl dispatch exec '[workspace 4 silent] obsidian' &
    sleep 1
    hyprctl dispatch exec '[workspace 5 silent] kitty' &
    sleep 1
    hyprctl dispatch exec '[workspace 6 silent] codium' &
    sleep 1
    hyprctl dispatch exec '[workspace 7 silent] qbittorrent' &
    
    # Stay on workspace 1
    hyprctl dispatch workspace 1
    echo "Startup complete"
  '';
in
{
  # Install startup script
  home.packages = [ hyprStartup ];
  
  # Session services can be added here
  systemd.user.services = {
    # Example: Auto-start clipboard history
    cliphist = {
      Unit = {
        Description = "Clipboard history daemon";
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "always";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}