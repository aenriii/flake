{ config, pkgs, lib, niri-flake, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/hostprofile.nix
    ../../modules/boot/luks/normal.nix
    ../../modules/persistence/impermanence.nix
    ../../modules/network/firewall.nix
    ../../modules/network/dns.nix
    ../../modules/network/tailscale.nix
    ../../modules/security/sops.nix
    ../../modules/security/apparmor/hardened.nix
    ../../modules/security/hardened.nix
    ../../users/aenri/default.nix
  ];
  hostprofile = {
    boot = {
      luks = "basic";
    };
    kernel = {
      flavor = "hardened";
      config = "hardened";
    };
    desktops = [ "niri" ];
  };
  
  nixpkgs.overlays = [ niri-flake.overlays.niri ];
  nix.settings.allowed-users = [ "aenri" ];
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; };
  nix.optimise.automatic = true;

  # home-manager.sharedModules = [ niri-flake.homeModules.niri ];
  networking.hostName = "actyldia";
  time.timeZone = "America/Indiana/Indianapolis";
  system.stateVersion = "25.11";
  
  
  # no need for lanzaboote in a vm
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
