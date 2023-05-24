{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    firefox.url = "github:colemickens/flake-firefox-nightly";
  };

  outputs = inputs @ { nixpkgs, nixpkgs-stable, firefox, agenix, home-manager, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit inputs; 
        stable = inputs.nixpkgs-stable.legacyPackages."x86_64-linux";
      };
      modules = [
        ./system.nix
        ./hardware.nix
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default
        { 
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
#          home-manager.users.chebuya = import ./home.nix;        
        }
      ];
    };
  };
}
