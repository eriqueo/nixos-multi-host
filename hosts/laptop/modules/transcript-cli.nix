# hosts/laptop/modules/transcript-cli.nix
# YouTube Transcript CLI tool for laptop
{ config, lib, pkgs, ... }:

{
  # Install CLI tool and dependencies system-wide
  environment.systemPackages = with pkgs; [
    # Core Python dependencies for transcript extraction
    python311
    python311Packages.pydantic
    python311Packages.httpx
    python311Packages.aiofiles
    python311Packages.python-slugify
    yt-dlp
    python311Packages.youtube-transcript-api
    
    # CLI wrapper script
    (pkgs.writeShellScriptBin "yt-transcript" ''
      export PYTHONPATH="/etc/nixos/scripts:$PYTHONPATH"
      exec ${pkgs.python311}/bin/python3 /etc/nixos/scripts/yt-transcript.py "$@"
    '')
  ];

  # Create default transcript directories in user's home
  systemd.tmpfiles.rules = [
    "d /home/eric/Documents/transcripts 0755 eric eric -"
    "d /home/eric/Documents/transcripts/individual 0755 eric eric -"
    "d /home/eric/Documents/transcripts/playlists 0755 eric eric -"
  ];

  # Set default environment for local usage
  environment.sessionVariables = {
    TRANSCRIPTS_ROOT = "/home/eric/Documents/transcripts";
    LANGS = "en,en-US,en-GB";
    TZ = "America/Denver";
  };

  # Optional: Add desktop entry for GUI file manager integration
  environment.systemPackages = [
    (pkgs.makeDesktopItem {
      name = "yt-transcript";
      desktopName = "YouTube Transcript";
      comment = "Extract transcripts from YouTube videos";
      exec = "${pkgs.kitty}/bin/kitty --title 'YouTube Transcript' -e yt-transcript";
      icon = "video-x-generic";
      categories = [ "AudioVideo" "Utility" ];
    })
  ];
}