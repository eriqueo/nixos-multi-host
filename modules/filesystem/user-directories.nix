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
    "d /home/eric/03-resources 0755 eric users -"      # Reference materials
    "d /home/eric/04-archive 0755 eric users -"        # Completed/inactive items
    "d /home/eric/05-templates 0755 eric users -"      # Reusable templates
    "d /home/eric/99-temp 0755 eric users -"           # Temporary workspace
    
    # Standard user configuration directories
    "d /home/eric/.config 0755 eric users -"
    "d /home/eric/.local 0755 eric users -"
    "d /home/eric/.local/bin 0755 eric users -"
    
    # Secure SSH directory
    "d /home/eric/.ssh 0700 eric users -"              # SSH keys and config (secure)
    
    # Development workspace
    "d /home/eric/dev 0755 eric users -"
    "d /home/eric/dev/heartwood-craft 0755 eric users -"
    "d /home/eric/dev/scripts 0755 eric users -"
    "d /home/eric/dev/experiments 0755 eric users -"
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
    
    ### 📚 03-resources/
    - **Purpose**: Reference materials for future use
    - **Usage**: Documentation, tutorials, research materials
    - **Examples**: Code snippets, design assets, technical docs
    
    ### 📦 04-archive/
    - **Purpose**: Completed or inactive items
    - **Usage**: Finished projects, old versions, historical data
    - **Rule**: Move here when projects are complete
    
    ### 📋 05-templates/
    - **Purpose**: Reusable templates and boilerplates
    - **Usage**: Project templates, code boilerplates, forms
    - **Examples**: Project structures, email templates, configs
    
    ### 🔄 99-temp/
    - **Purpose**: Temporary workspace for active tasks
    - **Usage**: Work-in-progress, scratch files, experiments
    - **Rule**: Clean regularly, move to appropriate locations
    
    ## Development Workspace (/home/eric/dev/)
    
    ### heartwood-craft/
    - Main business and personal projects
    
    ### scripts/
    - Utility scripts and automation tools
    
    ### experiments/
    - Testing new technologies and ideas
    
    ## Tips for ADHD Management
    
    1. **Use the inbox**: Always capture first, sort later
    2. **Review regularly**: Weekly cleanup of 99-temp and 00-inbox
    3. **Name descriptively**: Use clear, searchable folder names
    4. **Automate cleanup**: Use scripts to maintain organization
    5. **Visual cues**: Use consistent naming patterns
  '';
}