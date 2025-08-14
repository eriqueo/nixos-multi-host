# modules/filesystem/xdg-directories.nix
# Configure XDG user directories to use PARA method structure
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # XDG USER DIRECTORIES CONFIGURATION
  ####################################################################
  # Override default XDG directories to use PARA structure
  
  # Create XDG user-dirs configuration file
  environment.etc."skel/.config/user-dirs.dirs".text = ''
    # XDG User Directories - PARA Method Integration
    # This file configures where system applications look for user directories
    
    XDG_DESKTOP_DIR="$HOME/99-temp"                    # Temporary workspace
    XDG_DOWNLOAD_DIR="$HOME/00-inbox"                  # All downloads go to inbox first
    XDG_TEMPLATES_DIR="$HOME/02-areas/05-templates"    # Templates and boilerplates
    XDG_PUBLICSHARE_DIR="$HOME/01-projects"            # Active projects (shared)
    XDG_DOCUMENTS_DIR="$HOME/01-documents"             # All documents and vaults
    XDG_MUSIC_DIR="$HOME/02-media/02-music"            # Music files
    XDG_PICTURES_DIR="$HOME/02-media/01-pictures"      # Pictures and screenshots  
    XDG_VIDEOS_DIR="$HOME/02-media/03-videos"          # Video files
  '';
  
  # Set XDG directories for all users via home-manager integration
  home-manager.users.eric = { 
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      
      # Map XDG directories to PARA structure
      desktop = "$HOME/99-temp";                        # Temporary workspace for desktop files
      download = "$HOME/00-inbox";                      # Downloads go to inbox first
      templates = "$HOME/02-areas/05-templates";        # Templates and boilerplates  
      publicShare = "$HOME/01-projects";                # Active projects
      documents = "$HOME/01-documents";                 # All documents and vaults
      music = "$HOME/02-media/02-music";                # Music files
      pictures = "$HOME/02-media/01-pictures";          # Pictures and screenshots
      videos = "$HOME/02-media/03-videos";              # Video files
    };
  };
  
  ####################################################################
  # APPLICATION DIRECTORY OVERRIDES
  ####################################################################
  # Configure applications to use PARA directories
  
  # Override applications that create their own directories
  environment.variables = {
    # Screenshots go to proper location
    XDG_PICTURES_DIR = "$HOME/02-media/01-pictures";
    XDG_SCREENSHOTS_DIR = "$HOME/02-media/01-pictures/01-screenshots";
    
    # Downloads go to inbox
    XDG_DOWNLOAD_DIR = "$HOME/00-inbox";
    
    # Documents go to proper location  
    XDG_DOCUMENTS_DIR = "$HOME/01-documents";
  };
  
  ####################################################################
  # CLEANUP SCRIPT FOR DEFAULT DIRECTORIES
  ####################################################################
  # Create script to remove default XDG directories that get recreated
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "cleanup-default-dirs" ''
      #!/bin/bash
      # Remove default XDG directories that conflict with PARA structure
      
      echo "Cleaning up default XDG directories..."
      
      # Remove empty default directories if they exist
      DEFAULT_DIRS=(
        "$HOME/Desktop"
        "$HOME/Documents" 
        "$HOME/Downloads"
        "$HOME/Music"
        "$HOME/Pictures"
        "$HOME/Videos"
        "$HOME/Templates"
        "$HOME/Public"
      )
      
      for dir in "''${DEFAULT_DIRS[@]}"; do
        if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
          echo "Removing empty directory: $dir"
          rmdir "$dir" 2>/dev/null || echo "Could not remove $dir (not empty or permission denied)"
        elif [ -d "$dir" ]; then
          echo "Directory $dir exists and is not empty - manual review needed"
        fi
      done
      
      echo "Cleanup completed. Run 'ls -la ~' to verify."
    '')
  ];
  
  ####################################################################
  # AUTOMATIC DIRECTORY MAINTENANCE
  ####################################################################
  # Prevent default directory creation and maintain symlinks automatically
  
  # Service to maintain directory structure on every boot
  systemd.services.maintain-para-structure = {
    description = "Maintain PARA directory structure and prevent default directory conflicts";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "maintain-para-structure" ''
        USER_HOME="/home/eric"
        
        # Remove any conflicting directories that might have been created
        DEFAULT_DIRS=(
          "$USER_HOME/Desktop"
          "$USER_HOME/Downloads"
          "$USER_HOME/Documents" 
          "$USER_HOME/Pictures"
          "$USER_HOME/Music"
          "$USER_HOME/Videos"
          "$USER_HOME/Templates"
          "$USER_HOME/Public"
        )
        
        for dir in "''${DEFAULT_DIRS[@]}"; do
          # Only remove if it's a directory (not our symlinks)
          if [[ -d "$dir" ]] && [[ ! -L "$dir" ]]; then
            echo "Removing conflicting directory: $dir"
            
            # Move any contents to appropriate PARA locations before removing
            case "$(basename "$dir")" in
              "Desktop") 
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/99-temp/" 2>/dev/null || true
                ;;
              "Downloads")
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/00-inbox/" 2>/dev/null || true
                ;;
              "Documents")
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/01-documents/" 2>/dev/null || true
                ;;
              "Pictures")
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/02-media/01-pictures/" 2>/dev/null || true
                ;;
              "Music")
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/02-media/02-music/" 2>/dev/null || true
                ;;
              "Videos")
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/02-media/03-videos/" 2>/dev/null || true
                ;;
              "Templates")
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/02-areas/05-templates/" 2>/dev/null || true
                ;;
              "Public")
                [[ "$(ls -A "$dir" 2>/dev/null)" ]] && mv "$dir"/* "$USER_HOME/01-projects/" 2>/dev/null || true
                ;;
            esac
            
            # Remove the directory
            rmdir "$dir" 2>/dev/null || rm -rf "$dir" 2>/dev/null || true
          fi
        done
        
        echo "PARA directory structure maintenance completed"
      '';
    };
  };
  
  # User-level service to run after login (handles user-created directories)
  systemd.user.services.user-para-maintenance = {
    description = "User-level PARA directory maintenance";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "user-para-maintenance" ''
        # Run the same cleanup for user-created directories
        cleanup-default-dirs 2>/dev/null || true
      '';
    };
  };
}