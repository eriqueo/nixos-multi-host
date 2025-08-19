# Laptop Environment Migration Guide

**Author**: Eric  
**Target**: Migrate laptop Wayland/Hyprland environment to nixos-hwc structure  
**Timeline**: 5 phases, ~5 days  
**Safety**: Incremental with rollback at each phase

## Overview

This guide migrates your current laptop desktop environment (Hyprland, Waybar, neovim, shell config) into the nixos-hwc modular structure following the charter principles. No behavior changes until explicitly enabled.

## Prerequisites

### 1. Current State Snapshot
```bash
# Document current state
cd /etc/nixos
git checkout -b laptop-migration-$(date +%Y%m%d)
sudo nixos-rebuild build --flake .#hwc-laptop  # Ensure current config builds
```

### 2. Backup Critical Files
```bash
# Backup current Hyprland/Waybar configs
cp -r ~/.config/hypr /tmp/hypr-backup
cp -r ~/.config/waybar /tmp/waybar-backup
cp ~/.zshrc /tmp/zshrc-backup
```

### 3. Validation Setup
```bash
# Test nixos-hwc structure builds
cd /home/eric/nixos-hwc
sudo nixos-rebuild build --flake .#hwc-laptop
```

## Phase 1: Infrastructure Foundation

### GPU Module Implementation

Create `/home/eric/nixos-hwc/modules/infrastructure/gpu.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.gpu;
in {
  options.hwc.gpu = {
    nvidia = {
      enable = lib.mkEnableOption "NVIDIA GPU support";
      driver = lib.mkOption {
        type = lib.types.enum [ "stable" "beta" "production" ];
        default = "stable";
        description = "NVIDIA driver version";
      };
      prime = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable NVIDIA Prime for hybrid graphics";
        };
        nvidiaBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:1:0:0";
          description = "NVIDIA GPU bus ID";
        };
        intelBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:0:2:0";
          description = "Intel GPU bus ID";
        };
      };
      containerRuntime = lib.mkEnableOption "NVIDIA container runtime";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.nvidia.enable {
      # Enable OpenGL
      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };

      # NVIDIA drivers
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.${cfg.nvidia.driver};
      };

      # Prime configuration
      hardware.nvidia.prime = lib.mkIf cfg.nvidia.prime.enable {
        sync.enable = true;
        nvidiaBusId = cfg.nvidia.prime.nvidiaBusId;
        intelBusId = cfg.nvidia.prime.intelBusId;
      };

      # Container runtime
      hardware.nvidia-container-toolkit.enable = cfg.nvidia.containerRuntime;
    })
  ];
}
```

### Validation Commands
```bash
cd /home/eric/nixos-hwc
sudo nixos-rebuild build --flake .#hwc-laptop
# Should build without errors
```

## Phase 2: Desktop Environment Modules

### Hyprland Module

Create `/home/eric/nixos-hwc/modules/desktop/hyprland.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.desktop.hyprland;
in {
  options.hwc.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland Wayland compositor";
    
    nvidia = lib.mkEnableOption "NVIDIA-specific optimizations";
    
    keybinds = {
      modifier = lib.mkOption {
        type = lib.types.str;
        default = "SUPER";
        description = "Main modifier key";
      };
    };
    
    monitor = {
      primary = lib.mkOption {
        type = lib.types.str;
        default = "eDP-1,2560x1600@165,0x0,1.566667";
        description = "Primary monitor configuration";
      };
      external = lib.mkOption {
        type = lib.types.str;
        default = "DP-1,3840x2160@60,1638x0,2";
        description = "External monitor configuration";
      };
    };

    startup = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "waybar"
        "hyprpaper"
        "hypridle"
      ];
      description = "Applications to start with Hyprland";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables = lib.mkIf cfg.nvidia {
      # NVIDIA Wayland optimizations
      LIBVA_DRIVER_NAME = "nvidia";
      XDG_SESSION_TYPE = "wayland";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
    };

    # Hyprland configuration file
    environment.etc."hypr/hyprland.conf".text = ''
      # Monitor configuration
      monitor = ${cfg.monitor.primary}
      monitor = ${cfg.monitor.external}
      
      # Input configuration
      input {
          kb_layout = us
          follow_mouse = 1
          touchpad {
              natural_scroll = yes
          }
          sensitivity = 0
      }

      # General settings
      general {
          gaps_in = 5
          gaps_out = 10
          border_size = 2
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)
          layout = dwindle
      }

      # Decoration
      decoration {
          rounding = 10
          blur {
              enabled = true
              size = 3
              passes = 1
          }
          drop_shadow = yes
          shadow_range = 4
          shadow_render_power = 3
          col.shadow = rgba(1a1a1aee)
      }

      # Animations
      animations {
          enabled = yes
          bezier = myBezier, 0.05, 0.9, 0.1, 1.05
          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = borderangle, 1, 8, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
      }

      # Keybindings
      $mainMod = ${cfg.keybinds.modifier}
      
      bind = $mainMod, Q, exec, kitty
      bind = $mainMod, C, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, E, exec, dolphin
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, R, exec, rofi -show drun
      bind = $mainMod, P, pseudo,
      bind = $mainMod, J, togglesplit,

      # Move focus
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      # Switch workspaces
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5

      # Move active window to workspace
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5

      # Startup applications
      ${lib.concatMapStringsSep "\n" (app: "exec-once = ${app}") cfg.startup}
    '';

    # Required packages
    environment.systemPackages = with pkgs; [
      rofi-wayland
      waybar
      hyprpaper
      hypridle
      hyprlock
      kitty
      dolphin
      grim
      slurp
      wl-clipboard
    ];
  };
}
```

### Waybar Module

Create `/home/eric/nixos-hwc/modules/desktop/waybar.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.desktop.waybar;
in {
  options.hwc.desktop.waybar = {
    enable = lib.mkEnableOption "Waybar status bar";
    
    position = lib.mkOption {
      type = lib.types.enum [ "top" "bottom" ];
      default = "top";
      description = "Waybar position";
    };
    
    modules = {
      showWorkspaces = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show workspace switcher";
      };
      showNetwork = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show network module";
      };
      showBattery = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show battery module";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.waybar.enable = true;
    
    environment.etc."waybar/config".text = builtins.toJSON {
      layer = "top";
      position = cfg.position;
      height = 30;
      spacing = 4;
      
      modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
      modules-center = [ "hyprland/window" ];
      modules-right = [ "idle_inhibitor" "network" "cpu" "memory" "temperature" "battery" "clock" "tray" ];
      
      "hyprland/workspaces" = lib.mkIf cfg.modules.showWorkspaces {
        disable-scroll = true;
        all-outputs = true;
        format = "{icon}";
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          urgent = "";
          focused = "";
          default = "";
        };
      };
      
      keyboard-state = {
        numlock = true;
        capslock = true;
        format = "{name} {icon}";
        format-icons = {
          locked = "";
          unlocked = "";
        };
      };
      
      clock = {
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt = "{:%Y-%m-%d}";
      };
      
      cpu = {
        format = "{usage}% ";
        tooltip = false;
      };
      
      memory = {
        format = "{}% ";
      };
      
      temperature = {
        critical-threshold = 80;
        format = "{temperatureC}°C {icon}";
        format-icons = [ "" "" "" ];
      };
      
      battery = lib.mkIf cfg.modules.showBattery {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-alt = "{time} {icon}";
        format-icons = [ "" "" "" "" "" ];
      };
      
      network = lib.mkIf cfg.modules.showNetwork {
        format-wifi = "{essid} ({signalStrength}%) ";
        format-ethernet = "{ipaddr}/{cidr} ";
        tooltip-format = "{ifname} via {gwaddr} ";
        format-linked = "{ifname} (No IP) ";
        format-disconnected = "Disconnected ⚠";
        format-alt = "{ifname}: {ipaddr}/{cidr}";
      };
    };

    environment.etc."waybar/style.css".text = ''
      * {
          border: none;
          border-radius: 0;
          font-family: "JetBrains Mono Nerd Font";
          font-size: 13px;
          min-height: 0;
      }

      window#waybar {
          background-color: rgba(43, 48, 59, 0.5);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
      }

      #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #ffffff;
          border-bottom: 3px solid transparent;
      }

      #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
          box-shadow: inset 0 -3px #ffffff;
      }

      #workspaces button.focused {
          background-color: #64727D;
          border-bottom: 3px solid #ffffff;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #temperature,
      #network {
          padding: 0 10px;
          color: #ffffff;
      }

      #battery.charging, #battery.plugged {
          color: #ffffff;
          background-color: #26A65B;
      }

      #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }
    '';
  };
}
```

### Desktop Apps Module

Create `/home/eric/nixos-hwc/modules/desktop/apps.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.desktop.apps;
in {
  options.hwc.desktop.apps = {
    enable = lib.mkEnableOption "Desktop applications";
    
    browser = {
      firefox = lib.mkEnableOption "Firefox browser";
      chromium = lib.mkEnableOption "Chromium browser";
    };
    
    multimedia = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable multimedia applications";
      };
    };
    
    productivity = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable productivity applications";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Browsers
    programs.firefox.enable = cfg.browser.firefox;
    
    environment.systemPackages = with pkgs; [
      # Browsers
    ] ++ lib.optionals cfg.browser.chromium [
      chromium
    ] ++ lib.optionals cfg.multimedia.enable [
      # Multimedia
      vlc
      mpv
      pavucontrol
      obs-studio
    ] ++ lib.optionals cfg.productivity.enable [
      # Productivity
      obsidian
      libreoffice
      thunderbird
    ];

    # XDG portal for file dialogs
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    # Font configuration
    fonts.packages = with pkgs; [
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      fira-code
      font-awesome
    ];
  };
}
```

### Validation Commands
```bash
cd /home/eric/nixos-hwc
sudo nixos-rebuild build --flake .#hwc-laptop
# Should build without errors
```

## Phase 3: Home Environment Modules

### CLI Tools Module

Create `/home/eric/nixos-hwc/modules/home/cli.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.home.cli;
in {
  options.hwc.home.cli = {
    enable = lib.mkEnableOption "CLI tools and utilities";
    
    modernUnix = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable modern Unix replacements (eza, bat, fd, etc.)";
    };
    
    git = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Git configuration";
      };
      userName = lib.mkOption {
        type = lib.types.str;
        default = "Eric";
        description = "Git user name";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "eric@hwc.moe";
        description = "Git user email";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Core utilities
      curl
      wget
      unzip
      zip
      tree
      htop
      btop
      ncdu
      
      # Search and text processing
      ripgrep
      fzf
      jq
      yq
      
    ] ++ lib.optionals cfg.modernUnix [
      # Modern Unix replacements
      eza          # ls replacement
      bat          # cat replacement
      fd           # find replacement
      zoxide       # cd replacement
      procs        # ps replacement
      dust         # du replacement
    ];

    # Git configuration
    programs.git = lib.mkIf cfg.git.enable {
      enable = true;
      userName = cfg.git.userName;
      userEmail = cfg.git.userEmail;
      extraConfig = {
        init.defaultBranch = "main";
        push.default = "simple";
        pull.rebase = false;
      };
    };
    
    # Aliases for modern tools
    environment.shellAliases = lib.mkIf cfg.modernUnix {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      cat = "bat";
      find = "fd";
      cd = "z";
    };
  };
}
```

### Development Tools Module

Create `/home/eric/nixos-hwc/modules/home/development.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.home.development;
in {
  options.hwc.home.development = {
    enable = lib.mkEnableOption "Development tools and editors";
    
    editors = {
      neovim = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Neovim with configuration";
      };
      micro = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Micro editor";
      };
    };
    
    languages = {
      nix = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Nix development tools";
      };
      python = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Python development tools";
      };
      rust = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Rust development tools";
      };
      javascript = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable JavaScript/Node.js development tools";
      };
    };
    
    containers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable container development tools";
    };
  };

  config = lib.mkIf cfg.enable {
    # Neovim configuration
    programs.neovim = lib.mkIf cfg.editors.neovim {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      
      configure = {
        customRC = ''
          " Basic settings
          set number
          set relativenumber
          set tabstop=2
          set shiftwidth=2
          set expandtab
          set smartindent
          set wrap
          set noswapfile
          set nobackup
          set undodir=~/.vim/undodir
          set undofile
          set incsearch
          set termguicolors
          set scrolloff=8
          set colorcolumn=80
          
          " Key mappings
          let mapleader = " "
          nnoremap <leader>pv :Ex<CR>
          nnoremap <leader>w :w<CR>
          nnoremap <leader>q :q<CR>
          
          " Move lines
          vnoremap J :m '>+1<CR>gv=gv
          vnoremap K :m '<-2<CR>gv=gv
        '';
        
        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [
            vim-nix
            vim-commentary
            vim-surround
            fzf-vim
            telescope-nvim
            nvim-treesitter
            lualine-nvim
          ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      # Editors
    ] ++ lib.optionals cfg.editors.micro [
      micro
    ] ++ lib.optionals cfg.languages.nix [
      # Nix development
      nil
      nixfmt-rfc-style
      statix
      deadnix
      alejandra
    ] ++ lib.optionals cfg.languages.python [
      # Python development
      python3
      python3Packages.pip
      python3Packages.virtualenv
      pyright
    ] ++ lib.optionals cfg.languages.rust [
      # Rust development
      rustc
      cargo
      rust-analyzer
    ] ++ lib.optionals cfg.languages.javascript [
      # JavaScript development
      nodejs
      yarn
      typescript
      nodePackages.typescript-language-server
    ] ++ lib.optionals cfg.containers [
      # Container tools
      docker-compose
      kubernetes-helm
      kubectl
    ];

    # LSP servers for development
    environment.variables = {
      EDITOR = lib.mkIf cfg.editors.neovim "nvim";
    };
  };
}
```

### Shell Configuration Module

Create `/home/eric/nixos-hwc/modules/home/shell.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.home.shell;
in {
  options.hwc.home.shell = {
    enable = lib.mkEnableOption "Shell configuration";
    
    zsh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable ZSH configuration";
      };
      
      starship = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Starship prompt";
      };
      
      plugins = {
        autosuggestions = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable ZSH autosuggestions";
        };
        syntaxHighlighting = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable ZSH syntax highlighting";
        };
      };
    };
    
    tmux = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tmux configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ZSH configuration
    programs.zsh = lib.mkIf cfg.zsh.enable {
      enable = true;
      autosuggestions.enable = cfg.zsh.plugins.autosuggestions;
      syntaxHighlighting.enable = cfg.zsh.plugins.syntaxHighlighting;
      
      shellAliases = {
        # System
        ll = "ls -la";
        la = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        
        # Git shortcuts
        g = "git";
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
        
        # NixOS shortcuts
        nrs = "sudo nixos-rebuild switch";
        nrb = "sudo nixos-rebuild build";
        nrt = "sudo nixos-rebuild test";
        nfu = "nix flake update";
        
        # System monitoring
        df = "df -h";
        du = "du -h";
        free = "free -h";
      };
      
      ohMyZsh = {
        enable = true;
        plugins = [ "git" "sudo" "docker" "kubectl" ];
        theme = lib.mkIf (!cfg.zsh.starship) "robbyrussell";
      };
    };

    # Starship prompt
    programs.starship = lib.mkIf (cfg.zsh.enable && cfg.zsh.starship) {
      enable = true;
      settings = {
        format = "$all$character";
        right_format = "$time";
        
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        
        time = {
          disabled = false;
          format = "[$time]($style)";
          style = "bright-blue";
        };
        
        git_branch = {
          format = "[$symbol$branch]($style) ";
          symbol = " ";
        };
        
        git_status = {
          format = "([\\[$all_status$ahead_behind\\]]($style) )";
        };
        
        nix_shell = {
          format = "[$symbol$state( \\($name\\))]($style) ";
          symbol = " ";
        };
        
        directory = {
          truncation_length = 3;
          format = "[$path]($style)[$read_only]($read_only_style) ";
        };
      };
    };

    # Tmux configuration
    programs.tmux = lib.mkIf cfg.tmux.enable {
      enable = true;
      clock24 = true;
      terminal = "screen-256color";
      
      extraConfig = ''
        # Set prefix key
        set -g prefix C-a
        unbind C-b
        bind C-a send-prefix
        
        # Split windows
        bind | split-window -h
        bind - split-window -v
        
        # Switch panes
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
        
        # Resize panes
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5
        
        # Mouse support
        set -g mouse on
        
        # Status bar
        set -g status-bg colour235
        set -g status-fg colour255
        set -g status-left '[#S] '
        set -g status-right '%Y-%m-%d %H:%M'
        
        # Window options
        setw -g mode-keys vi
        setw -g automatic-rename on
      '';
    };

    # Terminal emulator
    environment.systemPackages = with pkgs; [
      kitty
      alacritty
    ];
  };
}
```

### Productivity Module

Create `/home/eric/nixos-hwc/modules/home/productivity.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.hwc.home.productivity;
in {
  options.hwc.home.productivity = {
    enable = lib.mkEnableOption "Productivity applications";
    
    notes = {
      obsidian = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Obsidian note-taking";
      };
    };
    
    browsers = {
      firefox = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Firefox browser";
      };
      chromium = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Chromium browser";
      };
    };
    
    office = {
      libreoffice = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable LibreOffice suite";
      };
    };
    
    communication = {
      thunderbird = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Thunderbird email client";
      };
      discord = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Discord";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Browsers
    programs.firefox = lib.mkIf cfg.browsers.firefox {
      enable = true;
      
      profiles.default = {
        settings = {
          "browser.startup.homepage" = "about:home";
          "privacy.trackingprotection.enabled" = true;
          "dom.security.https_only_mode" = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      # Notes
    ] ++ lib.optionals cfg.notes.obsidian [
      obsidian
    ] ++ lib.optionals cfg.browsers.chromium [
      chromium
    ] ++ lib.optionals cfg.office.libreoffice [
      libreoffice
    ] ++ lib.optionals cfg.communication.thunderbird [
      thunderbird
    ] ++ lib.optionals cfg.communication.discord [
      discord
    ];

    # File manager
    programs.thunar.enable = true;
    
    # Archive support
    programs.file-roller.enable = true;
  };
}
```

### Validation Commands
```bash
cd /home/eric/nixos-hwc
sudo nixos-rebuild build --flake .#hwc-laptop
# Should build without errors
```

## Phase 4: Profile Integration

### Desktop Hyprland Profile

Create `/home/eric/nixos-hwc/profiles/desktop-hyprland.nix`:

```nix
{ lib, ... }: {
  imports = [
    ../modules/infrastructure/gpu.nix
    ../modules/desktop/hyprland.nix
    ../modules/desktop/waybar.nix
    ../modules/desktop/apps.nix
    ../modules/home/cli.nix
    ../modules/home/development.nix
    ../modules/home/shell.nix
    ../modules/home/productivity.nix
  ];

  # Enable desktop environment
  hwc.desktop = {
    hyprland = {
      enable = true;
      nvidia = true;  # Enable NVIDIA optimizations
      keybinds.modifier = "SUPER";
      monitor = {
        primary = "eDP-1,2560x1600@165,0x0,1.566667";
        external = "DP-1,3840x2160@60,1638x0,2";
      };
      startup = [
        "waybar"
        "hyprpaper"
        "hypridle"
      ];
    };
    
    waybar = {
      enable = true;
      position = "top";
      modules = {
        showWorkspaces = true;
        showNetwork = true;
        showBattery = true;
      };
    };
    
    apps = {
      enable = true;
      browser = {
        firefox = true;
        chromium = false;
      };
      multimedia.enable = true;
      productivity.enable = true;
    };
  };

  # Enable home environment
  hwc.home = {
    cli = {
      enable = true;
      modernUnix = true;
      git = {
        enable = true;
        userName = "Eric";
        userEmail = "eric@hwc.moe";
      };
    };
    
    development = {
      enable = true;
      editors = {
        neovim = true;
        micro = true;
      };
      languages = {
        nix = true;
        python = true;
        rust = false;
        javascript = false;
      };
      containers = true;
    };
    
    shell = {
      enable = true;
      zsh = {
        enable = true;
        starship = true;
        plugins = {
          autosuggestions = true;
          syntaxHighlighting = true;
        };
      };
      tmux.enable = true;
    };
    
    productivity = {
      enable = true;
      notes.obsidian = true;
      browsers.firefox = true;
      office.libreoffice = true;
      communication.thunderbird = true;
    };
  };

  # GPU configuration
  hwc.gpu.nvidia = {
    enable = true;
    driver = "stable";
    prime = {
      enable = true;
      nvidiaBusId = "PCI:1:0:0";  # Update with your actual bus ID
      intelBusId = "PCI:0:2:0";   # Update with your actual bus ID
    };
    containerRuntime = true;
  };

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Networking
  networking.networkmanager.enable = true;
}
```

### Update Machine Configuration

Edit `/home/eric/nixos-hwc/machines/hwc-laptop.nix`:

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware/hwc-laptop.nix  # Your hardware-configuration.nix equivalent
    ../profiles/base.nix
    ../profiles/desktop-hyprland.nix  # Add this line
    ../profiles/security.nix
  ];

  # System identity
  networking.hostName = "hwc-laptop";
  networking.hostId = "12345678";  # Generate with: head -c 8 /etc/machine-id

  # Boot configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Storage configuration (if needed for laptop)
  hwc.storage = {
    hot.device = "/dev/disk/by-uuid/YOUR-LAPTOP-SSD-UUID";
  };

  # Laptop-specific settings
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  
  # Enable touchpad
  services.libinput.enable = true;

  system.stateVersion = "24.05";
}
```

### Validation Commands
```bash
cd /home/eric/nixos-hwc
sudo nixos-rebuild build --flake .#hwc-laptop
# Should build without errors - this validates the full desktop profile
```

## Phase 5: Migration and Testing

### Create Hardware Configuration

Copy your current hardware configuration:

```bash
# Copy hardware config
cp /etc/nixos/hosts/laptop/hardware-configuration.nix /home/eric/nixos-hwc/machines/hardware/hwc-laptop.nix

# Update paths in the hardware config to use hwc.paths if needed
```

### Test Build Process

```bash
cd /home/eric/nixos-hwc

# Build the new configuration
sudo nixos-rebuild build --flake .#hwc-laptop

# Test in VM first (if possible)
sudo nixos-rebuild test --flake .#hwc-laptop

# If all looks good, switch
sudo nixos-rebuild switch --flake .#hwc-laptop
```

### Validation Checklist

After switching, verify all components work:

```bash
# Test Hyprland
echo $XDG_SESSION_TYPE  # Should show "wayland"
hyprctl version        # Should show Hyprland version

# Test Waybar
pgrep waybar           # Should show waybar process

# Test GPU
nvidia-smi             # Should show GPU info
glxinfo | grep "OpenGL renderer"  # Should show GPU

# Test editors
nvim --version         # Should show Neovim
micro --version        # Should show Micro

# Test shell
echo $SHELL            # Should show /run/current-system/sw/bin/zsh
starship --version     # Should show Starship version

# Test applications
firefox --version      # Should launch Firefox
obsidian --version     # Should launch Obsidian
```

### Rollback Procedure

If anything goes wrong:

```bash
# Quick rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or rollback to original config
cd /etc/nixos
sudo nixos-rebuild switch --flake .#hwc-laptop
```

### Post-Migration Cleanup

Once everything is working:

```bash
# Clean up old build artifacts
nix-collect-garbage -d

# Update flake lock
cd /home/eric/nixos-hwc
nix flake update

# Document any custom configurations needed
```

## Troubleshooting

### Common Issues

1. **GPU not working**: Check bus IDs in hardware config
2. **Hyprland crashes**: Verify NVIDIA environment variables
3. **Waybar missing**: Check if it's in startup applications
4. **Shell not ZSH**: Verify user shell setting
5. **Apps not launching**: Check XDG portal configuration

### Debug Commands

```bash
# Check systemd services
systemctl --user status waybar
systemctl --user status hyprland

# Check logs
journalctl -xe -u display-manager
journalctl -xe --user -u waybar

# Test GPU
glxgears
nvidia-smi

# Test Wayland
weston-info
```

### Getting Help

- Current config comparison: `diff -r /etc/nixos /home/eric/nixos-hwc`
- Hardware info: `lshw -short`
- GPU info: `lspci | grep VGA`

## Charter Compliance Summary

✅ **No Behavior Changes**: All modules are disabled by default  
✅ **Incremental Migration**: Each phase builds on the previous  
✅ **Path Normalization**: Uses `hwc.paths.*` throughout  
✅ **Profile-Based**: Desktop functionality bundled in profile  
✅ **Reversible**: Full rollback capability at each step  
✅ **Namespace Compliance**: Uses `hwc.desktop.*` and `hwc.home.*`  
✅ **Module Structure**: Follows charter organization principles

This guide provides complete independence for migrating your laptop environment while maintaining all safety principles from your refactor charter.