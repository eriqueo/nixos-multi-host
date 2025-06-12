# ───────────────────────────────────────────────────────────────
# File: modules/ui/waybar.nix
# Home-Manager module to install Waybar + your JSON & CSS
# ───────────────────────────────────────────────────────────────
{ config, pkgs, lib, ... }:

let
  # Paths under modules/ui/waybar/files/ that you should create:
  cfgJson = ./files/config.json;
  styleCss = ./files/style.css;
in
{
  programs.waybar = {
    enable = true;
    # if you prefer not to use the default systemd user service:
    systemd.enable = false;
  };

  # Drop in your JSON config
  home.file."config/waybar/config.json" = {
    source     = cfgJson;
    # if you want it executable: executable = false;
  };

  # Drop in your CSS style
  home.file."config/waybar/style.css" = {
    source     = styleCss;
  };
}
