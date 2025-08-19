# shared/home-manager/core-cli.nix
{ config, pkgs, lib, ... }:

{
  ############################
  # Packages (pure binaries) #
  ############################
  home.packages = with pkgs; [
    # Modern CLI replacements
    ripgrep       # rg
    btop
    # eza/bat/fzf/zoxide are handled via programs.* below (gives you shell integration)
    fd            # pairs better with fzf than `find`
    fastfetch     # neofetch is unmaintained; fastfetch is a drop-in modern replacement

    # Essential CLI utilities
    tree          # keep if you sometimes want the classic tree output
    tmux
    micro

    # Network and transfer tools
    curl
    wget
    rsync
    rclone
    speedtest-cli
    nmap

    # Archive and compression
    zip
    unzip
    p7zip

    # Text and data processing
    jq
    yq
    pandoc

    # System utilities
    xclip
    diffutils
    less
    which
  ];

  ##########################
  # Tool integrations      #
  ##########################

  # eza: modern ls with nice defaults
  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
    extraOptions = [ "--group-directories-first" ];
  };

  # bat: better cat; also set as pager for man if you like
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      italic-text = "always";
      pager = "less -FR";
    };
  };

  # fzf: use fd for faster, smarter defaults; keep your colors/options
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    historyWidgetOptions = [ "--exact" ];
    defaultOptions = [
      "--height 40%"
      "--reverse"
      "--border"
      # your color scheme preserved
      "--color=bg+:#32302f,bg:#282828,spinner:#89b482,hl:#7daea3"
      "--color=fg:#d4be98,header:#7daea3,info:#d8a657,pointer:#89b482"
      "--color=marker:#89b482,fg+:#d4be98,prompt:#d8a657,hl+:#89b482"
    ];
  };

  # zoxide: shell hook so z/zi work; add beginner-friendly cd-like aliases
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd=z" ];
  };

  # tmux: keep your config; minor safety: ensure vi keys + sane split binds
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    extraConfig = ''
      # Gruvbox Material theme
      set -g status-bg "#282828"
      set -g status-fg "#d4be98"
      set -g status-left-style "bg=#7daea3,fg=#282828"
      set -g status-right-style "bg=#45403d,fg=#d4be98"
      set -g window-status-current-style "bg=#7daea3,fg=#282828"

      # Better key bindings
      bind-key v split-window -h
      bind-key s split-window -v
      bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
    '';
  };

  # micro: unchanged, your settings are solid
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
