# Heartwood Craft NixOS Configuration

Multi-host NixOS configuration for AI business intelligence platform.

## Hosts
- `homeserver` - Complete business server with media, surveillance, AI
- `laptop` - Client laptop with desktop environment

## Usage
# Server deployment
sudo nixos-rebuild switch --flake .#homeserver

## Laptop deployment  
sudo nixos-rebuild switch --flake .#laptop
## Architecture

4-file clean architecture
Conditional service modules
Shared configurations with host-specific flags
