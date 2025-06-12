# ───────────────────────────────────────────────────────────────
# File: modules/ui/hyprland.nix
# NixOS module to stand up Hyprland + your startup & keybind scripts
# ───────────────────────────────────────────────────────────────
{ config, pkgs, lib, ... }:

let
  # Path to your raw bindings script (you’ll place this at modules/scripts/bindings.sh)
  bindsPath   = ../scripts/bindings.sh;
  # Reference the hypr-startup binary exposed by modules/scripts.nix
  startupBin  = config.packages.hyprlandScripts.startup;
  rawBinds    = builtins.readFile bindsPath;
in
{
  services.xserver = {
    enable = true;

    windowManager.hyprland = {
      enable             = true;
      systemdIntegration = true;

      # inject your binds.sh HCL lines verbatim
      settings.extraConfig = ''
        ${rawBinds}

        # launch your startup.sh on first seat activation
        exec-once = ${startupBin}

        # arrange monitors
        monitor = eDP-1,2560x1600@165,1920x0,1.6

        # input tweaks
        input = {
          kb_layout     = "us";
          follow_mouse  = 1;
          touchpad = {
            natural_scroll = true;
          };
        };
      '';
    };
  };
}
