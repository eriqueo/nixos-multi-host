# modules/filesystem/user-directories.nix
# Consolidated user directory structure for Eric
{ config, lib, pkgs, ... }:

{
  ####################################################################
  # USER HOME DIRECTORY STRUCTURE
  ####################################################################
  systemd.tmpfiles.rules = [
    # NixOS configuration access permissions
    "Z /etc/nixos - eric users - -"
    
    # Main user directory
    "d /home/eric 0755 eric users -"
    
    # ADHD-friendly numbered organization system
    # Based on PARA method adapted for ADHD productivity
    "d /home/eric/00-inbox 0755 eric users -"          # Unsorted incoming items
    "d /home/eric/01-projects 0755 eric users -"       # Active projects with deadlines
    "d /home/eric/02-areas 0755 eric users -"          # Ongoing responsibilities
    "d /home/eric/04-archive 0755 eric users -"        # Completed/inactive items
    "d /home/eric/99-temp 0755 eric users -"           # Temporary workspace
    
    # Document management structure 
    "d /home/eric/01-documents 0755 eric users -"              # All documents
    "d /home/eric/01-documents/01-vaults 0755 eric users -"    # Obsidian vaults
    
    # Media management structure
    "d /home/eric/02-media 0755 eric users -"                  # All media files
    "d /home/eric/02-media/01-pictures 0755 eric users -"      # Pictures and screenshots
    "d /home/eric/02-media/02-music 0755 eric users -"         # Music files
    "d /home/eric/02-media/03-videos 0755 eric users -"        # Video files
    
    # PARA subdirectories - Areas (ongoing responsibilities)
    "d /home/eric/02-areas/01-business 0755 eric users -"      # Business files
    "d /home/eric/02-areas/02-personal 0755 eric users -"      # Personal files  
    "d /home/eric/02-areas/03-tech 0755 eric users -"          # Technology files
    "d /home/eric/02-areas/05-templates 0755 eric users -"     # Reusable templates
    
    # Resources at top level
    "d /home/eric/03-resources-adhd-course 0755 eric users -"  # ADHD course materials
    
    # Projects subdirectories
    "d /home/eric/01-projects/Business 0755 eric users -"      # Business projects
    "d /home/eric/01-projects/workspace 0755 eric users -"     # Development workspace
    "d /home/eric/01-projects/nixos-md 0755 eric users -"      # NixOS configuration
    
    # Standard user configuration directories
    "d /home/eric/.config 0755 eric users -"
    "d /home/eric/.local 0755 eric users -"
    "d /home/eric/.local/bin 0755 eric users -"
    
    # Secure SSH directory
    "d /home/eric/.ssh 0700 eric users -"              # SSH keys and config (secure)
  ];
  
  ####################################################################
  # USER DIRECTORY DOCUMENTATION
  ####################################################################
  # Create helpful README files for the directory structure
  environment.etc."user-directories-help.md".text = ''
    # User Directory Structure Guide
    
    ## ADHD-Friendly Organization System
    
    This directory structure follows the PARA method adapted for ADHD:
    
    ### 📥 00-inbox/
    - **Purpose**: Capture all incoming items before processing
    - **Usage**: Email attachments, downloaded files, quick notes
    - **Rule**: Everything goes here first, then gets sorted
    
    ### 🎯 01-projects/
    - **Purpose**: Active projects with specific deadlines
    - **Usage**: Current work with clear outcomes and timelines
    - **Examples**: Client work, coding projects, home improvements
    
    ### 🔄 02-areas/
    - **Purpose**: Ongoing areas of responsibility
    - **Usage**: Maintenance activities, continuous learning
    - **Examples**: Health, finances, home maintenance, skills
    
    ### 📦 04-archive/
    - **Purpose**: Completed or inactive items
    - **Usage**: Finished projects, old versions, historical data
    - **Rule**: Move here when projects are complete
    
    ### 🔄 99-temp/
    - **Purpose**: Temporary workspace for active tasks
    - **Usage**: Work-in-progress, scratch files, experiments
    - **Rule**: Clean regularly, move to appropriate locations
    
    ## Document Management (/home/eric/01-documents/)
    
    ### 📑 01-vaults/
    - **Purpose**: Obsidian knowledge vaults  
    - **Location**: `/home/eric/01-documents/01-vaults/`
    - **Contents**: 00_tech, 01_hwc, 02_personal vaults
    
    ## Media Management (/home/eric/02-media/)
    
    ### 📸 01-pictures/
    - **Purpose**: Photo collections and screenshots
    - **Location**: `/home/eric/02-media/01-pictures/`
    - **Contents**: Project photos, screenshots, reference images
    
    ### 🎵 02-music/
    - **Purpose**: Music library and audio files
    - **Location**: `/home/eric/02-media/02-music/`
    - **Contents**: Music collection, podcasts, audio recordings
    
    ### 🎬 03-videos/
    - **Purpose**: Video files and recordings
    - **Location**: `/home/eric/02-media/03-videos/`
    - **Contents**: Personal videos, recordings, video projects
    
    ## Areas Organization (/home/eric/02-areas/)

    ### 💼 01-business/
    - **Purpose**: Business-related files and documents
    - **Location**: `/home/eric/02-areas/01-business/`
    
    ### 👤 02-personal/
    - **Purpose**: Personal files and documents  
    - **Location**: `/home/eric/02-areas/02-personal/`
    
    ### 💻 03-tech/
    - **Purpose**: Technology files and resources
    - **Location**: `/home/eric/02-areas/03-tech/`
    
    ### 📋 05-templates/
    - **Purpose**: Reusable templates and boilerplates
    - **Location**: `/home/eric/02-areas/05-templates/`
    - **Usage**: Project templates, code boilerplates, forms
    - **Examples**: Project structures, email templates, configs
    
    ## Resources (/home/eric/)
    
    ### 📚 03-resources-adhd-course/
    - **Purpose**: ADHD management course materials
    - **Location**: `/home/eric/03-resources-adhd-course/`
    - **Contents**: Video courses, PDFs, and learning materials
    
    ## Tips for ADHD Management
    
    1. **Use the inbox**: Always capture first, sort later
    2. **Review regularly**: Weekly cleanup of 99-temp and 00-inbox
    3. **Name descriptively**: Use clear, searchable folder names
    4. **Automate cleanup**: Use scripts to maintain organization
    5. **Visual cues**: Use consistent naming patterns
  '';
}