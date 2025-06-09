# flake.nix - Complete Heartwood Craft NixOS Configuration
{
  description = "Heartwood Craft NixOS - AI Business Intelligence Platform";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, ... }: {
    nixosConfigurations = {
      
      # 🖥️ SERVER - Complete AI Business Intelligence Platform
      homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.eric = import ./home.nix;
          }
          {
            # SERVER CONFIGURATION - Define all options here
            networking.hostName = "homeserver";
            
            # Service flags - What runs on server
            media.server = true;
            media.client = true;
            surveillance.server = true;
            surveillance.client = true;
            business.server = true;
            business.client = true;
            ai.server = true;
            ai.client = true;
            
            # Hardware flags
            desktop = false;
            laptop = false;
            server = true;
          }
        ];
      };

      # 💻 LAPTOP - Complete Client + Development Environment
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.eric = import ./home.nix;
          }
           ({ pkgs, ... }: {
            environment.systemPackages = with pkgs; [
              librewolf
              ungoogled-chromium
            ];
          })
          {
            # LAPTOP CONFIGURATION
            networking.hostName = "heartwood-laptop";
            
            # Service flags - Client access only
            media.server = false;
            media.client = true;
            surveillance.server = false;
            surveillance.client = true;
            business.server = false;
            business.client = true;
            ai.server = false;
            ai.client = true;
            
            # Hardware flags
            desktop = true;
            laptop = true;
            server = false;
          }
        ];
      };
    };
  };
}
