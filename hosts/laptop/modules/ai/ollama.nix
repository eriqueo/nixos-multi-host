{ config, pkgs, lib, ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";  # Use NVIDIA GPU acceleration
    host = "127.0.0.1";     # Local access only for laptop
    port = 11434;
  };
}
