# hosts/laptop/modules/transcript-cli.nix
# YouTube Transcript CLI tool for laptop
{ config, lib, pkgs, ... }:

{
  # Install CLI tool and dependencies system-wide
  environment.systemPackages = with pkgs; [
    # CLI wrapper script with proper Python environment
    (pkgs.writeShellScriptBin "yt-transcript" ''
      export PYTHONPATH="/etc/nixos/scripts"
      # Use python3 (3.13) with the installed packages
      exec ${pkgs.python3.withPackages (ps: with ps; [ 
        pydantic httpx aiofiles python-slugify youtube-transcript-api yt-dlp
      ])}/bin/python /etc/nixos/scripts/yt-transcript.py "$@"
    '')
    
    # Desktop entry for GUI integration
    (pkgs.makeDesktopItem {
      name = "yt-transcript";
      desktopName = "YouTube Transcript";
      comment = "Extract transcripts from YouTube videos";
      exec = "${pkgs.kitty}/bin/kitty --title YouTube-Transcript -e yt-transcript";
      icon = "video-x-generic";
      categories = [ "AudioVideo" ];
    })
  ];

  # Create transcript directories in Obsidian vault (will sync via LiveSync)
  systemd.tmpfiles.rules = [
    "d /home/eric/01-documents/01-vaults/04-transcripts 0755 eric eric -"
    "d /home/eric/01-documents/01-vaults/04-transcripts/individual 0755 eric eric -"
    "d /home/eric/01-documents/01-vaults/04-transcripts/playlists 0755 eric eric -"
    "d /home/eric/01-documents/01-vaults/04-transcripts/api-requests 0755 eric eric -"
  ];

  # Set default environment for local usage
  environment.sessionVariables = {
    TRANSCRIPTS_ROOT = "/home/eric/01-documents/01-vaults/04-transcripts";
    LANGS = "en,en-US,en-GB";
    TZ = "America/Denver";
  };
}