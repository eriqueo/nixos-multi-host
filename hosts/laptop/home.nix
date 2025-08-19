# -----------------------------------------------------------------------------
# FILE: hosts/laptop/home.nix (ORCHESTRATOR)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, osConfig, ... }:
{
  imports = [
    # Shared modules (used by both laptop and server)
    ../../shared/home-manager/core-cli.nix
    ../../shared/home-manager/development.nix
    ../../shared/home-manager/productivity.nix
    ../../shared/home-manager/zsh.nix

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

  # 2) One-time cleanup guard so your first switch won’t fail if old backups exist.
  home.activation.pruneExistingHmBackups =
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f "$HOME/.config/gtk-3.0/bookmarks.backup" \
            "$HOME/.config/gtk-3.0/bookmarks.hm-bak"
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
