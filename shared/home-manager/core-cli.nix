# shared/home-manager/core-cli.nix
# Essential CLI tools and utilities used on both laptop and server
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Modern CLI replacements
    bat           # Better cat with syntax highlighting
    eza           # Modern ls replacement with git integration  
    fzf           # Fuzzy finder for files and commands
    ripgrep       # Fast grep replacement (rg command)
    btop          # Modern system monitor (replaces htop)
    
    # Essential CLI utilities
    tree          # Directory tree visualization
    tmux          # Terminal multiplexer for session management
    neofetch      # System information display
    micro         # Modern terminal text editor
    
    # Network and transfer tools
    curl          # HTTP client
    wget          # File downloader
    rsync         # File synchronization
    rclone        # Cloud storage sync
    speedtest-cli # Network speed testing
    nmap          # Network scanning and discovery
    
    # Archive and compression
    zip           # ZIP archive creation
    unzip         # ZIP archive extraction
    p7zip         # 7-Zip archive support
    
    # Text and data processing
    jq            # JSON processor and formatter
    yq            # YAML processor and formatter
    pandoc        # Universal document converter
    
    # System utilities  
    xclip         # X11 clipboard utility (useful for SSH X11 forwarding)
    diffutils     # File comparison utilities
    less          # Pager for viewing large files
    which         # Command location finder
  ];

  # Configure fzf fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "find . -type f";
    defaultOptions = [ 
      "--height 40%" 
      "--reverse" 
      "--border"
      "--color=bg+:#32302f,bg:#282828,spinner:#89b482,hl:#7daea3"
      "--color=fg:#d4be98,header:#7daea3,info:#d8a657,pointer:#89b482"  
      "--color=marker:#89b482,fg+:#d4be98,prompt:#d8a657,hl+:#89b482"
    ];
  };

  # Configure tmux for session management
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    extraConfig = ''
      # Gruvbox Material theme for tmux
      set -g status-bg "#282828"
      set -g status-fg "#d4be98"
      set -g status-left-style "bg=#7daea3,fg=#282828"
      set -g status-right-style "bg=#45403d,fg=#d4be98"
      set -g window-status-current-style "bg=#7daea3,fg=#282828"
      
      # Better key bindings
      bind-key v split-window -h
      bind-key s split-window -v
      bind-key r source-file ~/.config/tmux/tmux.conf \\; display-message "Config reloaded!"
    '';
  };

  # Enhanced micro editor configuration
  programs.micro = {
    enable = true;
    settings = {
      colorscheme = "gruvbox-tc";
      autoclose = true;
      autoindent = true;
      autosave = 10;
      cursorline = true;
      diffgutter = true;
      ftoptions = true;
      ignorecase = false;
      indentchar = " ";
      infobar = true;
      keymenu = true;
      mouse = true;
      rmtrailingws = true;
      ruler = true;
      savecursor = true;
      saveundo = true;
      scrollbar = true;
      smartpaste = true;
      softwrap = false;
      splitbottom = true;
      splitright = true;
      statusformatl = "$(filename) $(modified)($(line),$(col)) $(status.paste)| ft:$(opt:filetype) | $(opt:fileformat) | $(opt:encoding)";
      statusformatr = "$(bind:ToggleKeyMenu): bindings, $(bind:ToggleHelp): help";
      tabsize = 2;
      tabstospaces = true;
    };
  };
}
