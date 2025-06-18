# ───────────────────────────────────────────────────────────────
# File: modules/ui/hyprland.nix
# NixOS module to stand up Hyprland + your startup & keybind scripts
# ───────────────────────────────────────────────────────────────
# File: modules/ui/hyprland.nix
# NixOS module to stand up Hyprland + your startup & keybind scripts
# ───────────────────────────────────────────────────────────────
{ config, pkgs, lib, ... }:
let
  # Path to your raw bindings script (you'll place this at modules/scripts/bindings.sh)
  bindsPath   = ../scripts/bindings.sh;
  # Reference the hypr-startup binary exposed by modules/scripts.nix
  startupBin  = config.packages.hyprlandScripts.startup;
  rawBinds    = builtins.readFile bindsPath;
in
{
  # Enable Hyprland the modern way
  programs.hyprland = {
    enable = true;
  };

  # Optional: Enable XWayland if needed
  programs.hyprland.xwayland.enable = true;

  # User-level Hyprland configuration using home-manager
  # You might want to move this to a home-manager configuration instead
  environment.etc."hypr/hyprland.conf".text = ''
    ${rawBinds}
    # launch your startup.sh on first seat activation
    exec-once = ${startupBin}/bin/hypr-startup
    # arrange monitors
    monitor = eDP-1,2560x1600@165,1920x0,1.6
    # input tweaks
    input {
      kb_layout     = us
      follow_mouse  = 1
      touchpad {
        natural_scroll = true
      }
    }
  '';
}
