# Home Manager Restructure Implementation Plan
**Created**: 2025-01-30
**Purpose**: Comprehensive guide for restructuring Home Manager configuration across laptop and server hosts

## **Current State Analysis**
- **Good**: Separate laptop/server home.nix files with shared zsh.nix
- **Issues**: 
  - Mixed package management (some apps in system config, others in home config)
  - Limited shared modules (only zsh currently shared)
  - Manual config files instead of using Home Manager program modules
  - Inconsistent theming approach

## **Target Architecture**

```
/etc/nixos/
├── shared/home-manager/
│   ├── core-cli.nix       # Essential CLI tools (both hosts)
│   ├── development.nix    # Git, Python, Node.js, dev tools
│   ├── productivity.nix   # Obsidian, micro, shared productivity
│   ├── theming.nix        # Gruvbox theme for all programs
│   └── zsh.nix           # Shell configuration (existing)
├── hosts/laptop/modules/
│   ├── desktop-apps.nix   # GUI applications
│   ├── media.nix          # Audio/video applications  
│   ├── graphics.nix       # Design tools (GIMP, Inkscape)
│   ├── hyprland.nix       # Window manager (existing)
│   ├── waybar.nix         # Status bar (existing)
│   └── startup.nix        # Session startup (existing)
└── hosts/server/
    └── home.nix           # Server-specific config
```

## **Phase 1: Create Documentation & Shared Modules**

### 1.1 Core CLI Module (`shared/home-manager/core-cli.nix`)
**Purpose**: Essential command-line tools used on both laptop and server
**Contents**:
- Modern CLI alternatives: bat, eza, fzf, ripgrep, btop
- System utilities: tree, tmux, neofetch, micro
- Network tools: curl, wget, rsync, speedtest-cli
- Archive tools: zip, unzip, p7zip
- Text processing: jq, yq

### 1.2 Development Module (`shared/home-manager/development.nix`)
**Purpose**: Development tools and programming languages
**Contents**:
- Git configuration with proper user settings
- Python 3 with pip and virtualenv
- Node.js and npm
- GitHub CLI (gh)
- Common development utilities

### 1.3 Productivity Module (`shared/home-manager/productivity.nix`)
**Purpose**: Cross-platform productivity applications
**Contents**:
- Obsidian (works on both GUI and headless via X11 forwarding)
- Micro editor configuration
- Pandoc for document conversion
- Basic office tools that work on both hosts

## **Phase 2: Restructure Laptop Configuration**

### 2.1 Package Migration
**Move FROM system config TO home config**:
- claude-code CLI tool
- Fonts (nerd-fonts.caskaydia-cove) 
- GUI utilities (xclip, etc.)
- Development tools
- User-specific networking tools

**KEEP in system config**:
- Hardware drivers (nvidia, audio)
- System services (networking, printing, bluetooth)
- Login manager and system-level configurations

### 2.2 Modular Restructure
**Create laptop-specific modules**:

**desktop-apps.nix**:
- Browsers (Firefox/LibreWolf, Chromium)
- Communication (electron-mail)
- File management (thunar, file-roller)
- System utilities (blueman, timeshift)

**media.nix**:
- Video players (VLC, MPV)
- Audio tools
- qBittorrent with theme configuration
- Image viewers (imv)

**graphics.nix**:
- Creative applications (GIMP, Inkscape, Blender)
- PDF viewers (okular, zathura)
- Graphics utilities

### 2.3 Program Module Conversion
**Replace manual configs with Home Manager modules**:
- kitty: Use `programs.kitty` instead of manual config
- Git: Move to `programs.git` (if not already in shared)
- Add `programs.fzf` configuration
- Add `programs.tmux` for session management

## **Phase 3: Optimize Server Configuration**

### 3.1 Import Shared Modules
Update `hosts/server/home.nix` to import:
- core-cli.nix
- development.nix  
- productivity.nix
- Enhanced zsh configuration

### 3.2 Server-Specific Enhancements
**Add systemd user services**:
- Business intelligence automation
- Context monitoring for ADHD tools
- Backup and sync services

**Environment variables**:
- Business API URLs
- Database connections
- Workspace organization

## **Phase 4: Implementation Protocol**

### 4.1 Safety Measures
1. **Create this documentation file FIRST**
2. **Use `grebuild "commit message"` for each change**
3. **Test each module independently**
4. **Verify both laptop and server build successfully**
5. **No functionality should be lost - only reorganized**

### 4.2 Implementation Order
1. ✅ Create this documentation file
2. Create shared/home-manager/core-cli.nix
3. Create shared/home-manager/development.nix  
4. Create shared/home-manager/productivity.nix
5. Update server/home.nix to use shared modules
6. Test server configuration with `grebuild`
7. Create laptop desktop modules
8. Update laptop/home.nix structure
9. Test laptop configuration with `grebuild`
10. Move packages from system config to home config
11. Final testing and optimization

### 4.3 Testing Checklist
**After each phase**:
- [ ] Server builds successfully: `sudo nixos-rebuild test --flake .#homeserver`
- [ ] Laptop builds successfully: `sudo nixos-rebuild test --flake .#heartwood-laptop`
- [ ] All applications launch correctly
- [ ] Shell environment works (aliases, functions)
- [ ] Shared configurations are consistent

## **Expected Benefits**

### Maintainability
- ✅ Clear separation between system and user packages
- ✅ Reusable modules shared between hosts
- ✅ Consistent configuration across environments

### Host Appropriateness  
- ✅ GUI applications only on laptop
- ✅ CLI focus on server with X11 forwarding capability
- ✅ Server-specific automation and business tools

### Developer Experience
- ✅ Easier to modify and update configurations
- ✅ Better organization and documentation
- ✅ Consistent theming and application behavior

## **Rollback Plan**
If issues arise:
1. Use git to revert to previous working commit
2. Individual modules can be disabled by commenting imports
3. System-level packages remain functional during transition
4. Each phase is committed separately for granular rollback

## **Future Claude Sessions**
**To continue this work**:
1. Read this file first to understand current progress
2. Check todo list status with TodoRead tool
3. Follow implementation order above
4. Always use `grebuild "message"` for testing and commits
5. Update this file with progress and any discovered issues

---
**Next Action**: Create shared/home-manager/core-cli.nix module