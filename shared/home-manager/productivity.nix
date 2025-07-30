# shared/home-manager/productivity.nix
# Cross-platform productivity applications and tools
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Note-taking and knowledge management
    obsidian         # Cross-platform note-taking (works via X11 forwarding on server)
    
    # Document processing
    pandoc           # Universal document converter
    
    # Text expansion for ADHD-friendly workflows
    espanso          # Text expansion tool
  ];

  # Configure directory structure for productivity workflows
  home.file = {
    # Documents organization (ADHD-friendly numbering system)
    "Documents/00-templates/.keep".text = "Templates and forms directory";
    "Documents/01-vaults/.keep".text = "Obsidian vaults directory";  
    "Documents/02-active/.keep".text = "Current projects directory";
    "Documents/03-business/.keep".text = "Admin and business docs directory";
    "Documents/04-reference/.keep".text = "Manuals and guides directory";
    "Documents/05-archive/.keep".text = "Completed projects directory";
    "Documents/99-inbox/.keep".text = "Unsorted documents to be processed";

    # Pictures organization (consistent with documents)
    "Pictures/00-meta/.keep".text = "Icons, wallpapers, templates";
    "Pictures/01-screenshots/.keep".text = "Work captures and system docs";
    "Pictures/02-receipts/.keep".text = "Business receipts (syncs to server)";
    "Pictures/03-projects/.keep".text = "Jobsite photos and documentation";
    "Pictures/04-reference/.keep".text = "Documentation photos and examples";
    "Pictures/05-archive/.keep".text = "Family photos and old projects";
    "Pictures/99-inbox/.keep".text = "Unsorted photos to be processed";

    # Business directory (future server mount point)
    "Business/.keep".text = "Future mount point to server /opt/business/";

    # Productivity system documentation
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

  # Environment variables for productivity workflows
  home.sessionVariables = {
    # ADHD-friendly shortcuts
    INBOX_DOCS = "$HOME/Documents/99-inbox";
    INBOX_PICS = "$HOME/Pictures/99-inbox";
    ACTIVE_PROJECTS = "$HOME/Documents/02-active";
    BUSINESS_DOCS = "$HOME/Documents/03-business";
    
    # Obsidian vault locations
    TECH_VAULT = "$HOME/Documents/01-vaults/00_tech";
    BUSINESS_VAULT = "$HOME/Documents/01-vaults/01_business";
    PERSONAL_VAULT = "$HOME/Documents/01-vaults/02_personal";
  };

  # Basic espanso configuration for text expansion
  home.file.".config/espanso/config/default.yml".text = ''
    matches:
      # Email templates
      - trigger: "@@email"
        replace: "eriqueo@proton.me"
      
      # Common business phrases
      - trigger: "@@hc"
        replace: "Heartwood Craft"
      
      # Date shortcuts
      - trigger: "@@date"
        replace: "{{mydate}}"
        vars:
          - name: mydate
            type: date
            params:
              format: "%Y-%m-%d"
      
      # Time shortcuts
      - trigger: "@@time"
        replace: "{{mytime}}"
        vars:
          - name: mytime
            type: date
            params:
              format: "%H:%M"
  '';
}