{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs @ { nixpkgs, agenix, home-manager, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./system.nix
        ./hardware.nix
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default
        { 
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.chebuya = import ./home.nix;        
        }
      ];
    };
  };
}
