# -----------------------------------------------------------------------------
# FILE: hosts/laptop/home.nix (ORCHESTRATOR)
# -----------------------------------------------------------------------------
{ config, pkgs, lib, osConfig, ... }:
{
  imports = [
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/theming.nix
    ./modules/startup.nix
    ./modules/apps.nix
    ../../shared/home-manager/zsh.nix
  ];

  # IDENTITY
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;

  # XDG desktop integration for file manager
  xdg.enable = true;

  # STANDARDIZED DIRECTORY STRUCTURE
  home.file = {
    # Documents structure
    "Documents/00-templates/.keep".text = "Templates and forms directory";
    "Documents/01-vaults/.keep".text = "Obsidian vaults directory";  
    "Documents/02-active/.keep".text = "Current projects directory";
    "Documents/03-business/.keep".text = "Admin and business docs directory";
    "Documents/04-reference/.keep".text = "Manuals and guides directory";
    "Documents/05-archive/.keep".text = "Completed projects directory";
    "Documents/99-inbox/.keep".text = "Unsorted documents to be processed";

    # Pictures structure  
    "Pictures/00-meta/.keep".text = "Icons, wallpapers, templates";
    "Pictures/01-screenshots/.keep".text = "Work captures and system docs";
    "Pictures/02-receipts/.keep".text = "Business receipts (syncs to server)";
    "Pictures/03-projects/.keep".text = "Jobsite photos and documentation";
    "Pictures/04-reference/.keep".text = "Documentation photos and examples";
    "Pictures/05-archive/.keep".text = "Family photos and old projects";
    "Pictures/99-inbox/.keep".text = "Unsorted photos to be processed";

    # Business directory (future server mount point)
    "Business/.keep".text = "Future mount point to server /opt/business/";

    # README for the directory philosophy
    "Documents/00-templates/README.md".text = ''
      # Directory Organization Philosophy
      
      ## Numbering System (00-05 + 99)
      - **00**: Templates, meta, overview materials
      - **01**: Primary category (vaults, screenshots, etc.)
      - **02**: Secondary category (active work, receipts, etc.) 
      - **03**: Tertiary category (business, projects, etc.)
      - **04**: Quaternary category (reference materials)
      - **05**: Archive (completed, historical)
      - **99**: Inbox (unsorted, to be processed)
      
      ## Rule of 7
      Maximum 7 folders per directory. If you need more:
      1. Combine similar items into subdirectories
      2. Rename categories to be more inclusive
      3. Archive old items to 05-archive
      
      ## Server Integration
      This structure mirrors future server organization for:
      - Database file references
      - Automated processing workflows  
      - Cross-device synchronization
    '';
  };

}