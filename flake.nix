{
  description = "project pyria; highly paranoid nixos config";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
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

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, lanzaboote, impermanence, sops-nix, disko, niri-flake, noctalia, helium, claude-code, nixgl, ... }:
    let
      system = "x86_64-linux";
      output-systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs output-systems;
    in
    {
      niri-flake.cache.enable = true;
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          pyria = pkgs.callPackage ./nix/packages/pyria.nix { };
          pyria-sudo = pkgs.callPackage ./nix/packages/pyria-sudo.nix { };
          apparmor-d-nix-patch = pkgs.callPackage ./nix/packages/apparmor-d-nix-patch.nix { inherit inputs; };
        });

      overlays.default = final: prev: {
        pyria = final.callPackage ./nix/packages/pyria.nix { };
        pyria-sudo = final.callPackage ./nix/packages/pyria-sudo.nix { };
        apparmor-d-nix-patch = final.callPackage ./nix/packages/apparmor-d-nix-patch.nix { };
      };
      homeModules = {
        pyria-sudo = ./nix/home-modules/pyria-sudo.nix;
        default = self.homeModules.pyria-sudo;  # convenience
      };
      nixosConfigurations.deaddove = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit self niri-flake inputs; };
        modules = [
          {
            nixpkgs.overlays = [ 
              self.overlays.default
              helium.overlays.default 
              claude-code.overlays.default
              niri-flake.overlays.niri
            ];
          }
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
          {
            nixpkgs.overlays = [ 
              self.overlays.default
              helium.overlays.default 
              claude-code.overlays.default
              niri-flake.overlays.niri
            ];
          }
          
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          lanzaboote.nixosModules.lanzaboote
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
          {
            nixpkgs.overlays = [ 
              self.overlays.default
              helium.overlays.default 
              claude-code.overlays.default
              niri-flake.overlays.niri
            ];
          }
          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          ./hosts/kiri/default.nix
        ];
      };
      homeConfigurations.aenri = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit self inputs; };
        modules = [
          {
            nixpkgs.overlays = [ 
              helium.overlays.default 
              claude-code.overlays.default
              self.overlays.default
              niri-flake.overlays.niri
              nixgl.overlay
            ];
          }
          niri-flake.homeModules.config
          self.homeModules.pyria-sudo
          ./users/aenri/home.nix
        ];
      };
    };
}
