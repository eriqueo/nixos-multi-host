# -----------------------------------------------------------------------------
# FILE: hosts/laptop/home.nix (ORCHESTRATOR)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, osConfig, ... }:

let
  # Define the single source of truth for colors, available to all imports
  colors = (import ../../shared/colors/deep-nord.nix).colors;
in
{
  imports = [
    # Shared modules (used by both laptop and server)
    ../../shared/home-manager/core-cli.nix
    ../../shared/home-manager/development.nix
    ../../shared/home-manager/productivity.nix
    ../../shared/home-manager/zsh.nix
    # --- NEWLY MODULARIZED COMPONENTS ---
    # We pass the 'colors' palette to the modules that need it
    (import ../../shared/home-manager/kitty.nix { inherit colors; })
    (import ../../shared/home-manager/obsidian.nix { inherit lib colors; })
    (import ../../shared/home-manager/thunar.nix { inherit pkgs; })
    ../../shared/home-manager/ai/transcript-formatter.nix

    # Laptop-specific modules
    ./modules/desktop-apps.nix
    ./modules/media.nix
    ./modules/graphics.nix
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/theming.nix
    ./modules/startup.nix
    ./modules/virtualization.nix
    ./modules/betterbird.nix
    ./modules/blender.nix
  ];
  # 1) Make HM own the file (source-of-truth in your repo) and always overwrite it.
  xdg.configFile."gtk-3.0/bookmarks" = {
    # pick ONE: use text inline OR source a tracked file in your repo
    # text = ''
    #   file:///home/eric/Documents
    #   file:///home/eric/Downloads
    # '';
    source = ./gtk/bookmarks;   # <- put a canonical file under hosts/laptop/gtk/bookmarks
    force  = true;              # <- skip backups and clobber non-symlink targets
  };
  my.ai.transcriptFormatter = {
    enable = true;
    model = "llama3";
    host = "http://127.0.0.1:11434";
    inputDir = "${config.xdg.dataHome}/transcripts/input_transcripts";
    outputDir = "${config.xdg.dataHome}/transcripts/cleaned_transcripts";
    interval = "15m";
  };
  # 2) Universal cleanup guard to prevent Home Manager backup conflicts system-wide
  home.activation.pruneAllHmBackups =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      # Remove all backup files that could cause Home Manager conflicts
      # This prevents the backup.backup.backup chain and allows clean rebuilds
      echo "Cleaning Home Manager backup files to prevent conflicts..."

      # Clean config directory backup files
      find "$HOME/.config" -name "*.backup*" -type f -delete 2>/dev/null || true
      find "$HOME/.config" -name "*.hm-bak*" -type f -delete 2>/dev/null || true

      # Clean other common Home Manager directories
      find "$HOME/.local" -name "*.backup*" -type f -delete 2>/dev/null || true
      find "$HOME/.local" -name "*.hm-bak*" -type f -delete 2>/dev/null || true

      # Clean specific known problematic files
      rm -f "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml.backup"* || true
      rm -f "$HOME/.config/nvim/init.lua.backup"* || true
      rm -f "$HOME/.config/micro/settings.json.backup"* || true

      echo "Backup cleanup complete - Home Manager can now manage files cleanly"
    '';
  # IDENTITY
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  # SHARED MODULE CONFIGURATIONS
  # The following are imported from shared modules:
  # - Core CLI tools (bat, eza, fzf, ripgrep, btop, micro, tmux, etc.)
  # - Development tools (git, python3, nodejs, gh, etc.)
  # - Productivity apps (obsidian, pandoc, espanso) with directory structure
  # - ZSH configuration with enhanced aliases and functions

  # XDG desktop integration and directory structure handled by shared modules

}
