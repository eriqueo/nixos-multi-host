# -----------------------------------------------------------------------------
# SERVER HOME MANAGER CONFIGURATION - Heartwood Craft Homeserver
# User-level configuration for business intelligence and server management
# Focused on CLI productivity, ADHD tools, and business automation
# -----------------------------------------------------------------------------
{ config, pkgs, ... }:

{
  imports = [
    ../../shared/home-manager/core-cli.nix
    ../../shared/home-manager/development.nix  
    ../../shared/home-manager/productivity.nix
    ../../shared/home-manager/zsh.nix
  ];
  ####################################################################
  # 1. HOME MANAGER IDENTITY
  ####################################################################
  home.username = "eric";
  home.homeDirectory = "/home/eric";
  home.stateVersion = "25.11";

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  ####################################################################
  # 2. SERVER-SPECIFIC PACKAGES
  ####################################################################
  home.packages = with pkgs; [
    # Server-specific tools
        #    okular        # PDF viewer (for X11 forwarding)
    
    # Additional server utilities can be added here
  ];

  ####################################################################
  # 3. SERVER-SPECIFIC ENVIRONMENT VARIABLES
  ####################################################################
  home.sessionVariables = {
    # Business intelligence URLs
    BUSINESS_API_URL = "http://localhost:8000";
    OLLAMA_API_URL = "http://localhost:11434";
    DATABASE_URL = "postgresql://business_user:secure_password_change_me@localhost:5432/heartwood_business";
  };

  ####################################################################
  # 4. SHARED MODULE CONFIGURATIONS
  ####################################################################
  # The following are imported from shared modules:
  # - Core CLI tools (bat, eza, fzf, ripgrep, btop, micro, tmux, etc.)
  # - Development tools (git, python3, nodejs, gh, etc.)  
  # - Productivity apps (obsidian, pandoc, espanso)
  # - ZSH configuration with enhanced aliases and functions
}
