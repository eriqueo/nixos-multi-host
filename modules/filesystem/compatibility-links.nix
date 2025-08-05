# modules/filesystem/compatibility-links.nix
# Create symlinks and environment variables for traditional file structure compatibility
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # TRADITIONAL DIRECTORY SYMLINKS
  ####################################################################
  # Create symlinks so applications expecting standard directories work seamlessly
  
  systemd.tmpfiles.rules = [
    # Traditional directory symlinks pointing to PARA structure
    "L /home/eric/Desktop - - - - /home/eric/99-temp"                    # Desktop → temp workspace
    "L /home/eric/Downloads - - - - /home/eric/00-inbox"                 # Downloads → inbox
    "L /home/eric/Documents - - - - /home/eric/01-documents"             # Documents → documents
    "L /home/eric/Pictures - - - - /home/eric/02-media/01-pictures"      # Pictures → media/pictures
    "L /home/eric/Music - - - - /home/eric/02-media/02-music"            # Music → media/music
    "L /home/eric/Videos - - - - /home/eric/02-media/03-videos"          # Videos → media/videos
    "L /home/eric/Templates - - - - /home/eric/02-areas/05-templates"    # Templates → templates
    "L /home/eric/Public - - - - /home/eric/01-projects"                 # Public → projects
    
    # Additional common application directories
    "L /home/eric/Dropbox - - - - /home/eric/00-inbox/dropbox"           # Dropbox → inbox/dropbox
    "L /home/eric/OneDrive - - - - /home/eric/00-inbox/onedrive"         # OneDrive → inbox/onedrive
    "L /home/eric/Google Drive - - - - /home/eric/00-inbox/google-drive" # Google Drive → inbox/google-drive
    
    # Development directories (common expectations)
    "L /home/eric/Code - - - - /home/eric/01-projects"                   # Code → projects
    "L /home/eric/Development - - - - /home/eric/01-projects"            # Development → projects
    "L /home/eric/Projects - - - - /home/eric/01-projects"               # Projects → projects
    "L /home/eric/Workspace - - - - /home/eric/01-projects/workspace"    # Workspace → projects/workspace
    
    # Media application shortcuts
    "L /home/eric/Photos - - - - /home/eric/02-media/01-pictures"        # Photos → media/pictures
    "L /home/eric/Screenshots - - - - /home/eric/02-media/01-pictures/01-screenshots" # Screenshots
    "L /home/eric/Camera - - - - /home/eric/02-media/01-pictures/99-inbox" # Camera imports
    
    # Create subdirectories for cloud services
    "d /home/eric/00-inbox/dropbox 0755 eric users -"
    "d /home/eric/00-inbox/onedrive 0755 eric users -"
    "d /home/eric/00-inbox/google-drive 0755 eric users -"
    
    # Create marker files to indicate PARA management
    "f /home/eric/.para-managed 0644 eric users - PARA directory structure managed by NixOS"
    "f /home/eric/00-inbox/.para-managed 0644 eric users - Inbox managed by PARA system"
    "f /home/eric/01-documents/.para-managed 0644 eric users - Documents managed by PARA system"
    "f /home/eric/02-media/.para-managed 0644 eric users - Media managed by PARA system"
  ];
  
  ####################################################################
  # ENVIRONMENT VARIABLES FOR APPLICATION COMPATIBILITY
  ####################################################################
  # Set environment variables that applications commonly use
  
  environment.sessionVariables = {
    # XDG Base Directory specification (override for compatibility)
    XDG_DESKTOP_DIR = "$HOME/99-temp";
    XDG_DOWNLOAD_DIR = "$HOME/00-inbox";
    XDG_TEMPLATES_DIR = "$HOME/02-areas/05-templates";
    XDG_PUBLICSHARE_DIR = "$HOME/01-projects";
    XDG_DOCUMENTS_DIR = "$HOME/01-documents";
    XDG_MUSIC_DIR = "$HOME/02-media/02-music";
    XDG_PICTURES_DIR = "$HOME/02-media/01-pictures";
    XDG_VIDEOS_DIR = "$HOME/02-media/03-videos";
    
    # Common application environment variables
    PHOTOS_DIR = "$HOME/02-media/01-pictures";
    PICTURES_DIR = "$HOME/02-media/01-pictures";
    MUSIC_DIR = "$HOME/02-media/02-music";
    VIDEOS_DIR = "$HOME/02-media/03-videos";
    DOCUMENTS_DIR = "$HOME/01-documents";
    DOWNLOADS_DIR = "$HOME/00-inbox";
    DESKTOP_DIR = "$HOME/99-temp";
    PROJECTS_DIR = "$HOME/01-projects";
    CODE_DIR = "$HOME/01-projects";
    WORKSPACE_DIR = "$HOME/01-projects/workspace";
    
    # Screenshots and media applications
    SCREENSHOT_DIR = "$HOME/02-media/01-pictures/01-screenshots";
    CAMERA_DIR = "$HOME/02-media/01-pictures/99-inbox";
    
    # Development environments
    DEV_DIR = "$HOME/01-projects";
    SRC_DIR = "$HOME/01-projects";
    BUILD_DIR = "$HOME/99-temp/build";
    
    # Cloud storage paths (for applications that support env vars)
    DROPBOX_DIR = "$HOME/00-inbox/dropbox";
    ONEDRIVE_DIR = "$HOME/00-inbox/onedrive";
    GOOGLE_DRIVE_DIR = "$HOME/00-inbox/google-drive";
    
    # Business specific paths
    BUSINESS_DIR = "$HOME/02-areas/01-business";
    JOBTREAD_DIR = "$HOME/02-areas/01-business/01-jobtread";
    
    # Archive and backup paths
    BACKUP_DIR = "$HOME/04-archive";
    ARCHIVE_DIR = "$HOME/04-archive";
    
    # Temporary and processing
    TEMP_DIR = "$HOME/99-temp";
    TMP_DIR = "$HOME/99-temp";
    PROCESSING_DIR = "$HOME/99-temp";
  };
  
  ####################################################################
  # APPLICATION-SPECIFIC OVERRIDES
  ####################################################################
  # Configure specific applications that are known to be problematic
  
  # Home manager configuration for user-level application overrides
  home-manager.users.eric = {
    # Configure git to use proper directories
    programs.git = {
      extraConfig = {
        core = {
          # Use temp directory for git temporary files
          tmpdir = "$HOME/99-temp";
        };
      };
    };
    
    # Configure shell aliases for common directory access
    programs.zsh.shellAliases = {
      # Quick navigation aliases that match traditional expectations
      desktop = "cd ~/99-temp";
      downloads = "cd ~/00-inbox";
      documents = "cd ~/01-documents";
      pictures = "cd ~/02-media/01-pictures";
      music = "cd ~/02-media/02-music";
      videos = "cd ~/02-media/03-videos";
      projects = "cd ~/01-projects";
      code = "cd ~/01-projects";
      workspace = "cd ~/01-projects/workspace";
      
      # PARA method aliases
      inbox = "cd ~/00-inbox";
      areas = "cd ~/02-areas";
      archive = "cd ~/04-archive";
      temp = "cd ~/99-temp";
      
      # Business shortcuts
      business = "cd ~/02-areas/01-business";
      jobtread = "cd ~/02-areas/01-business/01-jobtread";
      vaults = "cd ~/01-documents/01-vaults";
      
      # Media shortcuts
      screenshots = "cd ~/02-media/01-pictures/01-screenshots";
      photos = "cd ~/02-media/01-pictures";
    };
    
    # Configure file manager bookmarks
    gtk.gtk3.bookmarks = [
      "file:///home/eric/00-inbox Inbox"
      "file:///home/eric/01-projects Projects"
      "file:///home/eric/01-documents Documents"
      "file:///home/eric/02-media Media"
      "file:///home/eric/02-media/01-pictures Pictures"
      "file:///home/eric/02-areas Areas"
      "file:///home/eric/04-archive Archive"
      "file:///home/eric/99-temp Temp"
      "file:///home/eric/02-areas/01-business Business"
      "file:///home/eric/01-documents/01-vaults Vaults"
    ];
  };
  
  ####################################################################
  # COMPATIBILITY MONITORING
  ####################################################################
  # Script to check and maintain compatibility links
  
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "check-compatibility-links" ''
      echo "🔗 Checking Traditional Directory Compatibility Links"
      echo "=================================================="
      
      # Check all symlinks
      LINKS=(
        "Desktop:99-temp"
        "Downloads:00-inbox"
        "Documents:01-documents"
        "Pictures:02-media/01-pictures"
        "Music:02-media/02-music"
        "Videos:02-media/03-videos"
        "Templates:02-areas/05-templates"
        "Public:01-projects"
        "Code:01-projects"
        "Projects:01-projects"
        "Photos:02-media/01-pictures"
      )
      
      echo ""
      echo "📁 Traditional Directory Links:"
      for link_info in "''${LINKS[@]}"; do
        link_name=$(echo "$link_info" | cut -d: -f1)
        target_path=$(echo "$link_info" | cut -d: -f2)
        full_path="$HOME/$link_name"
        
        if [[ -L "$full_path" ]]; then
          actual_target=$(readlink "$full_path")
          expected_target="$HOME/$target_path"
          if [[ "$actual_target" == "$expected_target" ]]; then
            echo "  ✅ $link_name → $target_path"
          else
            echo "  ⚠️  $link_name → $(basename "$actual_target") (expected: $target_path)"
          fi
        elif [[ -d "$full_path" ]]; then
          echo "  ❌ $link_name (directory exists, not symlink)"
        else
          echo "  ❌ $link_name (missing)"
        fi
      done
      
      echo ""
      echo "🔧 Environment Variables:"
      echo "  PHOTOS_DIR: ''${PHOTOS_DIR:-not set}"
      echo "  PROJECTS_DIR: ''${PROJECTS_DIR:-not set}"
      echo "  XDG_PICTURES_DIR: ''${XDG_PICTURES_DIR:-not set}"
      echo "  XDG_DOCUMENTS_DIR: ''${XDG_DOCUMENTS_DIR:-not set}"
      
      echo ""
      echo "💡 To fix broken links, run: sudo nixos-rebuild switch"
    '')
    
    (pkgs.writeShellScriptBin "fix-app-paths" ''
      echo "🔧 Application Path Compatibility Fixer"
      echo "======================================"
      
      # Common applications that might create directories
      PROBLEM_DIRS=(
        "$HOME/Desktop"
        "$HOME/Downloads" 
        "$HOME/Documents"
        "$HOME/Pictures"
        "$HOME/Music"
        "$HOME/Videos"
      )
      
      for dir in "''${PROBLEM_DIRS[@]}"; do
        if [[ -d "$dir" ]] && [[ ! -L "$dir" ]]; then
          echo "Found non-symlink directory: $dir"
          echo "  Moving contents to appropriate PARA location..."
          
          case "$(basename "$dir")" in
            "Desktop")
              if [[ "$(ls -A "$dir" 2>/dev/null)" ]]; then
                mv "$dir"/* "$HOME/99-temp/" 2>/dev/null || true
              fi
              ;;
            "Downloads")
              if [[ "$(ls -A "$dir" 2>/dev/null)" ]]; then
                mv "$dir"/* "$HOME/00-inbox/" 2>/dev/null || true
              fi
              ;;
            "Documents")
              if [[ "$(ls -A "$dir" 2>/dev/null)" ]]; then
                mv "$dir"/* "$HOME/01-documents/" 2>/dev/null || true
              fi
              ;;
            "Pictures")
              if [[ "$(ls -A "$dir" 2>/dev/null)" ]]; then
                mv "$dir"/* "$HOME/02-media/01-pictures/" 2>/dev/null || true
              fi
              ;;
            "Music")
              if [[ "$(ls -A "$dir" 2>/dev/null)" ]]; then
                mv "$dir"/* "$HOME/02-media/02-music/" 2>/dev/null || true
              fi
              ;;
            "Videos")
              if [[ "$(ls -A "$dir" 2>/dev/null)" ]]; then
                mv "$dir"/* "$HOME/02-media/03-videos/" 2>/dev/null || true
              fi
              ;;
          esac
          
          # Remove the directory after moving contents
          rmdir "$dir" 2>/dev/null || echo "  Could not remove $dir (not empty)"
        fi
      done
      
      echo ""
      echo "Running nixos-rebuild to recreate proper symlinks..."
      sudo nixos-rebuild switch
      
      echo ""
      echo "✅ Path compatibility fix completed!"
      echo "Run 'check-compatibility-links' to verify results."
    '')
  ];
  
  ####################################################################
  # ADDITIONAL COMPATIBILITY CONFIGURATIONS
  ####################################################################
  # Handle specific application configurations
  
  # Firefox/Chrome download directory (if needed)
  environment.etc."firefox-download-override.js".text = ''
    // Firefox download directory override
    user_pref("browser.download.dir", "/home/eric/00-inbox");
    user_pref("browser.download.folderList", 2);
  '';
  
  # VSCode settings for workspace directories
  environment.etc."vscode-settings-override.json".text = builtins.toJSON {
    "files.defaultLocation" = "/home/eric/01-projects";
    "terminal.integrated.cwd" = "/home/eric/01-projects";
    "workbench.startupEditor" = "newUntitledFile";
    "explorer.openEditors.visible" = 10;
  };
}