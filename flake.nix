{
  description = "paranoia nixos config";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, lanzaboote, impermanence, sops-nix, disko, niri-flake, ... }:
    let
      system = "x86_64-linux";
    in
    {
      
      nixosConfigurations.deaddove = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit self niri-flake; };
        modules = [
          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          niri-flake.nixosModules.niri
          ./hosts/deaddove/default.nix
        ];
      };
      nixosConfigurations.actyldia = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit self niri-flake; };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          niri-flake.nixosModules.niri
          ./hosts/actyldia/default.nix
        ];
      };
      nixosConfigurations.kiri = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit self; };
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          ./hosts/kiri/default.nix
        ];
      };
    };
}
