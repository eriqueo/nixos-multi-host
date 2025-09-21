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

  # Configure PARA method documentation (directories are created by systemd.tmpfiles.rules)
  home.file = {

    # Productivity system documentation
    "04-ref/templates/directory_README.md".text = ''
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
    # ADHD-friendly shortcuts using PARA method
    INBOX_DOCS = "$HOME/01-documents/99-inbox";
    INBOX_PICS = "$HOME/05-media/pictures";
    ACTIVE_PROJECTS = "$HOME/01-hwc/01-active";
    BUSINESS_DOCS = "$HOME/02-areas/01-business";

    # Obsidian vault locations
    TECH_VAULT = "$HOME/99-vaults/00_tech";
    BUSINESS_VAULT = "$HOME/99-vaults/01_hwc";
    PERSONAL_VAULT = "$HOME/99-vaults/02_personal";
    NIXOS_VAULT = "$HOME/99-vaults/03_nixos";
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
