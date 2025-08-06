# NixOS System Aliases & Commands Reference

## System Aliases (from shared/zsh-config.nix)

### File Management
- `ls` = `eza --tree --level=1`  
- `ll` = `eza -l --git --icons`
- `la` = `eza -la --git --icons`
- `lt` = `eza --tree --level=2`
- `grep` = `rg` (ripgrep syntax required)

### Navigation
- `..` = `cd ..`
- `...` = `cd ../..` 
- `....` = `cd ../../..`

### Git Shortcuts
- `gs` = `git status -sb`
- `ga` = `git add .`
- `gc` = `git commit -m`
- `gp` = `git push`
- `gl` = `git log --oneline --graph --decorate --all`
- `gpl` = `git pull`
- `gresync` = `cd /etc/nixos && sudo git fetch origin && sudo git pull origin master`
- `gstatus` = `cd /etc/nixos && sudo git status`
- `glog` = `cd /etc/nixos && sudo git log --oneline -10`

### NixOS Management  
- `grebuild "message"` = Enhanced git + test + rebuild + AI docs workflow
- `gtest "message"` = Test-only version (no commit/switch)
- `nixcon` = `sudo micro /etc/nixos/configuration.nix`
- `nixflake` = `sudo micro /etc/nixos/flake.nix`
- `nixserverhome` = `sudo micro /etc/nixos/hosts/server/home.nix`
- `nixservercon` = `sudo micro /etc/nixos/hosts/server/config.nix`
- `nixcameras` = `sudo micro /etc/nixos/hosts/server/modules/surveillance.nix`

### System Utils
- `df` = `df -h`
- `du` = `du -h` 
- `free` = `free -h`
- `htop` = `btop --tree`
- `speedtest` = `speedtest-cli`
- `myip` = `curl -s ifconfig.me`

### Media Navigation
- `media` = `cd /mnt/media`
- `tv` = `cd /mnt/media/tv`
- `movies` = `cd /mnt/media/movies`

### AI & Business
- `ai-chat` = `ollama run llama3.2:3b`
- `cameras` = Shows Frigate URL
- `home-assistant` = Shows HA URL
- `frigate-logs` = `sudo podman logs -f frigate`

### Useful Functions
- `mkcd <dir>` = Create and enter directory
- `extract <file>` = Universal archive extractor
- `status` = Quick system overview
- `update-containers` = Force container image updates

## Important Notes
- Use `rg` syntax instead of `grep` (system alias)
- Always use `grebuild` for configuration changes (includes AI docs)
- Use `gtest` to test configs before committing
- GPU services: Frigate, Immich, Jellyfin have NVIDIA acceleration