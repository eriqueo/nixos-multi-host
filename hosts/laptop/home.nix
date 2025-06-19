{ config, pkgs, lib, osConfig, ... }:
# ########################################
# File: hosts/laptop/home.nix
# Home-Manager config for user "eric" on your laptop
# ########################################
{
  imports = [
    ../../modules/ui/waybar.nix
  ];

  # ========================================
  # IDENTITY & STATE
  # ========================================
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "23.05";

  # Let Home-Manager update itself
  programs.home-manager.enable = true;

  # ========================================
  # STANDARDIZED DIRECTORY STRUCTURE
  # ========================================
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
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  # ========================================
  # APPLICATION PACKAGES
  # ========================================
  home.packages = with pkgs; [
    
    # HYPRLAND ECOSYSTEM
    # Core window manager components and tools
    wofi                    # Application launcher (rofi alternative for Wayland)
    hyprshot               # Screenshot tool for Hyprland
    hypridle               # Idle management (screen timeout, lock)
    hyprpaper              # Wallpaper manager for Hyprland
    
    # TERMINAL & SYSTEM UTILITIES
    # Command-line tools and system monitoring
    kitty                  # GPU-accelerated terminal emulator
    htop                   # Interactive process viewer
    neofetch              # System information display
    brightnessctl         # Screen brightness control
    acpi                  # Battery and power information
    lm_sensors            # Hardware sensor monitoring
    
    # NOTIFICATIONS & CLIPBOARD
    # Desktop integration services
    mako                  # Notification daemon (alternative to dunst)
    swaynotificationcenter # Notification center for Wayland
    cliphist              # Clipboard history manager
    wl-clipboard          # Wayland clipboard utilities
    
    # NETWORKING & CONNECTIVITY
    # Network management and wireless tools
    networkmanager        # Network connection management
    wirelesstools         # Wireless network utilities
    kdePackages.kdeconnect-kde # Phone integration and file sharing
    
    # PRODUCTIVITY SUITE
    # Office applications and document handling
    obsidian              # Note-taking and knowledge management
    libreoffice           # Office suite (documents, spreadsheets, presentations)
    electron-mail         # ProtonMail desktop client
    zathura               # Lightweight PDF viewer
    
    # DEVELOPMENT TOOLS
    # Code editors and version control
    vscodium              # Open-source VS Code (without telemetry)
    git                   # Version control system
    
    # CREATIVE APPLICATIONS
    # Graphics, design, and media creation
    gimp                  # Image editing and manipulation
    inkscape              # Vector graphics editor
    blender               # 3D modeling and animation
    
    # MEDIA & ENTERTAINMENT
    # Audio/video players and downloaders
    vlc                   # Versatile media player
    mpv                   # Lightweight video player
    qbittorrent           # BitTorrent client
    
    # FILE MANAGEMENT
    # File browsers and archive handling
    imv                   # Image viewer for Wayland
    file-roller           # Archive manager (zip, tar, etc.)
    
    # SYSTEM MAINTENANCE
    # Backup and system management tools
    blueman               # Bluetooth device manager
    timeshift             # System backup and restore
    udiskie               # Automatic disk mounting
    redshift              # Blue light filter for eye strain
    
    # FONTS
    # Typography and display fonts
    noto-fonts            # Google's font family with wide language support
    noto-fonts-emoji      # Emoji font support
  ];

  # ========================================
  # BROWSER CONFIGURATIONS
  # ========================================
  
  # Privacy-focused browser (librewolf)
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;  # Privacy-hardened Firefox fork
  };
  
  # Development browser (ungoogled chromium)
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;  # Chrome without Google tracking
  };

  # ========================================
  # SHELL CONFIGURATION
  # ========================================
  programs.zsh = {
    enable = true;
    # Directory navigation shortcuts for standardized structure
    shellAliases = {
      # Quick directory navigation
      "cdactive" = "cd ~/Documents/02-active";
      "cdbusiness" = "cd ~/Documents/03-business";
      "cdinbox" = "cd ~/Documents/99-inbox";
      "cdvaults" = "cd ~/Documents/01-vaults";
      
      # Picture directories
      "screenshots" = "cd ~/Pictures/01-screenshots";
      "receipts" = "cd ~/Pictures/02-receipts";
      "projects" = "cd ~/Pictures/03-projects";
      
      # System shortcuts
      "rebuild" = "sudo nixos-rebuild switch --flake /etc/nixos#heartwood-laptop";
    };
  };

  # ========================================
  # THEME CONFIGURATION
  # ========================================
  
  # Stylix: point Firefox at your profile for theming
  stylix.targets.firefox.profileNames = [ "3bp09ufp.default" ];
}
