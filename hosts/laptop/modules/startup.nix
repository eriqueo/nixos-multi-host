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
    
    # Initialize GPU mode to Intel (default)
    echo "intel" > /tmp/gpu-mode
    
    # Launch apps directly to specific workspaces (silent mode) with GPU wrapper
    hyprctl dispatch exec '[workspace 1 silent] gpu-launch librewolf' &      # External
    sleep 1
    hyprctl dispatch exec '[workspace 2 silent] gpu-launch electron-mail' &  # External  
    sleep 1
    hyprctl dispatch exec '[workspace 3 silent] gpu-launch chromium --app=https://jobtread.com' &  # External
    sleep 1
    
    # Laptop monitor workspaces (11-18)
    hyprctl dispatch exec '[workspace 4 silent] gpu-launch obsidian' &      # Laptop
    sleep 1
    hyprctl dispatch exec '[workspace 5 silent] neovim' &         # Laptop (no GPU wrapper for terminal apps)
    sleep 1
    hyprctl dispatch exec '[workspace 6 silent] kitty' &        # Laptop
    sleep 1
    
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
