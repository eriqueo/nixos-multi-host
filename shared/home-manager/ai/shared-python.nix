{ config, lib, pkgs, ... }:

{
  # Shared Python environment for all AI tools
  # Includes packages for both transcript-formatter and transcript-cli
  home.packages = [
    (pkgs.python3.withPackages (ps: with ps; [
      # For transcript-formatter
      requests
      pyyaml
      
      # For transcript-cli  
      pydantic
      httpx
      aiofiles
      python-slugify
      youtube-transcript-api
      
      # General development tools
      pip
      virtualenv
    ]))
    
    # Also include yt-dlp as separate package (not Python package)
    pkgs.yt-dlp
  ];
}