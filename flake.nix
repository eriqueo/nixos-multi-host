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

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server/default.nix
          ./configuration.nix
          ./modules.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.eric = import ./hosts/server/home.nix;
          }
          {
            networking.hostName = "homeserver";
            media.server = true;
            media.client = true;
            surveillance.server = true;
            surveillance.client = true;
            business.server = true;
            business.client = true;
            ai.server = true;
            ai.client = true;
            desktop = false;
            laptop = false;
            server = true;
          }
        ];
      };

      "heartwood-laptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/laptop/default.nix
          ./configuration.nix
          ./modules.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.eric = import ./hosts/laptop/home.nix;
          }
          {
            networking.hostName = "heartwood-laptop";
            media.server = false;
            media.client = true;
            surveillance.server = false;
            surveillance.client = true;
            business.server = false;
            business.client = true;
            ai.server = false;
            ai.client = true;
            desktop = true;
            laptop = true;
            server = false;
          }
        ];
      };
    };
  };
}
